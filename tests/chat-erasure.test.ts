import { mkdirSync, utimesSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";
import { describe, expect, test } from "bun:test";
import {
  BASE_URL, VOICE_FIXTURE, WAVEFORM, auth, connect, db, json, makeMatch, onlyRow, send, sendText, uploadOk, type ApiMessage, type Pair,
} from "./chat-helpers";
import { jpegWithGps } from "./media-helpers";
import { createChatMediaService, STRAY_MIN_AGE_MS } from "../src/features/chat/application/chat-media-service";
import { createChatStorage } from "../src/features/chat/infra/chat-storage";
import { createDiskObjectStore } from "../src/shared/storage/disk-object-store";
import { postgresMediaRepository } from "../src/features/chat/infra/postgres-media-repository";
import { postgresMessageRepository } from "../src/features/chat/infra/postgres-message-repository";
import { sharpChatImages } from "../src/features/chat/infra/sharp-chat-images";

// GDPR erasure: when an account (and with it its matches, conversations and
// messages) is deleted, the chat FILES go too, not only the rows.

const UPLOADS = process.env.UPLOADS_DIR ?? "uploads";
const admin = { "x-admin-password": process.env.ADMIN_PASSWORD ?? "dev-admin-pass" };
const onDisk = (key: string) => Bun.file(`${UPLOADS}/${key}`).exists();
const deleteAccount = (userId: number) => fetch(`${BASE_URL}/api/admin/users/${userId}`, { method: "DELETE", headers: admin });

async function keysOf(ids: number[]): Promise<string[]> {
  const rows = await db<{ storage_key: string }[]>`SELECT storage_key FROM message_media WHERE id IN ${db(ids)}`;
  return rows.map((r) => r.storage_key);
}

async function conversationWithFiles(label: string) {
  const pair = await makeMatch(label);
  const ids: number[] = [];
  const photo = await uploadOk(pair.a.token, pair.conversationId, { kind: "photo", file: await jpegWithGps(60, 60, 1) });
  await send(pair.a.token, pair.conversationId, { type: "photo", content: "légende", media_ids: [photo.id] });
  const voice = await uploadOk(pair.b.token, pair.conversationId, { kind: "voice", file: VOICE_FIXTURE, durationMs: 1000, waveform: WAVEFORM });
  await send(pair.b.token, pair.conversationId, { type: "voice", media_ids: [voice.id] });
  const unattached = await uploadOk(pair.a.token, pair.conversationId, { kind: "photo", file: await jpegWithGps(60, 60, 1) });
  ids.push(photo.id, voice.id, unattached.id);
  return { pair, ids, keys: await keysOf(ids) };
}

describe("deleting an account erases its chat files", () => {
  test("every file of its conversations is gone from disk, uploaded by either member, sent or not", async () => {
    const { pair, ids, keys } = await conversationWithFiles("erase");
    expect(keys).toHaveLength(3);
    for (const key of keys) expect(await onDisk(key)).toBe(true);

    const res = await deleteAccount(pair.a.id);
    expect(res.status).toBe(200);

    for (const key of keys) expect([key, await onDisk(key)]).toEqual([key, false]);
    const left = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM message_media WHERE id IN ${db(ids)}`;
    expect(onlyRow(left).n).toBe("0");
    const user = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM users WHERE id = ${pair.a.id}`;
    expect(onlyRow(user).n).toBe("0");
    const conversations = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM conversations WHERE id = ${pair.conversationId}`;
    expect(onlyRow(conversations).n).toBe("0");
  });

  test("the other member keeps nothing of that conversation either, and the signed URLs stop working", async () => {
    const { pair } = await conversationWithFiles("erase2");
    const listed = (await (await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/messages`, { headers: auth(pair.b.token) })).json()) as { messages: ApiMessage[] };
    const url = listed.messages.flatMap((m) => m.media.map((x) => x.url))[0]!;
    expect((await fetch(url.startsWith("http") ? url : `${BASE_URL}${url}`)).status).toBe(200);
    await deleteAccount(pair.a.id);
    expect((await fetch(url.startsWith("http") ? url : `${BASE_URL}${url}`)).status).toBe(404);
    expect((await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/messages`, { headers: auth(pair.b.token) })).status).toBe(404);
  });

  test("another conversation of the same member is erased too; a conversation between two other people is not", async () => {
    const first = await conversationWithFiles("erase3");
    const bystanders = await conversationWithFiles("erase3x");
    // the member also talks to somebody else
    const swipe = (token: string, target: number) => fetch(`${BASE_URL}/api/swipes`, { method: "POST", headers: json(token), body: JSON.stringify({ target_user_id: target, action: "like" }) });
    await swipe(first.pair.a.token, bystanders.pair.b.id);
    await swipe(bystanders.pair.b.token, first.pair.a.id);
    const second = (await (await fetch(`${BASE_URL}/api/conversations`, { headers: auth(first.pair.a.token) })).json()) as { conversations: Array<{ id: number }> };
    const otherId = second.conversations.find((c) => c.id !== first.pair.conversationId)!.id;
    const extra = await uploadOk(first.pair.a.token, otherId, { kind: "photo", file: await jpegWithGps(60, 60, 1) });
    const [extraKey] = await keysOf([extra.id]);

    await deleteAccount(first.pair.a.id);
    expect(await onDisk(extraKey!)).toBe(false);
    for (const key of first.keys) expect(await onDisk(key)).toBe(false);
    for (const key of bystanders.keys) expect([key, await onDisk(key)]).toEqual([key, true]);
  });

  test("a conversation with no match behind it no longer blocks the deletion, and its files go", async () => {
    const pair = await makeMatch("erase4");
    const [loose] = await db<{ id: number }[]>`INSERT INTO conversations (match_id, user1_id, user2_id) VALUES (NULL, ${pair.a.id}, ${pair.b.id}) RETURNING id`;
    const photo = await uploadOk(pair.a.token, loose!.id, { kind: "photo", file: await jpegWithGps(60, 60, 1) });
    await send(pair.a.token, loose!.id, { type: "photo", media_ids: [photo.id] });
    const [key] = await keysOf([photo.id]);
    expect(await onDisk(key!)).toBe(true);

    const res = await deleteAccount(pair.b.id);
    expect(res.status).toBe(200);
    expect(await onDisk(key!)).toBe(false);
    const gone = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM users WHERE id = ${pair.b.id}`;
    expect(onlyRow(gone).n).toBe("0");
  });

  test("a deletion that fails leaves the files alone", async () => {
    const { pair, keys } = await conversationWithFiles("erase5");
    // The admin route cannot be made to fail on purpose, so the failure is a real one:
    // no admin credentials, nothing happens.
    const refused = await fetch(`${BASE_URL}/api/admin/users/${pair.a.id}`, { method: "DELETE", headers: { "x-admin-password": "wrong" } });
    expect(refused.status).toBe(401);
    for (const key of keys) expect(await onDisk(key)).toBe(true);
  });
});

describe("the stray-file sweep, with the real repositories and disk", () => {
  const service = () => createChatMediaService({
    messages: postgresMessageRepository, media: postgresMediaRepository, storage: createChatStorage(createDiskObjectStore(UPLOADS)), images: sharpChatImages, now: () => new Date(),
  });
  const plant = (key: string, ageMs: number) => {
    const path = `${UPLOADS}/${key}`;
    mkdirSync(dirname(path), { recursive: true });
    writeFileSync(path, "stray");
    const when = new Date(Date.now() - ageMs);
    utimesSync(path, when, when);
  };

  test("removes an old file nobody owns; keeps a young one, an owned one and anything outside chat/", async () => {
    const mine = await makeMatch("sweep");
    const owned = await uploadOk(mine.a.token, mine.conversationId, { kind: "photo", file: await jpegWithGps(40, 40, 1) });
    const [ownedKey] = await keysOf([owned.id]);
    const old = new Date(Date.now() - 5 * STRAY_MIN_AGE_MS);
    utimesSync(`${UPLOADS}/${ownedKey}`, old, old); // old, but a row owns it

    const tag = `${Date.now()}-${Math.floor(Math.random() * 1e6)}`;
    plant(`chat/999999/stray-old-${tag}.jpg`, 2 * STRAY_MIN_AGE_MS);
    plant(`chat/999999/in-flight-${tag}.jpg`, STRAY_MIN_AGE_MS / 2);
    plant(`chat/preview-cache/stray-cache-${tag}.jpg`, 3 * STRAY_MIN_AGE_MS);
    plant(`photos/profile-like-${tag}.jpg`, 9 * STRAY_MIN_AGE_MS);

    expect(await service().sweepStrayFiles()).toBeGreaterThanOrEqual(2);

    expect(await onDisk(`chat/999999/stray-old-${tag}.jpg`)).toBe(false);
    expect(await onDisk(`chat/preview-cache/stray-cache-${tag}.jpg`)).toBe(false);
    expect(await onDisk(`chat/999999/in-flight-${tag}.jpg`)).toBe(true);
    expect(await onDisk(ownedKey!)).toBe(true);
    expect(await onDisk(`photos/profile-like-${tag}.jpg`)).toBe(true);
  });

  test("a file the preview cache still owns survives", async () => {
    const tag = `${Date.now()}-${Math.floor(Math.random() * 1e6)}`;
    const key = `chat/preview-cache/cached-${tag}.jpg`;
    plant(key, 5 * STRAY_MIN_AGE_MS);
    await db`INSERT INTO link_preview_cache (url, data, fetched_at) VALUES (${`https://cache.example/${tag}`}, ${db.json({ title: "t", description: null, siteName: null, imageKey: key, imageWidth: 1, imageHeight: 1 })}, NOW())`;
    await service().sweepStrayFiles();
    expect(await onDisk(key)).toBe(true);
  });
});

describe("a reported message that is then unsent keeps its text only for moderation", () => {
  const SECRET = "texte-de-preuve-unique-7f3a";

  test("no route the members use ever shows it again; the admin report list does", async () => {
    const pair: Pair = await makeMatch("retention");
    const watcherA = await connect(pair.a.token);
    const watcherB = await connect(pair.b.token);
    try {
      const message = await sendText(pair.a.token, pair.conversationId, SECRET);
      // The original delivery legitimately carries the text; what follows must not.
      await watcherA.next("chat:message");
      await watcherB.next("chat:message");
      expect((await fetch(`${BASE_URL}/api/messages/${message.id}/report`, { method: "POST", headers: json(pair.b.token), body: JSON.stringify({ reason: "harassment" }) })).status).toBe(200);
      const unsend = await fetch(`${BASE_URL}/api/messages/${message.id}/unsend`, { method: "POST", headers: json(pair.a.token) });
      expect(unsend.status).toBe(200);

      const seen: string[] = [await unsend.text()];
      for (const token of [pair.a.token, pair.b.token]) {
        seen.push(await (await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/messages`, { headers: auth(token) })).text());
        seen.push(await (await fetch(`${BASE_URL}/api/conversations`, { headers: auth(token) })).text());
        seen.push(await (await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}`, { headers: auth(token) })).text());
      }
      for (const watcher of [watcherA, watcherB]) {
        const frame = await watcher.next("chat:updated");
        seen.push(JSON.stringify(frame));
      }
      await new Promise((r) => setTimeout(r, 200));
      for (const watcher of [watcherA, watcherB]) seen.push(JSON.stringify(watcher.events));
      for (const body of seen) expect(body).not.toContain(SECRET);

      const reports = (await (await fetch(`${BASE_URL}/api/admin/reports?limit=200`, { headers: admin })).json()) as { reports: Array<{ message_id: number | null; reported_message_content?: string | null; reported_message_unsent?: boolean }> };
      const report = reports.reports.find((r) => r.message_id === message.id);
      expect(report?.reported_message_content).toBe(SECRET);
      expect(report?.reported_message_unsent).toBe(true);
    } finally {
      watcherA.close();
      watcherB.close();
    }
  });

  test("an unsent message that was never reported is erased in the database", async () => {
    const pair = await makeMatch("retention2");
    const message = await sendText(pair.a.token, pair.conversationId, SECRET);
    await fetch(`${BASE_URL}/api/messages/${message.id}/unsend`, { method: "POST", headers: json(pair.a.token) });
    const row = onlyRow(await db<{ content: string }[]>`SELECT content FROM messages WHERE id = ${message.id}`);
    expect(row.content).toBe("");
  });
});
