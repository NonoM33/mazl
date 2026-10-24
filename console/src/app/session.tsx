import { createContext, useCallback, useContext, useEffect, useMemo, useReducer, useRef, type ReactElement, type ReactNode } from "react";
import { sessionReducer, type SessionState } from "../auth/session-state";
import { createApiClient, createTokenStore, type ApiClient, type ApiResult } from "../shared/api/client";
import type { LoginResultDto, MeDto, MfaConfirmedDto, MfaEnrollmentDto } from "../shared/api/contracts";

interface SessionApi {
  readonly state: SessionState;
  readonly api: ApiClient;
  readonly loginPassword: (email: string, password: string) => Promise<ApiResult<LoginResultDto>>;
  readonly loginGoogle: (credential: string) => Promise<ApiResult<LoginResultDto>>;
  readonly submitCode: (challenge: string, code: string) => Promise<ApiResult<LoginResultDto>>;
  readonly startEnrollment: () => Promise<ApiResult<MfaEnrollmentDto>>;
  readonly confirmEnrollment: (code: string) => Promise<ApiResult<MfaConfirmedDto>>;
  readonly logout: () => void;
}

const SessionContext = createContext<SessionApi | null>(null);

export function useSession(): SessionApi {
  const value = useContext(SessionContext);
  if (value === null) throw new Error("useSession doit être utilisé sous <SessionProvider>.");
  return value;
}

/** L'utilisateur connecté ; n'existe que sous l'écran principal. */
export function useMe(): MeDto {
  const { state } = useSession();
  if (state.phase !== "ready") throw new Error("useMe : la session n'est pas prête.");
  return state.me;
}

const tokenStore = createTokenStore(window.sessionStorage);

export function SessionProvider({ children }: { readonly children: ReactNode }): ReactElement {
  const [state, dispatch] = useReducer(sessionReducer, { phase: "loading" } as SessionState);
  const dispatchRef = useRef(dispatch);
  dispatchRef.current = dispatch;

  const api = useMemo(
    () =>
      createApiClient({
        fetch: (input, init) => window.fetch(input, init),
        getToken: () => tokenStore.read(),
        onUnauthorized: () => {
          tokenStore.clear();
          dispatchRef.current({ type: "expired" });
        },
        onMfaRequired: () => dispatchRef.current({ type: "mfa_required" }),
      }),
    [],
  );

  useEffect(() => {
    if (tokenStore.read() === null) {
      dispatch({ type: "no_token" });
      return;
    }
    void api.get<MeDto>("/me").then((result) => {
      if (result.ok) dispatch({ type: "me", me: result.data });
      else dispatch({ type: "no_token" });
    });
  }, [api]);

  const acceptLogin = useCallback((result: ApiResult<LoginResultDto>): ApiResult<LoginResultDto> => {
    if (result.ok) {
      if (result.data.kind === "session") tokenStore.write(result.data.token);
      dispatch({ type: "login", result: result.data });
    }
    return result;
  }, []);

  const value = useMemo<SessionApi>(
    () => ({
      state,
      api,
      loginPassword: async (email, password) => acceptLogin(await api.post<LoginResultDto>("/auth/password", { email: email.trim(), password })),
      loginGoogle: async (credential) => acceptLogin(await api.post<LoginResultDto>("/auth/google", { credential: credential.trim() })),
      submitCode: async (challenge, code) => acceptLogin(await api.post<LoginResultDto>("/auth/mfa", { challenge, code })),
      startEnrollment: () => api.post<MfaEnrollmentDto>("/mfa/enroll"),
      confirmEnrollment: async (code) => {
        const result = await api.post<MfaConfirmedDto>("/mfa/confirm", { code });
        if (result.ok) {
          tokenStore.write(result.data.token);
          dispatch({ type: "me", me: result.data.me });
        }
        return result;
      },
      logout: () => {
        tokenStore.clear();
        dispatch({ type: "logout" });
      },
    }),
    [state, api, acceptLogin],
  );

  return <SessionContext.Provider value={value}>{children}</SessionContext.Provider>;
}
