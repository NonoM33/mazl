import { beforeAll, describe, expect, test } from "bun:test";
import sharp from "sharp";
import {
  BASE_URL, VOICE_FIXTURE, WAVEFORM, absolute, auth, craftChatUrl, db, makeMatch, send, upload, uploadOk, type ApiMedia, type Pair,
} from "./chat-helpers";
import { EXIF_MARKER, craftSignedUrl, jpegWithGps } from "./media-helpers";
import { createChatMediaService } from "../src/features/chat/application/chat-media-service";
import { postgresMediaRepository } from "../src/features/chat/infra/postgres-media-repository";
import { postgresMessageRepository } from "../src/features/chat/infra/postgres-message-repository";
import { sharpChatImages } from "../src/features/chat/infra/sharp-chat-images";
import { createChatDiskStorage } from "../src/features/chat/infra/disk-chat-storage";

// CONTRAT.md §0.2 and §2 (POST /media, GET /media/chat/:id): same pipeline as
// profile photos, audio checked by its bytes, nothing served unsigned.

// Uploads are rate-limited per member (30 a minute), so each group has its own pair.
let pair: Pair;

const fail = async (res: Response) => ({ status: res.status, body: (await res.json()) as { success: boolean; error?: string } });

describe("photo upload", () => {
  beforeAll(async () => { pair = await makeMatch("mediaphoto"); });

  test("re-encodes: no EXIF/GPS survives, orientation applied, client name and MIME ignored", async () => {
    const media = await uploadOk(pair.a.token, pair.conversationId, {
      kind: "photo", file: await jpegWithGps(300, 100, 6), name: "../../evil.php", mime: "text/html",
    });
    expect(media.kind).toBe("photo");
    expect(media.url).toMatch(/\/media\/chat\/\d+\?exp=\d+&sig=[A-Za-z0-9_-]+$/);
    expect(media.url).not.toContain("evil");
    expect([media.width, media.height]).toEqual([100, 300]); // orientation 6 swaps the sides

    const served = await fetch(absolute(media.url));
    expect(served.status).toBe(200);
    expect(served.headers.get("content-type")).toBe("image/jpeg");
    expect(served.headers.get("cache-control")).toBe("private, max-age=3600");
    expect(served.headers.get("x-content-type-options")).toBe("nosniff");
    const bytes = Buffer.from(await served.arrayBuffer());
    expect([...bytes.subarray(0, 3)]).toEqual([0xff, 0xd8, 0xff]);
    expect(bytes.includes(Buffer.from("Exif\0\0", "binary"))).toBe(false);
    expect(bytes.includes(Buffer.from(EXIF_MARKER))).toBe(false);
    const meta = await sharp(bytes).metadata();
    expect(meta.exif).toBeUndefined();
    expect([meta.width, meta.height]).toEqual([100, 300]);
  });

  test("the stored file is under chat/<conversation>/ with a random name", async () => {
    const media = await uploadOk(pair.a.token, pair.conversationId, { kind: "photo", file: await jpegWithGps(50, 50, 1) });
    const [row] = await db<{ storage_key: string; message_id: number | null; uploader_id: number; conversation_id: number }[]>`
      SELECT storage_key, message_id, uploader_id, conversation_id FROM message_media WHERE id = ${media.id}`;
    expect(row?.storage_key).toMatch(new RegExp(`^chat/${pair.conversationId}/[0-9a-f-]{36}\\.jpg$`));
    expect(row).toMatchObject({ message_id: null, uploader_id: pair.a.id, conversation_id: pair.conversationId });
  });

  test("the long side is capped at 2048 px", async () => {
    const big = await sharp({ create: { width: 3000, height: 1500, channels: 3, background: { r: 1, g: 2, b: 3 } } }).jpeg().toBuffer();
    const media = await uploadOk(pair.a.token, pair.conversationId, { kind: "photo", file: big });
    expect([media.width, media.height]).toEqual([2048, 1024]);
    const bytes = Buffer.from(await (await fetch(absolute(media.url))).arrayBuffer());
    const meta = await sharp(bytes).metadata();
    expect(Math.max(meta.width ?? 0, meta.height ?? 0)).toBe(2048);
  });

  test("PNG is accepted and comes back as JPEG", async () => {
    const png = await sharp({ create: { width: 40, height: 40, channels: 3, background: { r: 200, g: 0, b: 0 } } }).png().toBuffer();
    const media = await uploadOk(pair.a.token, pair.conversationId, { kind: "photo", file: png, mime: "image/png" });
    const bytes = Buffer.from(await (await fetch(absolute(media.url))).arrayBuffer());
    expect([...bytes.subarray(0, 3)]).toEqual([0xff, 0xd8, 0xff]);
  });

  test("refuses what cannot be decoded (PHP, SVG, empty, a voice note sent as a photo), and stores nothing", async () => {
    const before = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM message_media WHERE uploader_id = ${pair.a.id}`;
    for (const file of [
      Buffer.from("<?php system($_GET['c']); ?>"),
      Buffer.from('<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>'),
      Buffer.alloc(0),
      Buffer.from(VOICE_FIXTURE),
    ]) {
      const { status } = await fail(await upload(pair.a.token, pair.conversationId, { kind: "photo", file, name: "x.jpg", mime: "image/jpeg" }));
      expect(status).toBe(400);
    }
    const after = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM message_media WHERE uploader_id = ${pair.a.id}`;
    expect(after[0]?.n).toBe(before[0]?.n);
  });

  test("no file, no kind, a wrong kind, a non-multipart body", async () => {
    expect((await upload(pair.a.token, pair.conversationId, { kind: "photo" })).status).toBe(400);
    expect((await upload(pair.a.token, pair.conversationId, { kind: "video", file: VOICE_FIXTURE })).status).toBe(400);
    const noKind = new FormData();
    noKind.append("file", new File([VOICE_FIXTURE], "v.m4a"));
    expect((await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/media`, { method: "POST", headers: auth(pair.a.token), body: noKind })).status).toBe(400);
    const json = await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/media`, { method: "POST", headers: { ...auth(pair.a.token), "Content-Type": "application/json" }, body: "{}" });
    expect(json.status).toBe(400);
  });

  test("over 10 MB is refused with 413 before it is stored", async () => {
    const huge = new Uint8Array(10 * 1024 * 1024 + 2048);
    huge.set([0xff, 0xd8, 0xff]);
    const { status } = await fail(await upload(pair.a.token, pair.conversationId, { kind: "photo", file: huge }));
    expect(status).toBe(413);
  });
});

describe("voice upload", () => {
  beforeAll(async () => { pair = await makeMatch("mediavoice"); });

  const voice = (overrides: Partial<Parameters<typeof upload>[2]> = {}) =>
    upload(pair.a.token, pair.conversationId, { kind: "voice", file: VOICE_FIXTURE, durationMs: 8300, waveform: WAVEFORM, name: "note.m4a", mime: "audio/mp4", ...overrides });

  test("a real AAC note is stored and served as audio/mp4", async () => {
    const res = await voice();
    expect(res.status).toBe(200);
    const media = ((await res.json()) as { media: ApiMedia }).media;
    expect(media).toMatchObject({ kind: "voice", duration_ms: 8300 });
    expect(media.waveform).toHaveLength(48);
    const served = await fetch(absolute(media.url));
    expect(served.status).toBe(200);
    expect(served.headers.get("content-type")).toBe("audio/mp4");
    expect(served.headers.get("x-content-type-options")).toBe("nosniff");
    expect(new Uint8Array(await served.arrayBuffer())).toEqual(VOICE_FIXTURE);
    const [row] = await db<{ storage_key: string }[]>`SELECT storage_key FROM message_media WHERE id = ${media.id}`;
    expect(row?.storage_key).toMatch(/\.m4a$/);
  });

  test("the bytes decide, not the name or the MIME type", async () => {
    const jpeg = await jpegWithGps(20, 20, 1);
    for (const file of [jpeg, new TextEncoder().encode("ID3 not really an mp3, just a long enough string of text"), new Uint8Array(VOICE_FIXTURE.subarray(0, 12))]) {
      expect((await voice({ file, name: "note.m4a", mime: "audio/mp4" })).status).toBe(400);
    }
  });

  test("a file that merely starts like MP4 but is not AAC audio is refused", async () => {
    const fake = Buffer.concat([Buffer.from([0, 0, 0, 0x18]), Buffer.from("ftypheic"), Buffer.alloc(16), Buffer.from([0, 0, 0, 8]), Buffer.from("mdat")]);
    expect((await voice({ file: new Uint8Array(fake) })).status).toBe(400);
  });

  test("duration must be 1..120000 ms", async () => {
    expect((await voice({ durationMs: 120_000 })).status).toBe(200);
    for (const durationMs of [0, -1, 120_001]) expect((await voice({ durationMs })).status).toBe(400);
    const missing = new FormData();
    missing.append("kind", "voice");
    missing.append("file", new File([VOICE_FIXTURE], "v.m4a"));
    missing.append("waveform", WAVEFORM);
    expect((await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/media`, { method: "POST", headers: auth(pair.a.token), body: missing })).status).toBe(400);
  });

  test("waveform must be 48 integers between 0 and 100", async () => {
    for (const waveform of [JSON.stringify([1, 2, 3]), JSON.stringify(Array.from({ length: 48 }, () => 101)), JSON.stringify(Array.from({ length: 48 }, () => 0.5)), "not json", ""]) {
      expect([waveform.slice(0, 12), (await voice({ waveform })).status]).toEqual([waveform.slice(0, 12), 400]);
    }
  });

  test("over 3 MB is refused", async () => {
    const big = new Uint8Array(3 * 1024 * 1024 + 1);
    big.set(VOICE_FIXTURE);
    expect((await voice({ file: big })).status).toBe(413);
  });
});

describe("signed URLs", () => {
  let media: ApiMedia;
  beforeAll(async () => {
    pair = await makeMatch("mediasigned");
    media = await uploadOk(pair.a.token, pair.conversationId, { kind: "photo", file: await jpegWithGps(40, 40, 1) });
  });

  test("served without a session when the signature is right (it is the credential)", async () => {
    expect((await fetch(absolute(media.url))).status).toBe(200);
  });

  test("a signature computed independently from the contract is accepted", async () => {
    const exp = Math.floor(Date.now() / 1000) + 600;
    expect((await fetch(craftChatUrl(media.id, exp))).status).toBe(200);
  });

  test("expired, tampered, missing, other id and the profile-photo prefix are all the same 404", async () => {
    const past = Math.floor(Date.now() / 1000) - 5;
    const future = Math.floor(Date.now() / 1000) + 600;
    const url = new URL(absolute(media.url));
    const sig = url.searchParams.get("sig")!;
    const attempts = [
      craftChatUrl(media.id, past),
      `${BASE_URL}/media/chat/${media.id}?exp=${url.searchParams.get("exp")}&sig=${sig.slice(0, -2)}AA`,
      `${BASE_URL}/media/chat/${media.id}?exp=${Number(url.searchParams.get("exp")) + 1}&sig=${sig}`,
      `${BASE_URL}/media/chat/${media.id}`,
      `${BASE_URL}/media/chat/${media.id}?exp=${future}`,
      `${BASE_URL}/media/chat/${media.id}?sig=${sig}`,
      craftChatUrl(media.id + 1, future),
      craftChatUrl(media.id, future, "photo"), // a photo signature must not open a chat file
      craftSignedUrl(media.id, future).replace("/media/photos/", "/media/chat/"),
      `${BASE_URL}/media/chat/abc?exp=${future}&sig=${sig}`,
      `${BASE_URL}/media/chat/${media.id}?exp=-1&sig=${sig}`,
    ];
    const bodies = new Set<string>();
    for (const attempt of attempts) {
      const res = await fetch(attempt);
      expect([attempt.slice(0, 80), res.status]).toEqual([attempt.slice(0, 80), 404]);
      bodies.add(await res.text());
    }
    expect(bodies.size).toBe(1);
  });

  test("a signed profile-photo URL pattern does not open chat media either way", async () => {
    const future = Math.floor(Date.now() / 1000) + 600;
    expect((await fetch(craftSignedUrl(media.id, future))).status).toBe(404); // /media/photos/<chat media id>
  });
});

describe("range requests (audio players seek in remote MP4)", () => {
  let media: ApiMedia;
  beforeAll(async () => {
    pair = await makeMatch("mediarange");
    media = await uploadOk(pair.a.token, pair.conversationId, { kind: "voice", file: VOICE_FIXTURE, durationMs: 1000, waveform: WAVEFORM });
  });
  const get = (range?: string) => fetch(absolute(media.url), { headers: range ? { Range: range } : {} });

  test("advertises byte ranges", async () => {
    expect((await get()).headers.get("accept-ranges")).toBe("bytes");
  });
  test("a bounded range gives 206 with the right slice", async () => {
    const res = await get("bytes=10-19");
    expect(res.status).toBe(206);
    expect(res.headers.get("content-range")).toBe(`bytes 10-19/${VOICE_FIXTURE.length}`);
    expect(new Uint8Array(await res.arrayBuffer())).toEqual(VOICE_FIXTURE.subarray(10, 20));
  });
  test("open-ended and suffix ranges", async () => {
    const tail = await get("bytes=-100");
    expect(tail.status).toBe(206);
    expect(new Uint8Array(await tail.arrayBuffer())).toEqual(VOICE_FIXTURE.subarray(VOICE_FIXTURE.length - 100));
    const rest = await get(`bytes=${VOICE_FIXTURE.length - 5}-`);
    expect(new Uint8Array(await rest.arrayBuffer())).toEqual(VOICE_FIXTURE.subarray(VOICE_FIXTURE.length - 5));
  });
  test("a range past the end is 416", async () => {
    const res = await get(`bytes=${VOICE_FIXTURE.length}-`);
    expect(res.status).toBe(416);
    expect(res.headers.get("content-range")).toBe(`bytes */${VOICE_FIXTURE.length}`);
  });
});

describe("media belongs to a conversation", () => {
  beforeAll(async () => { pair = await makeMatch("mediabelong"); });

  test("the other member can open it by its signed URL once it is in a message, and a stranger could not have uploaded it", async () => {
    const photo = await uploadOk(pair.a.token, pair.conversationId, { kind: "photo", file: await jpegWithGps(40, 40, 1) });
    const sent = await send(pair.a.token, pair.conversationId, { type: "photo", media_ids: [photo.id] });
    const listed = (await (await fetch(`${BASE_URL}/api/conversations/${pair.conversationId}/messages?limit=1`, { headers: auth(pair.b.token) })).json()) as { messages: Array<{ media: ApiMedia[] }> };
    expect(sent.status).toBe(200);
    expect((await fetch(absolute(listed.messages[0]!.media[0]!.url))).status).toBe(200);
    // every URL in the list is freshly signed for the viewer's request, valid one hour
    const exp = Number(new URL(absolute(listed.messages[0]!.media[0]!.url)).searchParams.get("exp"));
    expect(exp - Math.floor(Date.now() / 1000)).toBeGreaterThan(3500);
    expect(exp - Math.floor(Date.now() / 1000)).toBeLessThanOrEqual(3600);
  });

  test("a row whose file vanished from disk is a 404, not a crash", async () => {
    const photo = await uploadOk(pair.a.token, pair.conversationId, { kind: "photo", file: await jpegWithGps(40, 40, 1) });
    const [row] = await db<{ storage_key: string }[]>`SELECT storage_key FROM message_media WHERE id = ${photo.id}`;
    await Bun.file(`${process.env.UPLOADS_DIR ?? "uploads"}/${row!.storage_key}`).delete();
    expect((await fetch(absolute(photo.url))).status).toBe(404);
  });
});

describe("orphan purge (24 h), with the real repositories and disk", () => {
  test("removes unattached uploads older than 24 h, files included; keeps attached and recent ones", async () => {
    const mine = await makeMatch("purge");
    const old = await uploadOk(mine.a.token, mine.conversationId, { kind: "photo", file: await jpegWithGps(30, 30, 1) });
    const recent = await uploadOk(mine.a.token, mine.conversationId, { kind: "photo", file: await jpegWithGps(30, 30, 1) });
    const used = await uploadOk(mine.a.token, mine.conversationId, { kind: "photo", file: await jpegWithGps(30, 30, 1) });
    await send(mine.a.token, mine.conversationId, { type: "photo", media_ids: [used.id] });
    await db`UPDATE message_media SET created_at = NOW() - INTERVAL '25 hours' WHERE id IN (${old.id}, ${used.id})`;
    await db`UPDATE message_media SET created_at = NOW() - INTERVAL '23 hours' WHERE id = ${recent.id}`;
    const keys = Object.fromEntries((await db<{ id: number; storage_key: string }[]>`SELECT id, storage_key FROM message_media WHERE id IN (${old.id}, ${recent.id}, ${used.id})`).map((r) => [r.id, r.storage_key]));
    const onDisk = (id: number) => Bun.file(`${process.env.UPLOADS_DIR ?? "uploads"}/${keys[id]}`).exists();

    const service = createChatMediaService({
      messages: postgresMessageRepository, media: postgresMediaRepository,
      storage: createChatDiskStorage(process.env.UPLOADS_DIR ?? "uploads"), images: sharpChatImages, now: () => new Date(),
    });
    expect(await service.purgeOrphans()).toBeGreaterThanOrEqual(1);

    const left = await db<{ id: number }[]>`SELECT id FROM message_media WHERE id IN (${old.id}, ${recent.id}, ${used.id}) ORDER BY id`;
    expect(left.map((r) => r.id)).toEqual([recent.id, used.id]);
    expect(await onDisk(old.id)).toBe(false);
    expect(await onDisk(recent.id)).toBe(true);
    expect(await onDisk(used.id)).toBe(true);
  });
});
