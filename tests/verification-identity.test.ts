import { beforeAll, describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import sharp from "sharp";
import { PgIdentityRepository } from "../src/features/verification/infra/pg-identity-repository";
import { BASE_URL, auth, db, json, makeUser, type TestUser } from "./media-helpers";

// Level 2 against a running server (TEST_API_URL) and its database. The chip
// fixtures are fictitious (state "UTO"), so the PRODUCTION trust store must
// refuse them; the success path with real components is covered by
// tests/unit/verification-identity-e2e.test.ts.
const ADMIN_EMAIL = process.env.ADMIN_EMAIL ?? "admin@example.com";
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? "dev-admin-pass";
const CHIP = join(import.meta.dir, "fixtures", "chip", "rsa-pkcs1-face");
const FACES = join(import.meta.dir, "fixtures", "faces");
const chipFile = (name: string): Blob => new Blob([readFileSync(join(CHIP, name))]);
const face = (name: string): Uint8Array => new Uint8Array(readFileSync(join(FACES, name)));

async function liveFrames(challenges: string[]): Promise<Uint8Array[]> {
  const mirrored = new Uint8Array(await sharp(face("ride-profile-sts7-1983.jpg")).flop().jpeg().toBuffer());
  const sides = [face("ride-profile-sts7-1983.jpg"), mirrored];
  const out = [face("ride-flight-deck-1983.jpg")];
  for (const c of challenges.slice(1)) out.push(c === "front" ? face("ride-portrait-1984.jpg") : (sides.shift() as Uint8Array));
  return out;
}

async function identitySession(u: TestUser): Promise<{ session_id: string; challenges: string[] }> {
  const r = await fetch(`${BASE_URL}/api/verification/face/session`, {
    method: "POST",
    headers: json(u.token),
    body: JSON.stringify({ purpose: "identity" }),
  });
  expect(r.status).toBe(200);
  return (await r.json()) as { session_id: string; challenges: string[] };
}

function identityForm(sessionId: string, frames: Uint8Array[], chip: Partial<Record<"dg1" | "dg2" | "sod", Blob>>): FormData {
  const form = new FormData();
  form.set("session_id", sessionId);
  frames.forEach((f, i) => form.set(`frame_${i}`, new Blob([f], { type: "image/jpeg" }), `frame_${i}.jpg`));
  for (const [k, v] of Object.entries(chip)) form.set(k, v, `${k}.bin`);
  return form;
}

const postIdentity = (u: TestUser | null, body: FormData | string, headers: Record<string, string> = {}) =>
  fetch(`${BASE_URL}/api/verification/identity`, { method: "POST", headers: { ...(u ? auth(u.token) : {}), ...headers }, body });

describe("POST /api/verification/identity", () => {
  test("requires authentication", async () => {
    expect((await postIdentity(null, new FormData())).status).toBe(401);
  });

  test("requires a multipart body", async () => {
    const u = await makeUser("id-json");
    const r = await postIdentity(u, "{}", { "Content-Type": "application/json" });
    expect(r.status).toBe(400);
  });

  test("refuses a submission without chip files", async () => {
    const u = await makeUser("id-nochip");
    const s = await identitySession(u);
    const r = await postIdentity(u, identityForm(s.session_id, await liveFrames(s.challenges), {}));
    expect(r.status).toBe(400);
    expect(((await r.json()) as { error: string }).error).toBe("dg1 is required");
  });

  test("a genuine selfie with a chip signed by an unknown state is refused (csca_unknown)", async () => {
    const u = await makeUser("id-utopia");
    const s = await identitySession(u);
    const form = identityForm(s.session_id, await liveFrames(s.challenges), {
      dg1: chipFile("dg1.bin"),
      dg2: chipFile("dg2.bin"),
      sod: chipFile("sod.bin"),
    });
    const r = await postIdentity(u, form);
    expect(r.status).toBe(200);
    expect(await r.json()).toEqual({ success: true, verified: false, reason: "csca_unknown" });
  });
});

describe("identity storage", () => {
  const repo = new PgIdentityRepository(db);
  let adminToken = "";
  const fingerprint = (label: string): string => label.padEnd(64, "0").slice(0, 64);

  beforeAll(async () => {
    const r = await fetch(`${BASE_URL}/api/admin/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: ADMIN_EMAIL, password: ADMIN_PASSWORD }),
    });
    expect(r.status).toBe(200);
    adminToken = ((await r.json()) as { token: string }).token;
  });

  async function verifiedUser(label: string, fp: string): Promise<TestUser> {
    const u = await makeUser(label);
    await fetch(`${BASE_URL}/api/profile`, { method: "PUT", headers: json(u.token), body: JSON.stringify({ birthdate: "2000-01-01" }) });
    const saved = await repo.save({
      userId: u.id,
      method: "nfc_passive_auth",
      issuingState: "FRA",
      documentType: "P",
      fingerprint: fp,
      documentExpiry: "2031-01-01",
      birthDate: "1990-05-17",
    });
    expect(saved).toBe("saved");
    return u;
  }

  test("the document birth date replaces the profile's and is locked", async () => {
    const u = await verifiedUser("id-lock", fingerprint(`lock${Date.now()}`));
    await fetch(`${BASE_URL}/api/profile`, { method: "PUT", headers: json(u.token), body: JSON.stringify({ birthdate: "2004-03-03" }) });
    const [row] = await db<{ birthdate: string; birthdate_locked: boolean; identity_verified_at: Date | null }[]>`
      SELECT to_char(birthdate, 'YYYY-MM-DD') AS birthdate, birthdate_locked, identity_verified_at FROM profiles WHERE user_id = ${u.id}
    `;
    expect(row?.birthdate).toBe("1990-05-17");
    expect(row?.birthdate_locked).toBe(true);
    expect(row?.identity_verified_at).not.toBeNull();
  });

  test("one document opens one account", async () => {
    const fp = fingerprint(`dup${Date.now()}`);
    await verifiedUser("id-first", fp);
    const second = await makeUser("id-second");
    const result = await repo.save({
      userId: second.id,
      method: "nfc_passive_auth",
      issuingState: "FRA",
      documentType: "P",
      fingerprint: fp,
      documentExpiry: "2031-01-01",
      birthDate: "1990-05-17",
    });
    expect(result).toBe("fingerprint_taken");
  });

  test("a permanent ban bans the document, an unban releases it", async () => {
    const fp = fingerprint(`ban${Date.now()}`);
    const u = await verifiedUser("id-ban", fp);
    const headers = { Authorization: `Bearer ${adminToken}`, "Content-Type": "application/json" };
    const ban = await fetch(`${BASE_URL}/api/admin/users/${u.id}/ban`, {
      method: "POST",
      headers,
      body: JSON.stringify({ reason: "test", isPermanent: true }),
    });
    expect(ban.status).toBe(200);
    expect(await repo.isBanned(fp)).toBe(true);

    const unban = await fetch(`${BASE_URL}/api/admin/users/${u.id}/unban`, { method: "POST", headers, body: "{}" });
    expect(unban.status).toBe(200);
    expect(await repo.isBanned(fp)).toBe(false);
  });

  test("a temporary ban does not ban the document", async () => {
    const fp = fingerprint(`tmp${Date.now()}`);
    const u = await verifiedUser("id-tmpban", fp);
    const r = await fetch(`${BASE_URL}/api/admin/users/${u.id}/ban`, {
      method: "POST",
      headers: { Authorization: `Bearer ${adminToken}`, "Content-Type": "application/json" },
      body: JSON.stringify({ reason: "test", expiresAt: "2030-01-01T00:00:00Z" }),
    });
    expect(r.status).toBe(200);
    expect(await repo.isBanned(fp)).toBe(false);
  });
});
