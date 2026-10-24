import { beforeAll, describe, expect, test } from "bun:test";
import { existsSync } from "node:fs";
import { readdir, readFile } from "node:fs/promises";
import { join, resolve } from "node:path";

// Integration test for the encrypted + purged identity-document flow.
// Needs a running server (TEST_API_URL) whose UPLOADS_DIR is the one this
// process reads (UPLOADS_DIR, default ./.uploads-test), a reachable Postgres,
// and the non-production dev endpoints. ADMIN_EMAIL / ADMIN_PASSWORD must be
// the ones the server was started with.
const BASE_URL = process.env.TEST_API_URL || "http://localhost:3000";
const UPLOADS_ROOT = resolve(process.env.UPLOADS_DIR || ".uploads-test");
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || "admin@example.com";
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || "dev-admin-pass";

interface Member {
  email: string;
  token: string;
  waitlistId: number;
}

let adminToken = "";

const adminHeaders = (): Record<string, string> => ({
  Authorization: `Bearer ${adminToken}`,
  "Content-Type": "application/json",
});

function jpegWith(marker: string): Uint8Array {
  return new Uint8Array([0xff, 0xd8, 0xff, 0xe0, ...new TextEncoder().encode(marker), 0xff, 0xd9]);
}

function newMarker(): string {
  return `SCAN-IDENTITE-${crypto.randomUUID()}`;
}

async function makeMember(label: string): Promise<Member> {
  const email = `docs-${label}-${Date.now()}-${Math.floor(performance.now())}@example.com`;
  const res = await fetch(`${BASE_URL}/api/dev/documents/verification-token`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email }),
  });
  const data = (await res.json()) as { token: string; waitlist_id: number };
  return { email, token: data.token, waitlistId: data.waitlist_id };
}

async function upload(
  member: Member,
  type: string,
  bytes: Uint8Array,
  mime = "image/jpeg",
  tokenOverride?: string,
): Promise<{ status: number; body: { success: boolean; documentId?: number; filename?: string; error?: string } }> {
  const form = new FormData();
  form.set("type", type);
  form.set("file", new Blob([bytes], { type: mime }), "passeport-jeanne-exemple.jpg");
  const res = await fetch(`${BASE_URL}/api/verify/upload?token=${encodeURIComponent(tokenOverride ?? member.token)}`, {
    method: "POST",
    body: form,
  });
  return { status: res.status, body: (await res.json()) as never };
}

async function uploadAll(member: Member): Promise<Record<string, { id: number; filename: string; marker: string }>> {
  const out: Record<string, { id: number; filename: string; marker: string }> = {};
  for (const type of ["selfie_id", "id_card_front", "id_card_back"]) {
    const marker = newMarker();
    const { body } = await upload(member, type, jpegWith(marker));
    out[type] = { id: body.documentId!, filename: body.filename!, marker };
  }
  return out;
}

async function filesUnderRoot(dir = UPLOADS_ROOT): Promise<string[]> {
  if (!existsSync(dir)) return [];
  const out: string[] = [];
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) out.push(...(await filesUnderRoot(full)));
    else out.push(full);
  }
  return out;
}

async function anyFileContains(marker: string): Promise<boolean> {
  for (const file of await filesUnderRoot()) {
    if (Buffer.from(await readFile(file)).includes(Buffer.from(marker))) return true;
  }
  return false;
}

async function adminItem(email: string): Promise<{ documents: Array<{ id: number; purged: boolean; status: string }> }> {
  const res = await fetch(`${BASE_URL}/api/admin/pending`, { headers: adminHeaders() });
  const data = (await res.json()) as { items: Array<{ email: string; documents: never[] }> };
  const item = data.items.find((i) => i.email === email);
  if (!item) throw new Error("member not in the pending list");
  return item as never;
}

const adminPost = (path: string, body: unknown = {}) =>
  fetch(`${BASE_URL}${path}`, { method: "POST", headers: adminHeaders(), body: JSON.stringify(body) });

beforeAll(async () => {
  const res = await fetch(`${BASE_URL}/api/admin/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: ADMIN_EMAIL, password: ADMIN_PASSWORD }),
  });
  adminToken = ((await res.json()) as { token: string }).token;
  if (!adminToken) throw new Error("admin login failed: check ADMIN_EMAIL / ADMIN_PASSWORD");
});

describe("upload", () => {
  test("the bytes on disk never contain the uploaded plaintext", async () => {
    const member = await makeMember("clear");
    const marker = newMarker();
    const { status, body } = await upload(member, "selfie_id", jpegWith(marker));

    expect(status).toBe(200);
    expect(body.success).toBe(true);
    expect(body.filename).toMatch(/^documents\/[0-9a-f-]{36}\.enc$/);
    const onDisk = await readFile(join(UPLOADS_ROOT, body.filename!));
    expect(onDisk.includes(Buffer.from(marker))).toBe(false);
    expect(await anyFileContains(marker)).toBe(false);
  });

  test("the admin sees the original bytes, with no-store caching", async () => {
    const member = await makeMember("view");
    const marker = newMarker();
    const { body } = await upload(member, "id_card_front", jpegWith(marker));

    const res = await fetch(`${BASE_URL}/api/admin/documents/${body.documentId}/file`, { headers: adminHeaders() });
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toBe("image/jpeg");
    expect(res.headers.get("cache-control")).toBe("no-store");
    expect(Buffer.from(await res.arrayBuffer()).equals(Buffer.from(jpegWith(marker)))).toBe(true);
  });

  test("the document file endpoint refuses unauthenticated callers", async () => {
    const member = await makeMember("anon");
    const { body } = await upload(member, "selfie_id", jpegWith(newMarker()));
    const res = await fetch(`${BASE_URL}/api/admin/documents/${body.documentId}/file`);
    expect(res.status).toBe(401);
  });

  test("the format is decided by the bytes, not by the declared MIME type", async () => {
    const member = await makeMember("magic");
    const html = new TextEncoder().encode("<html><script>alert(1)</script></html>");
    const fake = await upload(member, "selfie_id", html, "image/jpeg");
    expect(fake.status).toBe(400);
    expect(fake.body.error).toBe("Format non supporté (JPG/PNG/PDF)");

    const gif = await upload(member, "selfie_id", new TextEncoder().encode("GIF89a......"), "image/png");
    expect(gif.status).toBe(400);
  });

  test("accepts PNG and PDF by their signatures", async () => {
    const member = await makeMember("kinds");
    const png = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1, 2, 3]);
    const pdf = new TextEncoder().encode("%PDF-1.7\n%%EOF");
    expect((await upload(member, "id_card_front", png, "application/octet-stream")).status).toBe(200);
    expect((await upload(member, "id_card_back", pdf, "text/plain")).status).toBe(200);
  });

  test("refuses files over 10 MB, unknown types and bad tokens", async () => {
    const member = await makeMember("limits");
    const big = new Uint8Array(10 * 1024 * 1024 + 1);
    big.set([0xff, 0xd8, 0xff]);
    const tooBig = await upload(member, "selfie_id", big);
    expect(tooBig.status).toBe(400);
    expect(tooBig.body.error).toBe("Fichier trop gros (max 10MB)");

    expect((await upload(member, "passport_scan", jpegWith("x"))).status).toBe(400);
    expect((await upload(member, "selfie_id", jpegWith("x"), "image/jpeg", "not-a-token")).status).toBe(404);

    const noToken = await fetch(`${BASE_URL}/api/verify/upload`, { method: "POST", body: new FormData() });
    expect(noToken.status).toBe(400);
  });
});

describe("member status and submission (shapes unchanged)", () => {
  test("GET /api/verify lists what is missing, then submit succeeds", async () => {
    const member = await makeMember("status");
    const before = (await (await fetch(`${BASE_URL}/api/verify?token=${member.token}`)).json()) as {
      success: boolean; email: string; requiredReady: boolean; missing: string[]; verificationStatus: string;
    };
    expect(before).toMatchObject({ success: true, email: member.email, requiredReady: false });
    expect(before.missing).toEqual(["selfie_id", "id_card_front", "id_card_back"]);

    const early = await fetch(`${BASE_URL}/api/verify/submit?token=${member.token}`, {
      method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ os: "ios" }),
    });
    expect(early.status).toBe(400);
    expect(((await early.json()) as { missing: string[] }).missing.length).toBe(3);

    await uploadAll(member);
    const after = (await (await fetch(`${BASE_URL}/api/verify?token=${member.token}`)).json()) as { requiredReady: boolean; missing: string[] };
    expect(after).toMatchObject({ requiredReady: true, missing: [] });

    const submit = await fetch(`${BASE_URL}/api/verify/submit?token=${member.token}`, {
      method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ os: "android" }),
    });
    expect(await submit.json()).toEqual({ success: true });
  });

  test("an unknown or missing token is refused", async () => {
    expect((await fetch(`${BASE_URL}/api/verify`)).status).toBe(400);
    expect((await fetch(`${BASE_URL}/api/verify?token=nope`)).status).toBe(404);
  });
});

describe("purge after the admin decision", () => {
  test("approving a document deletes its file; the admin list shows it purged", async () => {
    const member = await makeMember("approve-one");
    const docs = await uploadAll(member);
    const target = docs.selfie_id!;
    expect(existsSync(join(UPLOADS_ROOT, target.filename))).toBe(true);

    expect((await adminPost(`/api/admin/documents/${target.id}/approve`)).status).toBe(200);

    expect(existsSync(join(UPLOADS_ROOT, target.filename))).toBe(false);
    expect(await anyFileContains(target.marker)).toBe(false);
    const gone = await fetch(`${BASE_URL}/api/admin/documents/${target.id}/file`, { headers: adminHeaders() });
    expect(gone.status).toBe(410);

    const item = await adminItem(member.email);
    expect(item.documents.find((d) => d.id === target.id)).toMatchObject({ purged: true, status: "approved" });
    // the other documents were not decided: still on disk
    expect(existsSync(join(UPLOADS_ROOT, docs.id_card_front!.filename))).toBe(true);
  });

  test("rejecting a document deletes its file", async () => {
    const member = await makeMember("reject-one");
    const docs = await uploadAll(member);
    const target = docs.id_card_back!;

    const res = await adminPost(`/api/admin/documents/${target.id}/reject`, { notes: "illisible" });
    expect(res.status).toBe(200);
    expect(existsSync(join(UPLOADS_ROOT, target.filename))).toBe(false);
    expect(await anyFileContains(target.marker)).toBe(false);
  });

  test("approving the profile deletes every file of that member", async () => {
    const member = await makeMember("approve-profile");
    const docs = await uploadAll(member);
    const other = await makeMember("bystander");
    const bystander = await uploadAll(other);

    const res = await adminPost(`/api/admin/profiles/${member.waitlistId}/approve`);
    expect(res.status).toBe(200);

    for (const doc of Object.values(docs)) {
      expect(existsSync(join(UPLOADS_ROOT, doc.filename))).toBe(false);
      expect(await anyFileContains(doc.marker)).toBe(false);
    }
    for (const doc of Object.values(bystander)) expect(existsSync(join(UPLOADS_ROOT, doc.filename))).toBe(true);
  });

  test("a reupload request deletes every file and invalidates the old link", async () => {
    const member = await makeMember("reupload");
    const docs = await uploadAll(member);

    const res = await adminPost(`/api/admin/profiles/${member.waitlistId}/request-reupload`, { notes: "photo floue" });
    expect(res.status).toBe(200);

    for (const doc of Object.values(docs)) expect(existsSync(join(UPLOADS_ROOT, doc.filename))).toBe(false);
    expect((await fetch(`${BASE_URL}/api/verify?token=${member.token}`)).status).toBe(404);
  });

  test("the review endpoint purges approved and rejected documents, keeps the rest", async () => {
    const member = await makeMember("review");
    const docs = await uploadAll(member);

    const res = await adminPost(`/api/admin/profiles/${member.waitlistId}/review`, {
      approveDocumentIds: [docs.selfie_id!.id],
      rejectDocumentIds: [docs.id_card_front!.id],
      reason: "recto flou",
    });
    expect(res.status).toBe(200);

    expect(existsSync(join(UPLOADS_ROOT, docs.selfie_id!.filename))).toBe(false);
    expect(existsSync(join(UPLOADS_ROOT, docs.id_card_front!.filename))).toBe(false);
    expect(existsSync(join(UPLOADS_ROOT, docs.id_card_back!.filename))).toBe(true);
  });
});

describe("background purge of undecided documents", () => {
  test("a document older than 30 days is purged, a recent one is not", async () => {
    const member = await makeMember("stale");
    const docs = await uploadAll(member);
    const old = docs.selfie_id!;

    const backdate = await fetch(`${BASE_URL}/api/dev/documents/${old.id}/backdate`, {
      method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ days: 31 }),
    });
    expect(backdate.status).toBe(200);

    const sweep = await fetch(`${BASE_URL}/api/dev/documents/purge-sweep`, { method: "POST" });
    expect(sweep.status).toBe(200);

    expect(existsSync(join(UPLOADS_ROOT, old.filename))).toBe(false);
    expect(await anyFileContains(old.marker)).toBe(false);
    expect(existsSync(join(UPLOADS_ROOT, docs.id_card_front!.filename))).toBe(true);

    // a purged, never-reviewed document has to be sent again
    const status = (await (await fetch(`${BASE_URL}/api/verify?token=${member.token}`)).json()) as { missing: string[] };
    expect(status.missing).toEqual(["selfie_id"]);
    const item = await adminItem(member.email);
    expect(item.documents.find((d) => d.id === old.id)).toMatchObject({ purged: true, status: "pending" });
  });
});
