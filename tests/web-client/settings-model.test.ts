import { describe, expect, test } from "bun:test";
import type { WebSessionInfo } from "../../web/src/shared/api/types";
import { PARIS } from "../../web/src/features/shabbat/rest-windows";
import { others, sessionDetail, sessionTitle, windowLabel } from "../../web/src/features/settings/settings-model";

const session = (patch: Partial<WebSessionInfo>): WebSessionInfo => ({ id: "a", browser: "Chrome sur macOS", method: "qr", created_at: "2026-10-20T08:00:00Z", last_seen_at: "2026-10-24T09:05:00Z", expires_at: "2026-10-27T08:00:00Z", ...patch });

describe("session labels", () => {
  test("the current computer is named as such", () => {
    expect(sessionTitle(session({ current: true }))).toBe("Chrome sur macOS · Cet ordinateur");
    expect(sessionTitle(session({}))).toBe("Chrome sur macOS");
  });
  test("the detail names the sign-in method", () => {
    expect(sessionDetail(session({ method: "google" }))).toContain("Connecté par Google");
    expect(sessionDetail(session({ method: "qr" }))).toContain("QR code");
  });
  test("others excludes the current session", () => {
    expect(others([session({ id: "a", current: true }), session({ id: "b" })]).map((item) => item.id)).toEqual(["b"]);
  });
});

describe("next rest window", () => {
  test("reads like « Shabbat : vendredi 17:02 → samedi 18:10, Paris »", () => {
    const label = windowLabel({ start: new Date(2026, 9, 23, 17, 2), end: new Date(2026, 9, 24, 18, 10), holiday: false }, PARIS);
    expect(label).toBe("Shabbat : vendredi 17:02 → samedi 18:10, Paris");
  });
  test("a holiday is called Yom Tov, no window says so", () => {
    expect(windowLabel({ start: new Date(2026, 9, 3, 17, 0), end: new Date(2026, 9, 4, 18, 0), holiday: true }, PARIS)).toStartWith("Yom Tov : ");
    expect(windowLabel(null, PARIS)).toBe("Aucune fenêtre à venir.");
  });
});
