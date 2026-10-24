import { describe, expect, test } from "bun:test";
import { sessionReducer, type SessionState } from "../../console/src/auth/session-state";
import { digitsOnly, isCompleteCode, validateCredentials } from "../../console/src/auth/validation";
import type { MeDto } from "../../console/src/shared/api/contracts";

const me = (overrides: Partial<MeDto> = {}): MeDto => ({
  email: "moderation@example.com",
  role: "moderator",
  roleLabel: "Modérateur",
  permissions: ["dashboard.read"],
  mfa: true,
  mfaEnrolled: true,
  mfaRequired: true,
  ...overrides,
});
const start: SessionState = { phase: "loading" };

describe("session", () => {
  test("mot de passe valide avec second facteur : étape du code", () => {
    expect(sessionReducer(start, { type: "login", result: { kind: "mfa_challenge", challenge: "c1" } })).toEqual({ phase: "challenge", challenge: "c1" });
  });
  test("session ouverte avec second facteur : prêt", () => {
    expect(sessionReducer(start, { type: "login", result: { kind: "session", token: "t", me: me() } }).phase).toBe("ready");
  });
  test("second facteur exigé mais absent : enrôlement", () => {
    const state = sessionReducer(start, { type: "me", me: me({ mfa: false, mfaEnrolled: false }) });
    expect(state.phase).toBe("enrolling");
  });
  test("second facteur non exigé (développement) : prêt sans enrôlement", () => {
    expect(sessionReducer(start, { type: "me", me: me({ mfa: false, mfaRequired: false }) }).phase).toBe("ready");
  });
  test("403 mfa_required en cours de route : enrôlement", () => {
    const ready = sessionReducer(start, { type: "me", me: me() });
    expect(sessionReducer(ready, { type: "mfa_required" }).phase).toBe("enrolling");
  });
  test("401 : retour à la connexion avec un avis ; déconnexion : sans avis", () => {
    const ready = sessionReducer(start, { type: "me", me: me() });
    expect(sessionReducer(ready, { type: "expired" })).toEqual({ phase: "anonymous", notice: "Votre session a expiré. Reconnectez-vous." });
    expect(sessionReducer(ready, { type: "logout" })).toEqual({ phase: "anonymous", notice: null });
  });
});

describe("saisie de connexion", () => {
  test("collage d'un code : espaces et tirets retirés, 6 chiffres au plus", () => {
    expect(digitsOnly("123 456")).toBe("123456");
    expect(digitsOnly("12-34-56-78")).toBe("123456");
    expect(isCompleteCode("12345")).toBe(false);
    expect(isCompleteCode("123456")).toBe(true);
  });
  test("identifiants invalides signalés champ par champ", () => {
    expect(validateCredentials("pas-un-mail", "")).toEqual({ email: "Saisissez une adresse e-mail valide.", password: "Saisissez votre mot de passe." });
    expect(validateCredentials("a@example.com", "x")).toEqual({});
  });
});
