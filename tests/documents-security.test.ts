import { describe, expect, test } from "bun:test";
import { upsertWaitlistAndGetVerification } from "../src/db";
import { BASE_URL, db } from "./media-helpers";

// Integration tests for the member verification flow (/verify) against the
// attacks of the security audit. Needs the running server (TEST_API_URL) and its
// database (TEST_DATABASE_URL), like documents-flow.test.ts.

interface Member {
  email: string;
  token: string;
  waitlistId: number;
}

async function makeMember(label: string): Promise<Member> {
  const email = `docsec-${label}-${Date.now()}-${Math.floor(performance.now())}@example.com`;
  const res = await fetch(`${BASE_URL}/api/dev/documents/verification-token`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email }),
  });
  const data = (await res.json()) as { token: string; waitlist_id: number };
  return { email, token: data.token, waitlistId: data.waitlist_id };
}

const jpeg = (): Uint8Array => new Uint8Array([0xff, 0xd8, 0xff, 0xe0, ...new TextEncoder().encode("SCAN-EXEMPLE"), 0xff, 0xd9]);

async function upload(token: string, type = "selfie_id", bytes: Uint8Array = jpeg()): Promise<{ status: number; body: { success: boolean; error?: string } }> {
  const form = new FormData();
  form.set("type", type);
  form.set("file", new Blob([bytes], { type: "image/jpeg" }), "scan-exemple.jpg");
  const res = await fetch(`${BASE_URL}/api/verify/upload?token=${encodeURIComponent(token)}`, { method: "POST", body: form });
  return { status: res.status, body: (await res.json()) as never };
}

async function uploadAllRequired(token: string): Promise<void> {
  for (const type of ["selfie_id", "id_card_front", "id_card_back"]) {
    expect((await upload(token, type)).status).toBe(200);
  }
}

const submit = (token: string): Promise<Response> =>
  fetch(`${BASE_URL}/api/verify/submit?token=${encodeURIComponent(token)}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: "{}",
  });

const status = async (token: string): Promise<Response> => fetch(`${BASE_URL}/api/verify?token=${encodeURIComponent(token)}`);

const subscribe = (email: string): Promise<Response> =>
  fetch(`${BASE_URL}/api/subscribe`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ email }) });

async function setStatus(waitlistId: number, verificationStatus: string): Promise<void> {
  await db`UPDATE waitlist SET verification_status = ${verificationStatus} WHERE id = ${waitlistId}`;
}

async function waitlistRow(waitlistId: number): Promise<{ verification_status: string; verification_token: string }> {
  const rows = await db<{ verification_status: string; verification_token: string }[]>`
    SELECT verification_status, verification_token FROM waitlist WHERE id = ${waitlistId}
  `;
  const row = rows[0];
  if (row === undefined) throw new Error("no waitlist row");
  return row;
}

async function ageToken(waitlistId: number, days: number): Promise<void> {
  await db`UPDATE waitlist SET verification_token_created_at = NOW() - make_interval(days => ${days}) WHERE id = ${waitlistId}`;
}

describe("POST /api/subscribe cannot demote a member who is already being handled", () => {
  for (const handled of ["verified", "verified_plus", "submitted"]) {
    test(`a ${handled} member keeps status and link when an anonymous caller subscribes with their email`, async () => {
      const member = await makeMember(`sub-${handled}`);
      await setStatus(member.waitlistId, handled);

      const res = await subscribe(member.email);
      expect(res.status).toBe(200);

      const row = await waitlistRow(member.waitlistId);
      expect(row.verification_status).toBe(handled);
      expect(row.verification_token).toBe(member.token);
      const link = await status(member.token);
      expect(link.status).toBe(200);
      expect(((await link.json()) as { verificationStatus: string }).verificationStatus).toBe(handled);
    });

    test(`upsertWaitlistAndGetVerification flags a ${handled} member as already handled and hands out no token`, async () => {
      const member = await makeMember(`flag-${handled}`);
      await setStatus(member.waitlistId, handled);
      const entry = await upsertWaitlistAndGetVerification(member.email);
      expect(entry).toEqual({ id: member.waitlistId, email: member.email, verificationToken: "", alreadyHandled: true });
    });
  }

  test("a pending member still gets a fresh link (resending the email keeps working)", async () => {
    const member = await makeMember("sub-pending");
    const entry = await upsertWaitlistAndGetVerification(member.email);
    expect(entry.alreadyHandled).toBe(false);
    expect(entry.verificationToken).not.toBe("");
    expect(entry.verificationToken).not.toBe(member.token);
    expect((await status(member.token)).status).toBe(404);
    expect((await status(entry.verificationToken)).status).toBe(200);
  });

  test("a new email is registered as pending", async () => {
    const email = `docsec-new-${Date.now()}@example.com`;
    const entry = await upsertWaitlistAndGetVerification(email);
    expect(entry.alreadyHandled).toBe(false);
    expect((await waitlistRow(entry.id)).verification_status).toBe("pending");
  });
});

describe("the link of a member who is already verified is no longer a way to change anything", () => {
  for (const verified of ["verified", "verified_plus"]) {
    test(`upload and submit are refused with 409 once ${verified}`, async () => {
      const member = await makeMember(`done-${verified}`);
      await uploadAllRequired(member.token);
      await setStatus(member.waitlistId, verified);

      const late = await upload(member.token, "selfie_id");
      expect(late.status).toBe(409);
      expect(late.body.success).toBe(false);
      expect((await submit(member.token)).status).toBe(409);
      expect((await waitlistRow(member.waitlistId)).verification_status).toBe(verified);
    });
  }

  test("a verified member can still read their status with the link", async () => {
    const member = await makeMember("done-status");
    await setStatus(member.waitlistId, "verified");
    expect((await status(member.token)).status).toBe(200);
  });

  test("a member who is only submitted can still add a document before the review", async () => {
    const member = await makeMember("submitted-add");
    await uploadAllRequired(member.token);
    expect((await submit(member.token)).status).toBe(200);
    expect((await upload(member.token, "community_doc")).status).toBe(200);
  });
});

describe("the link expires 30 days after it was created", () => {
  test("at 31 days every route answers 404 invalid token", async () => {
    const member = await makeMember("expired");
    await uploadAllRequired(member.token);
    await ageToken(member.waitlistId, 31);
    expect((await status(member.token)).status).toBe(404);
    expect((await upload(member.token)).status).toBe(404);
    expect((await submit(member.token)).status).toBe(404);
  });

  test("at 29 days the link still works", async () => {
    const member = await makeMember("not-yet");
    await ageToken(member.waitlistId, 29);
    expect((await status(member.token)).status).toBe(200);
    expect((await upload(member.token)).status).toBe(200);
  });

  test("a new link, sent by subscribing again, starts a new period", async () => {
    const member = await makeMember("renewed");
    await ageToken(member.waitlistId, 40);
    const entry = await upsertWaitlistAndGetVerification(member.email);
    expect((await status(entry.verificationToken)).status).toBe(200);
  });

  test("the column exists with a default, so rows that predate it start their 30 days at the migration", async () => {
    const rows = await db<{ column_default: string | null; is_nullable: string }[]>`
      SELECT column_default, is_nullable FROM information_schema.columns
      WHERE table_name = 'waitlist' AND column_name = 'verification_token_created_at'
    `;
    expect(rows[0]?.column_default).toContain("now()");
    expect(rows[0]?.is_nullable).toBe("NO");
  });
});

describe("limits on what a link can upload", () => {
  test("a body over 15 MB is refused with 413 before it is read", async () => {
    const member = await makeMember("huge");
    const huge = new Uint8Array(16 * 1024 * 1024);
    huge.set([0xff, 0xd8, 0xff]);
    const res = await upload(member.token, "selfie_id", huge);
    expect(res.status).toBe(413);
    expect(res.body.success).toBe(false);
  });

  test("a file between 10 and 15 MB still gets the existing 'too large' answer", async () => {
    const member = await makeMember("big");
    const big = new Uint8Array(11 * 1024 * 1024);
    big.set([0xff, 0xd8, 0xff]);
    const res = await upload(member.token, "selfie_id", big);
    expect(res.status).toBe(400);
    expect(res.body.error).toBe("Fichier trop gros (max 10MB)");
  });

  test("at most 10 files per waitlist entry", async () => {
    const member = await makeMember("many");
    for (let i = 0; i < 10; i += 1) expect((await upload(member.token, "selfie_id")).status).toBe(200);
    const eleventh = await upload(member.token, "selfie_id");
    expect(eleventh.status).toBe(409);
    expect(eleventh.body.success).toBe(false);
    const stored = await db`SELECT 1 FROM documents WHERE waitlist_id = ${member.waitlistId}`;
    expect(stored).toHaveLength(10);
  });
});
