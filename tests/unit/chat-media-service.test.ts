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


describe("erasure of a user's chat files (GDPR)", () => {
  const key = (conversation: number, name: string) => `chat/${conversation}/${name}`;

  async function seed() {
    messages.addConversation(11, ALICE, EVE);
    mediaRepo.members.set(CONV, [ALICE, BOB]);
    mediaRepo.members.set(11, [ALICE, EVE]);
    const files: Array<[number, string, number, "photo" | "voice", "attachment" | "preview", number | null]> = [
      [CONV, "alice.jpg", ALICE, "photo", "attachment", 1],
      [CONV, "bob.m4a", BOB, "voice", "attachment", 2],
      [CONV, "unsent-yet.jpg", ALICE, "photo", "attachment", null],
      [CONV, "preview.jpg", ALICE, "photo", "preview", 3],
      [11, "with-eve.jpg", ALICE, "photo", "attachment", 4],
    ];
    for (const [conversationId, name, uploaderId, kind, role, messageId] of files) {
      await storage.save(key(conversationId, name), new Uint8Array([1]));
      await mediaRepo.insert({ conversationId, uploaderId, kind, role, storageKey: key(conversationId, name), width: null, height: null, durationMs: null, waveform: null });
      if (messageId !== null) mediaRepo.rows[mediaRepo.rows.length - 1] = { ...mediaRepo.rows.at(-1)!, messageId };
    }
    messages.addConversation(12, BOB, EVE);
    mediaRepo.members.set(12, [BOB, EVE]);
    await storage.save(key(12, "not-alices.jpg"), new Uint8Array([1]));
    await mediaRepo.insert({ conversationId: 12, uploaderId: BOB, kind: "photo", storageKey: key(12, "not-alices.jpg"), width: null, height: null, durationMs: null, waveform: null });
  }

  test("every file of every conversation of the user goes, whoever uploaded it, sent or not; other people's files stay", async () => {
    await seed();
    await service.eraseUserMedia(ALICE, async () => { mediaRepo.rows.length = 0; });
    expect([...storage.files.keys()]).toEqual([key(12, "not-alices.jpg")]);
  });

  test("the keys are collected BEFORE the deletion runs (the cascade would hide them) and files go only AFTER it", async () => {
    await seed();
    const seenDuringDeletion: number[] = [];
    await service.eraseUserMedia(ALICE, async () => {
      seenDuringDeletion.push(storage.files.size); // files still there while the database is being cleaned
      mediaRepo.rows.length = 0; // the cascade: the rows can no longer tell us the keys
    });
    expect(seenDuringDeletion).toEqual([6]);
    expect(storage.files.size).toBe(1);
  });

  test("when the deletion fails nothing is removed from disk and the error is passed on", async () => {
    await seed();
    await expect(service.eraseUserMedia(ALICE, async () => { throw new Error("fk violation"); })).rejects.toThrow("fk violation");
    expect(storage.files.size).toBe(6);
  });

  test("returns the deletion's own result", async () => {
    expect(await service.eraseUserMedia(ALICE, async () => ({ deleted: true }))).toEqual({ deleted: true });
  });

  test("a file that cannot be removed does not undo the deletion; the others still go", async () => {
    await seed();
    storage.failRemoveFor.add(key(CONV, "alice.jpg"));
    await service.eraseUserMedia(ALICE, async () => { mediaRepo.rows.length = 0; });
    expect([...storage.files.keys()].sort()).toEqual([key(CONV, "alice.jpg"), key(12, "not-alices.jpg")].sort());
  });
});

describe("sweep of stray files (safety net)", () => {
  const HOUR = 3_600_000;
  const stray = async (name: string, ageMs: number) => {
    storage.savedAt = new Date(clock.getTime() - ageMs);
    await storage.save(name, new Uint8Array([1]));
  };

  test("deletes files without a row older than 1 hour; keeps younger ones (an upload in flight), referenced ones and files outside chat/", async () => {
    clock = new Date(T0.getTime() + 10 * HOUR);
    await stray("chat/10/stray-old.jpg", 2 * HOUR);
    await stray("chat/10/stray-just-over.jpg", HOUR + 1000);
    await stray("chat/10/in-flight.jpg", HOUR - 1000);
    await stray("chat/10/brand-new.jpg", 0);
    await stray("chat/10/owned.jpg", 5 * HOUR);
    await mediaRepo.insert({ conversationId: CONV, uploaderId: ALICE, kind: "photo", storageKey: "chat/10/owned.jpg", width: null, height: null, durationMs: null, waveform: null });
    await stray("chat/preview-cache/cached.jpg", 5 * HOUR);
    mediaRepo.cacheKeys.add("chat/preview-cache/cached.jpg");
    await stray("chat/preview-cache/expired.jpg", 5 * HOUR);
    await stray("photos/profile-of-someone.jpg", 9 * HOUR);
    await stray("chat-lookalike/x.jpg", 9 * HOUR);

    expect(await service.sweepStrayFiles()).toBe(3);
    expect([...storage.files.keys()].sort()).toEqual([
      "chat-lookalike/x.jpg", "chat/10/brand-new.jpg", "chat/10/in-flight.jpg", "chat/10/owned.jpg",
      "chat/preview-cache/cached.jpg", "photos/profile-of-someone.jpg",
    ].sort());
  });

  test("exactly one hour old is still left alone", async () => {
    clock = new Date(T0.getTime() + 10 * HOUR);
    await stray("chat/10/edge.jpg", HOUR);
    expect(await service.sweepStrayFiles()).toBe(0);
  });

  test("a failing removal does not stop the sweep", async () => {
    clock = new Date(T0.getTime() + 10 * HOUR);
    await stray("chat/10/a.jpg", 2 * HOUR);
    await stray("chat/10/b.jpg", 2 * HOUR);
    storage.failRemoveFor.add("chat/10/a.jpg");
    expect(await service.sweepStrayFiles()).toBe(1);
    expect([...storage.files.keys()]).toEqual(["chat/10/a.jpg"]);
  });

  test("ownership is looked up in bounded batches", async () => {
    clock = new Date(T0.getTime() + 10 * HOUR);
    for (let i = 0; i < 1200; i++) storage.files.set(`chat/10/f${i}.jpg`, new Uint8Array([1])), storage.modified.set(`chat/10/f${i}.jpg`, new Date(0));
    expect(await service.sweepStrayFiles()).toBe(1200);
    expect(mediaRepo.referenceLookups.every((n) => n <= 500)).toBe(true);
    expect(mediaRepo.referenceLookups.reduce((a, b) => a + b, 0)).toBe(1200);
  });

  test("an empty store is fine", async () => {
    expect(await service.sweepStrayFiles()).toBe(0);
  });
});
