import { describe, expect, test } from "bun:test";
import { BASE_URL, auth, db, makeMatch, onlyRow, send, uploadOk, type Pair } from "./chat-helpers";
import { jpegWithGps, uploadPhoto } from "./media-helpers";

// GDPR right to erasure, and an App Store requirement: a member deletes their
// own account from the app. The app has always called DELETE /api/users/me;
// the route did not exist (404), so nobody could delete their account.

const UPLOADS = process.env.UPLOADS_DIR ?? "uploads";
const onDisk = (key: string) => Bun.file(`${UPLOADS}/${key}`).exists();
const deleteMe = (token: string | null, body: unknown = { reason: "J'ai rencontré quelqu'un" }) =>
  fetch(`${BASE_URL}/api/users/me`, {
    method: "DELETE",
    headers: { "Content-Type": "application/json", ...(token ? auth(token) : {}) },
    body: JSON.stringify(body),
  });
const count = async (query: Promise<{ n: string }[]>) => Number(onlyRow(await query).n);

async function memberWithEverything(label: string): Promise<{ pair: Pair; photoKeys: string[]; chatKeys: string[] }> {
  const pair = await makeMatch(label);
  await uploadPhoto(pair.a.token, await jpegWithGps(80, 80, 1));
  const photoKeys = (await db<{ url: string }[]>`SELECT url FROM profile_photos WHERE user_id = ${pair.a.id}`).map((r) => r.url);
  const photo = await uploadOk(pair.a.token, pair.conversationId, { kind: "photo", file: await jpegWithGps(60, 60, 1) });
  await send(pair.a.token, pair.conversationId, { type: "photo", content: "", media_ids: [photo.id] });
  const chatKeys = (await db<{ storage_key: string }[]>`SELECT storage_key FROM message_media WHERE id = ${photo.id}`).map((r) => r.storage_key);
  // An event they organised and a couple memory they wrote: both referenced
  // users without ON DELETE, which used to make the deletion fail.
  await db`INSERT INTO events (title, date, organizer_id) VALUES ('Soirée test', CURRENT_DATE + 7, ${pair.a.id})`;
  const enabled = await fetch(`${BASE_URL}/api/dev/couple/enable`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ userId: pair.a.id, partnerId: pair.b.id }),
  });
  const couple = (await enabled.json()) as { coupleId: number };
  await db`INSERT INTO couple_memories (couple_id, type, title, created_by) VALUES (${couple.coupleId}, 'note', 'souvenir', ${pair.a.id})`;
  return { pair, photoKeys, chatKeys };
}

describe("DELETE /api/users/me", () => {
  test("requires authentication", async () => {
    expect((await deleteMe(null)).status).toBe(401);
  });

  test("erases the member: rows, profile photo files, chat files; the other member stays", async () => {
    const { pair, photoKeys, chatKeys } = await memberWithEverything("selfdel");
    expect(photoKeys.length).toBeGreaterThan(0);
    for (const key of [...photoKeys, ...chatKeys]) expect(await onDisk(key)).toBe(true);

    const res = await deleteMe(pair.a.token);
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ success: true });

    expect(await count(db`SELECT COUNT(*) AS n FROM users WHERE id = ${pair.a.id}`)).toBe(0);
    expect(await count(db`SELECT COUNT(*) AS n FROM profile_photos WHERE user_id = ${pair.a.id}`)).toBe(0);
    expect(await count(db`SELECT COUNT(*) AS n FROM conversations WHERE id = ${pair.conversationId}`)).toBe(0);
    for (const key of [...photoKeys, ...chatKeys]) expect([key, await onDisk(key)]).toEqual([key, false]);
    // The event stays (other people registered for it), without its organiser.
    expect(await count(db`SELECT COUNT(*) AS n FROM events WHERE title = 'Soirée test' AND organizer_id = ${pair.a.id}`)).toBe(0);
    expect(await count(db`SELECT COUNT(*) AS n FROM users WHERE id = ${pair.b.id}`)).toBe(1);
  });

  test("the reason is kept without anything that identifies the member", async () => {
    const pair = await makeMatch("selfdel-reason");
    const marker = `raison-${Date.now()}`;
    expect((await deleteMe(pair.a.token, { reason: marker })).status).toBe(200);
    const rows = await db<Record<string, unknown>[]>`SELECT * FROM account_deletion_feedback WHERE reason = ${marker}`;
    expect(rows).toHaveLength(1);
    expect(Object.keys(rows[0] ?? {}).sort()).toEqual(["created_at", "id", "reason"]);
  });

  test("a second call with the same token finds nothing to delete", async () => {
    const pair = await makeMatch("selfdel-twice");
    expect((await deleteMe(pair.a.token)).status).toBe(200);
    expect([401, 404]).toContain((await deleteMe(pair.a.token)).status);
  });
});
