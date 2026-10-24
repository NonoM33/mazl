import { beforeEach, describe, expect, test } from "bun:test";
import { createLinkPreviewService, PREVIEW_CONCURRENCY, PREVIEW_QUEUE } from "../../src/features/chat/application/link-preview-service";
import { createMessagePresenter } from "../../src/features/chat/application/message-presenter";
import { limitImageProcessing } from "../../src/features/chat/application/limited-images";
import { createSemaphore, SemaphoreFullError } from "../../src/features/chat/application/semaphore";
import { ChatError } from "../../src/features/chat/domain/errors";
import type { ChatImageProcessor, ProcessedImage } from "../../src/features/chat/application/ports";
import type { FetchOutcome } from "../../src/features/chat/application/guarded-fetch";
import { FakeFetcher, FakeImages, FakeMessageRepository, FakePreviewCache, FakeStorage, RecordingEvents, T0, htmlPage } from "./chat-fakes";

// Security: link previews and image re-encoding are the two heavy things a user
// can trigger by sending a message. Neither may run unbounded in parallel.

interface Deferred<T> { promise: Promise<T>; resolve: (value: T) => void; reject: (error: unknown) => void }
function deferred<T>(): Deferred<T> {
  let resolve!: (value: T) => void;
  let reject!: (error: unknown) => void;
  const promise = new Promise<T>((res, rej) => { resolve = res; reject = rej; });
  return { promise, resolve, reject };
}
const tick = (): Promise<void> => new Promise((resolve) => setTimeout(resolve, 0));

describe("semaphore", () => {
  test("never runs more than `permits` tasks at once, and runs the queued ones as slots free up", async () => {
    const semaphore = createSemaphore({ permits: 2, maxQueue: 10 });
    let running = 0;
    let peak = 0;
    const gates = Array.from({ length: 6 }, () => deferred<void>());
    const results = gates.map((gate, i) => semaphore.run(async () => {
      running++;
      peak = Math.max(peak, running);
      await gate.promise;
      running--;
      return i;
    }));
    await tick();
    expect(running).toBe(2);
    for (const gate of gates) { gate.resolve(); await tick(); }
    expect(await Promise.all(results)).toEqual([0, 1, 2, 3, 4, 5]);
    expect(peak).toBe(2);
  });

  test("starts the queued tasks in the order they arrived", async () => {
    const semaphore = createSemaphore({ permits: 1, maxQueue: 10 });
    const order: number[] = [];
    const first = deferred<void>();
    const all = [
      semaphore.run(async () => { await first.promise; order.push(0); }),
      semaphore.run(async () => { order.push(1); }),
      semaphore.run(async () => { order.push(2); }),
    ];
    first.resolve();
    await Promise.all(all);
    expect(order).toEqual([0, 1, 2]);
  });

  test("refuses at once when the queue is full", async () => {
    const semaphore = createSemaphore({ permits: 1, maxQueue: 2 });
    const hold = deferred<void>();
    const accepted = [1, 2, 3].map(() => semaphore.run(() => hold.promise));
    await expect(semaphore.run(async () => "late")).rejects.toBeInstanceOf(SemaphoreFullError);
    hold.resolve();
    await Promise.all(accepted);
  });

  test("a failing task frees its slot", async () => {
    const semaphore = createSemaphore({ permits: 1, maxQueue: 1 });
    await expect(semaphore.run(async () => { throw new Error("boom"); })).rejects.toThrow("boom");
    expect(await semaphore.run(async () => "next")).toBe("next");
    expect(semaphore.active).toBe(0);
    expect(semaphore.waiting).toBe(0);
  });
});

describe("image processing limiter", () => {
  class SlowImages implements ChatImageProcessor {
    running = 0;
    peak = 0;
    readonly gates: Array<Deferred<void>> = [];
    private async work(): Promise<ProcessedImage> {
      this.running++;
      this.peak = Math.max(this.peak, this.running);
      const gate = deferred<void>();
      this.gates.push(gate);
      await gate.promise;
      this.running--;
      return { bytes: Uint8Array.from([1]), width: 1, height: 1 };
    }
    toChatJpeg = (): Promise<ProcessedImage> => this.work();
    toPreviewJpeg = (): Promise<ProcessedImage> => this.work();
  }

  test("20 simultaneous uploads re-encode at most 3 at a time, and all complete", async () => {
    const inner = new SlowImages();
    const limited = limitImageProcessing(inner, createSemaphore({ permits: 3, maxQueue: 50 }));
    const done = Array.from({ length: 20 }, () => limited.toChatJpeg(Uint8Array.of(1)));
    for (let i = 0; i < 20; i++) {
      await tick();
      expect(inner.running).toBeLessThanOrEqual(3);
      inner.gates[i]?.resolve();
    }
    await Promise.all(done);
    expect(inner.peak).toBe(3);
  });

  test("previews and chat photos share the same budget", async () => {
    const inner = new SlowImages();
    const limited = limitImageProcessing(inner, createSemaphore({ permits: 3, maxQueue: 50 }));
    const done = [
      ...Array.from({ length: 5 }, () => limited.toChatJpeg(Uint8Array.of(1))),
      ...Array.from({ length: 5 }, () => limited.toPreviewJpeg(Uint8Array.of(1))),
    ];
    await tick();
    expect(inner.running).toBe(3);
    for (let i = 0; i < 10; i++) { await tick(); inner.gates[i]?.resolve(); }
    await Promise.all(done);
  });

  test("when the queue is full the caller gets a 'busy' ChatError, not an unbounded wait", async () => {
    const inner = new SlowImages();
    const limited = limitImageProcessing(inner, createSemaphore({ permits: 1, maxQueue: 1 }));
    const accepted = [limited.toChatJpeg(Uint8Array.of(1)), limited.toChatJpeg(Uint8Array.of(1))];
    const refused = await limited.toChatJpeg(Uint8Array.of(1)).catch((error: unknown) => error);
    expect(refused).toBeInstanceOf(ChatError);
    expect((refused as ChatError).kind).toBe("busy");
    for (let i = 0; i < 2; i++) { await tick(); inner.gates[i]?.resolve(); }
    await Promise.all(accepted);
  });
});

describe("link preview concurrency", () => {
  const CONV = 10;
  const ALICE = 1;
  const BOB = 2;
  let repo: FakeMessageRepository;
  let gates: Map<string, Deferred<FetchOutcome>>;
  let started: string[];
  let jobs: Promise<void>[];

  beforeEach(() => {
    repo = new FakeMessageRepository();
    repo.addConversation(CONV, ALICE, BOB);
    gates = new Map();
    started = [];
    jobs = [];
  });

  function previewsOver(): ReturnType<typeof createLinkPreviewService> {
    const responses: Record<string, () => Promise<FetchOutcome>> = {};
    for (let i = 0; i < 200; i++) {
      const url = `https://site${i}.example/p`;
      responses[url] = () => {
        started.push(url);
        const gate = deferred<FetchOutcome>();
        gates.set(url, gate);
        return gate.promise;
      };
    }
    return createLinkPreviewService({
      fetcher: new FakeFetcher(responses), images: new FakeImages(), storage: new FakeStorage(), cache: new FakePreviewCache(),
      repository: repo, events: new RecordingEvents(), now: () => T0,
      presenter: createMessagePresenter({ repository: repo, signUrl: (id) => `https://signed.example/m/${id}` }),
      runInBackground: (job) => { jobs.push(job); },
    });
  }

  async function messageWith(url: string) {
    const outcome = await repo.insert({ conversationId: CONV, senderId: ALICE, clientId: null, type: "text", content: url, replyToId: null, mediaIds: [] });
    if (outcome.kind !== "created") throw new Error("setup");
    return outcome.message;
  }

  test("100 messages with a link fetch at most 4 pages at a time and drop what exceeds the queue", async () => {
    const previews = previewsOver();
    for (let i = 0; i < 100; i++) previews.schedule(await messageWith(`https://site${i}.example/p`));
    await tick();
    expect(PREVIEW_CONCURRENCY).toBe(4);
    expect(started).toHaveLength(PREVIEW_CONCURRENCY);

    // release them one by one: the running count never goes above 4
    let released = 0;
    while (released < started.length) {
      const url = started[released] as string;
      gates.get(url)?.resolve(htmlPage('<meta property="og:title" content="T">'));
      released++;
      await tick();
      expect(started.length - released).toBeLessThanOrEqual(PREVIEW_CONCURRENCY);
    }
    await Promise.all(jobs);
    // 4 that ran at once + the bounded queue; the other 76 were dropped
    expect(started).toHaveLength(PREVIEW_CONCURRENCY + PREVIEW_QUEUE);
    expect(started.length).toBeLessThan(100);
  });

  test("a dropped preview never rejects the background job", async () => {
    const previews = previewsOver();
    for (let i = 0; i < 100; i++) previews.schedule(await messageWith(`https://site${i}.example/p`));
    await tick();
    // queued previews only start once a running one ends: keep releasing what has started
    for (let released = 0; released < PREVIEW_CONCURRENCY + PREVIEW_QUEUE; released++) {
      gates.get(started[released] as string)?.resolve(htmlPage("<html></html>"));
      await tick();
    }
    const settled = await Promise.allSettled(jobs);
    expect(settled.every((result) => result.status === "fulfilled")).toBe(true);
  });
});
