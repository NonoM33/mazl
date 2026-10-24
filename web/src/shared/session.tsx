import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import { api, onUnauthorized } from "./api/client";
import { ApiError } from "./api/errors";
import type { MeResponse, WebSessionResponse } from "./api/types";

// The signed-in member, read from the web session (cookie) and /api/auth/me.

export type SessionState =
  | { readonly status: "loading" }
  | { readonly status: "signed-out" }
  | { readonly status: "signed-in"; readonly me: MeResponse; readonly session: WebSessionResponse["session"] };

interface SessionApi {
  readonly state: SessionState;
  readonly refresh: () => Promise<void>;
  readonly signOut: () => Promise<void>;
}

const SessionContext = createContext<SessionApi | null>(null);

async function loadSession(): Promise<SessionState> {
  try {
    const [web, me] = await Promise.all([api.get<WebSessionResponse>("/api/web/session"), api.get<MeResponse>("/api/auth/me")]);
    return { status: "signed-in", me, session: web.session };
  } catch (error) {
    if (error instanceof ApiError && error.isUnauthorized) return { status: "signed-out" };
    throw error;
  }
}

export function SessionProvider({ children }: { readonly children: ReactNode }) {
  const [state, setState] = useState<SessionState>({ status: "loading" });

  const refresh = useCallback(async () => {
    try {
      setState(await loadSession());
    } catch {
      // Network or server trouble: keep what we had, the next call retries.
      setState((current) => (current.status === "loading" ? { status: "signed-out" } : current));
    }
  }, []);

  const signOut = useCallback(async () => {
    try {
      await api.post("/api/web/auth/logout");
    } finally {
      setState({ status: "signed-out" });
    }
  }, []);

  useEffect(() => {
    let cancelled = false;
    loadSession().then(
      (loaded) => { if (!cancelled) setState(loaded); },
      () => { if (!cancelled) setState({ status: "signed-out" }); },
    );
    const off = onUnauthorized(() => setState({ status: "signed-out" }));
    return () => { cancelled = true; off(); };
  }, []);

  const value = useMemo(() => ({ state, refresh, signOut }), [state, refresh, signOut]);
  return <SessionContext value={value}>{children}</SessionContext>;
}

export function useSession(): SessionApi {
  const value = useContext(SessionContext);
  if (!value) throw new Error("useSession outside SessionProvider");
  return value;
}

// The member, for screens rendered behind the sign-in gate.
export function useMe(): MeResponse {
  const { state } = useSession();
  if (state.status !== "signed-in") throw new Error("useMe while signed out");
  return state.me;
}
