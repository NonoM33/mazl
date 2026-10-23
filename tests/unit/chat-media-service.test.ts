import { beforeEach, describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { createChatMediaService, MAX_PENDING_PER_USER, ORPHAN_AGE_MS, type ChatMediaService } from "../../src/features/chat/application/chat-media-service";
import { ChatError } from "../../src/features/chat/domain/errors";
import { FakeImages, FakeMediaRepository, FakeMessageRepository, FakeStorage, T0 } from "./chat-fakes";

const ALICE = 1;
const BOB = 2;
const EVE = 3;
const CONV = 10;
const voiceFile = new Uint8Array(readFileSync(join(import.meta.dir, "../fixtures/chat/voice.m4a")));
const waveform = JSON.stringify(Array.from({ length: 48 }, (_, i) => i));

let messages: FakeMessageRepository;
let mediaRepo: FakeMediaRepository;
let storage: FakeStorage;
let clock: Date;
let service: ChatMediaService;

beforeEach(() => {
  messages = new FakeMessageRepository();
  messages.addConversation(CONV, ALICE, BOB);
  mediaRepo = new FakeMediaRepository();
  storage = new FakeStorage();
  clock = T0;
  service = createChatMediaService({ messages, media: mediaRepo, storage, images: new FakeImages(), now: () => clock });
});

async function failure(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
    return "no error";
  } catch (error: unknown) {
    return error instanceof ChatError ? `${error.kind}:${error.detail}` : `other:${String(error)}`;
  }
}

describe("photo upload", () => {
  test("stores the re-encoded bytes under a random key and returns a signed URL", async () => {
    const view = await service.uploadPhoto(ALICE, CONV, Uint8Array.from([1, 2, 3, 4]));
    expect(view).toMatchObject({ kind: "photo", width: 640, height: 480 });
    expect(view.url).toMatch(/\/media\/chat\/\d+\?exp=\d+&sig=[A-Za-z0-9_-]+$/);
    const row = mediaRepo.rows[0]!;
    expect(row.storageKey).toMatch(/^chat\/10\/[0-9a-f-]{36}\.jpg$/);
    expect(row.messageId).toBeNull();
    expect(await storage.read(row.storageKey)).toEqual(Uint8Array.from([0xff, 0xd8, 0xff, 0x01]));
  });

  test("an undecodable image is refused and nothing is stored", async () => {
    expect(await failure(service.uploadPhoto(ALICE, CONV, Uint8Array.from([1])))).toStartWith("invalid:");
    expect(mediaRepo.rows).toHaveLength(0);
    expect(storage.files.size).toBe(0);
  });

  test("empty and over 10 MB", async () => {
    expect(await failure(service.uploadPhoto(ALICE, CONV, new Uint8Array()))).toStartWith("invalid:");
    expect(await failure(service.uploadPhoto(ALICE, CONV, new Uint8Array(10 * 1024 * 1024 + 1)))).toStartWith("too_large:");
  });

  test("a failing database insert removes the file again", async () => {
    mediaRepo.insert = async () => { throw new Error("db down"); };
    expect(await failure(service.uploadPhoto(ALICE, CONV, Uint8Array.from([1, 2, 3])))).toStartWith("other:");
    expect(storage.files.size).toBe(0);
  });
});

describe("voice upload", () => {
  const upload = (overrides: Partial<{ bytes: Uint8Array; durationMs: number; waveform: string }> = {}) =>
    service.uploadVoice(ALICE, CONV, { bytes: voiceFile, durationMs: 8300, waveform, ...overrides });

  test("a real AAC note is stored with its duration and waveform", async () => {
    const view = await upload();
    expect(view).toMatchObject({ kind: "voice", duration_ms: 8300 });
    expect(mediaRepo.rows[0]!.storageKey).toMatch(/^chat\/10\/[0-9a-f-]{36}\.m4a$/);
    expect(mediaRepo.rows[0]!.waveform).toHaveLength(48);
  });

  test("the bytes decide: a JPEG sent as a voice note is refused", async () => {
    expect(await failure(upload({ bytes: Uint8Array.from([0xff, 0xd8, 0xff, 0xe0, ...new Array<number>(40).fill(0)]) }))).toStartWith("invalid:");
    expect(storage.files.size).toBe(0);
  });

  test("duration: 1..120000 ms integers", async () => {
    expect((await upload({ durationMs: 120_000 })).kind).toBe("voice");
    for (const durationMs of [0, -5, 120_001, 1.5, Number.NaN]) {
      expect([durationMs, await failure(upload({ durationMs }))]).toEqual([durationMs, expect.stringMatching(/^invalid:/)]);
    }
  });

  test("waveform must be 48 ints in 0..100", async () => {
    expect(await failure(upload({ waveform: "[1,2,3]" }))).toStartWith("invalid:");
    expect(await failure(upload({ waveform: "nope" }))).toStartWith("invalid:");
  });

  test("over 3 MB is too large, even if it would otherwise be valid", async () => {
    const big = new Uint8Array(3 * 1024 * 1024 + 1);
    big.set(voiceFile);
    expect(await failure(upload({ bytes: big }))).toStartWith("too_large:");
  });
});

describe("who may upload", () => {
  test("a non-member gets not_found", async () => {
    expect(await failure(service.uploadPhoto(EVE, CONV, Uint8Array.from([1, 2, 3])))).toBe("not_found:not_found");
  });

  test("a blocked pair cannot upload", async () => {
    messages.blocked.add(`${BOB}:${ALICE}`);
    expect(await failure(service.uploadPhoto(ALICE, CONV, Uint8Array.from([1, 2, 3])))).toStartWith("blocked:");
  });

  test(`at most ${MAX_PENDING_PER_USER} unattached uploads per member`, async () => {
    for (let i = 0; i < MAX_PENDING_PER_USER; i++) await service.uploadPhoto(ALICE, CONV, Uint8Array.from([1, 2, 3]));
    expect(await failure(service.uploadPhoto(ALICE, CONV, Uint8Array.from([1, 2, 3])))).toStartWith("too_many_pending:");
    await service.uploadPhoto(BOB, CONV, Uint8Array.from([1, 2, 3])); // another member is unaffected
  });
});

describe("serving", () => {
  test("content type follows the kind, never the file name", async () => {
    const photo = await service.uploadPhoto(ALICE, CONV, Uint8Array.from([1, 2, 3]));
    const voice = await service.uploadVoice(ALICE, CONV, { bytes: voiceFile, durationMs: 1000, waveform });
    expect((await service.serve(photo.id))?.contentType).toBe("image/jpeg");
    expect((await service.serve(voice.id))?.contentType).toBe("audio/mp4");
  });

  test("unknown row, or a row whose file is gone", async () => {
    expect(await service.serve(999)).toBeNull();
    const photo = await service.uploadPhoto(ALICE, CONV, Uint8Array.from([1, 2, 3]));
    storage.files.clear();
    expect(await service.serve(photo.id)).toBeNull();
  });
});

describe("orphan purge", () => {
  test("deletes unattached uploads older than 24 hours, files and rows, and nothing else", async () => {
    const old = await service.uploadPhoto(ALICE, CONV, Uint8Array.from([1, 2, 3]));
    const attached = await service.uploadPhoto(ALICE, CONV, Uint8Array.from([1, 2, 3]));
    const fresh = await service.uploadPhoto(BOB, CONV, Uint8Array.from([1, 2, 3]));
    const rows = mediaRepo.rows;
    rows[0] = { ...rows[0]!, createdAt: new Date(T0.getTime() - ORPHAN_AGE_MS - 1000) };
    rows[1] = { ...rows[1]!, createdAt: new Date(T0.getTime() - ORPHAN_AGE_MS - 1000), messageId: 77 };
    rows[2] = { ...rows[2]!, createdAt: new Date(T0.getTime() - ORPHAN_AGE_MS + 60_000) };
    const oldKey = rows[0]!.storageKey;

    expect(await service.purgeOrphans()).toBe(1);
    expect(mediaRepo.rows.map((r) => r.id)).toEqual([attached.id, fresh.id]);
    expect(await storage.read(oldKey)).toBeNull();
    expect(old.id).toBe(1);
  });

  test("a file that cannot be removed keeps its row for the next run", async () => {
    await service.uploadPhoto(ALICE, CONV, Uint8Array.from([1, 2, 3]));
    mediaRepo.rows[0] = { ...mediaRepo.rows[0]!, createdAt: new Date(T0.getTime() - ORPHAN_AGE_MS - 1000) };
    storage.failRemoveFor.add(mediaRepo.rows[0]!.storageKey);
    expect(await service.purgeOrphans()).toBe(0);
    expect(mediaRepo.rows).toHaveLength(1);
  });
});
