// Machine d'état de la session : fonctions pures, testées sans DOM.
import type { LoginResultDto, MeDto } from "../shared/api/contracts";

export type SessionState =
  | { readonly phase: "loading" }
  | { readonly phase: "anonymous"; readonly notice: string | null }
  | { readonly phase: "challenge"; readonly challenge: string }
  | { readonly phase: "enrolling"; readonly me: MeDto }
  | { readonly phase: "ready"; readonly me: MeDto };

export type SessionAction =
  | { readonly type: "login"; readonly result: LoginResultDto }
  | { readonly type: "me"; readonly me: MeDto }
  | { readonly type: "expired" }
  | { readonly type: "mfa_required" }
  | { readonly type: "logout" }
  | { readonly type: "no_token" };

export function needsEnrollment(me: MeDto): boolean {
  return me.mfaRequired && !me.mfa;
}

function fromMe(me: MeDto): SessionState {
  return needsEnrollment(me) ? { phase: "enrolling", me } : { phase: "ready", me };
}

export function sessionReducer(state: SessionState, action: SessionAction): SessionState {
  switch (action.type) {
    case "login":
      return action.result.kind === "mfa_challenge" ? { phase: "challenge", challenge: action.result.challenge } : fromMe(action.result.me);
    case "me":
      return fromMe(action.me);
    case "expired":
      return { phase: "anonymous", notice: "Votre session a expiré. Reconnectez-vous." };
    case "mfa_required":
      return state.phase === "ready" ? { phase: "enrolling", me: state.me } : state;
    case "logout":
      return { phase: "anonymous", notice: null };
    case "no_token":
      return { phase: "anonymous", notice: null };
  }
}
