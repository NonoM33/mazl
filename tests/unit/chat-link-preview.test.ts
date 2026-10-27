import { beforeEach, describe, expect, test } from "bun:test";
import { createGuardedFetcher } from "../../src/features/chat/application/guarded-fetch";
import { createLinkPreviewService, CACHE_TTL_MS, type LinkPreviewService } from "../../src/features/chat/application/link-preview-service";
import { createMessagePresenter } from "../../src/features/chat/application/message-presenter";
import type { PinnedRequest, PinnedTransport } from "../../src/features/chat/application/fetch-ports";
import type { MessageRecord } from "../../src/features/chat/domain/types";
import { FakeFetcher, FakeImages, FakeMessageRepository, FakePreviewCache, FakeStorage, RecordingEvents, T0, htmlPage, imageBytes, allowAllReceipts } from "./chat-fakes";

// Link previews, CONTRAT.md §0.5: what is fetched, what is kept, what is shown.

const ALICE = 1;
const BOB = 2;
const CONV = 10;
const PAGE = "https://news.example/article";

const OG_PAGE = `<html><head>
  <meta property="og:title" content="Un bel article">
  <meta property="og:description" content="Le résumé.">
  <meta property="og:site_name" content="News">
  <meta property="og:image" content="/cover.png">
</head></html>`;

let repo: FakeMessageRepository;
let storage: FakeStorage;
let events: RecordingEvents;
let images: FakeImages;
let cache: FakePreviewCache;
let clock: Date;
let jobs: Promise<void>[];

beforeEach(() => {
  repo = new FakeMessageRepository();
  repo.addConversation(CONV, ALICE, BOB);
  storage = new FakeStorage();
  events = new RecordingEvents();
  images = new FakeImages();
  cache = new FakePreviewCache();
  clock = T0;
  jobs = [];
});

function serviceWith(fetcher: FakeFetcher): LinkPreviewService {
  return createLinkPreviewService({
    fetcher, images, storage, cache, repository: repo, events, now: () => clock,
    presenter: createMessagePresenter({ repository: repo, signUrl: (id) => `https://signed.example/m/${id}`, receipts: allowAllReceipts }),
    runInBackground: (job) => { jobs.push(job); },
  });
}

async function textMessage(content: string): Promise<MessageRecord> {
  const outcome = await repo.insert({ conversationId: CONV, senderId: ALICE, clientId: null, type: "text", content, replyToId: null, mediaIds: [] });
  if (outcome.kind !== "created") throw new Error("setup");
  return outcome.message;
}

describe("a page with Open Graph tags", () => {
  test("title, description, site name and a stored image; both members are told with chat:updated", async () => {
    const fetcher = new FakeFetcher({ [PAGE]: htmlPage(OG_PAGE), "https://news.example/cover.png": imageBytes() });
    const message = await textMessage(`regarde ${PAGE}`);
    await serviceWith(fetcher).run(message);

    const stored = repo.messages[0]!.linkPreview!;
    expect(stored).toMatchObject({ url: PAGE, title: "Un bel article", description: "Le résumé.", siteName: "News" });
    expect(stored.imageMediaId).not.toBeNull();
    const image = repo.mediaRows.find((m) => m.id === stored.imageMediaId)!;
    expect(image).toMatchObject({ role: "preview", messageId: message.id, kind: "photo", width: 320, height: 200 });
    // the image is the RE-ENCODED one, never the downloaded bytes
    expect(await storage.read(image.storageKey)).toEqual(Uint8Array.from([0xff, 0xd8, 0xff, 0x02]));
    expect(images.previewCalls).toHaveLength(1);

    const updated = events.ofType("chat:updated");
    expect(updated).toHaveLength(1);
    expect(updated[0]!.to.sort()).toEqual([ALICE, BOB]);
    const view = (updated[0]!.payload as { message: { link_preview: Record<string, unknown>; media: unknown[] } }).message;
    expect(view.link_preview).toEqual({
      url: PAGE, title: "Un bel article", description: "Le résumé.", site_name: "News",
      image_url: `https://signed.example/m/${image.id}`,
    });
    expect(view.media).toEqual([]); // the preview image is not an attachment
  });

  test("a relative og:image is resolved against the page, an absolute one is fetched as is", async () => {
    const fetcher = new FakeFetcher({
      [PAGE]: htmlPage(`<meta property="og:title" content="T"><meta property="og:image" content="https://cdn.example/x.png">`),
      "https://cdn.example/x.png": imageBytes(),
    });
    await serviceWith(fetcher).run(await textMessage(PAGE));
    expect(fetcher.calls.map((c) => [c.url, c.kind])).toEqual([[PAGE, "html"], ["https://cdn.example/x.png", "image"]]);
  });

  test("only the FIRST link of the message is looked at", async () => {
    const fetcher = new FakeFetcher({ [PAGE]: htmlPage(OG_PAGE), "https://news.example/cover.png": imageBytes() });
    await serviceWith(fetcher).run(await textMessage(`${PAGE} puis https://autre.example/`));
    expect(fetcher.calls.filter((c) => c.kind === "html").map((c) => c.url)).toEqual([PAGE]);
  });

  test("schedule() hands the job to the background runner instead of running it inline", async () => {
    const fetcher = new FakeFetcher({ [PAGE]: htmlPage(OG_PAGE), "https://news.example/cover.png": imageBytes() });
    const service = serviceWith(fetcher);
    service.schedule(await textMessage(PAGE));
    expect(jobs).toHaveLength(1);
    expect(fetcher.calls.length).toBeGreaterThanOrEqual(0);
    await jobs[0];
    expect(repo.messages[0]!.linkPreview).not.toBeNull();
  });
});

describe("what goes wrong is silent and leaves no preview", () => {
  test("the page cannot be fetched", async () => {
    const fetcher = new FakeFetcher({ [PAGE]: { ok: false, reason: "blocked_address" } });
    await serviceWith(fetcher).run(await textMessage(PAGE));
    expect(repo.messages[0]!.linkPreview).toBeNull();
    expect(events.sent).toHaveLength(0);
  });

  test("a page with nothing usable", async () => {
    const fetcher = new FakeFetcher({ [PAGE]: htmlPage("<html><body>rien</body></html>") });
    await serviceWith(fetcher).run(await textMessage(PAGE));
    expect(repo.messages[0]!.linkPreview).toBeNull();
  });

  test("the image cannot be fetched: the text preview is kept", async () => {
    const fetcher = new FakeFetcher({ [PAGE]: htmlPage(OG_PAGE), "https://news.example/cover.png": { ok: false, reason: "too_large" } });
    await serviceWith(fetcher).run(await textMessage(PAGE));
    expect(repo.messages[0]!.linkPreview).toMatchObject({ title: "Un bel article", imageMediaId: null });
    expect(repo.mediaRows).toHaveLength(0);
  });

  test("the image is not a decodable raster: the text preview is kept, nothing is stored", async () => {
    images.failPreview = true;
    const fetcher = new FakeFetcher({ [PAGE]: htmlPage(OG_PAGE), "https://news.example/cover.png": imageBytes() });
    await serviceWith(fetcher).run(await textMessage(PAGE));
    expect(repo.messages[0]!.linkPreview).toMatchObject({ title: "Un bel article", imageMediaId: null });
    expect(storage.files.size).toBe(0);
  });

  test("an unexpected failure never escapes the background job", async () => {
    const fetcher = new FakeFetcher({ [PAGE]: async () => { throw new Error("boom"); } });
    await expect(serviceWith(fetcher).run(await textMessage(PAGE))).resolves.toBeUndefined();
  });

  test("the message was unsent while the page was loading: no preview, no stray file, no event", async () => {
    const fetcher = new FakeFetcher({ [PAGE]: htmlPage(OG_PAGE), "https://news.example/cover.png": imageBytes() });
    const message = await textMessage(PAGE);
    await repo.unsend(message.id, clock);
    await serviceWith(fetcher).run(message);
    expect(repo.messages[0]!.linkPreview).toBeNull();
    expect(events.sent).toHaveLength(0);
    expect([...storage.files.keys()].filter((key) => !key.startsWith("chat/preview-cache/"))).toEqual([]);
  });
});

describe("cache, 24 hours per URL", () => {
  test("a second message with the same link does not fetch again, and gets its own copy of the image", async () => {
    const fetcher = new FakeFetcher({ [PAGE]: htmlPage(OG_PAGE), "https://news.example/cover.png": imageBytes() });
    const service = serviceWith(fetcher);
    await service.run(await textMessage(PAGE));
    const callsAfterFirst = fetcher.calls.length;
    clock = new Date(T0.getTime() + CACHE_TTL_MS - 1000);
    await service.run(await textMessage(PAGE));
    expect(fetcher.calls.length).toBe(callsAfterFirst);

    const [first, second] = repo.messages;
    expect(second!.linkPreview!.title).toBe("Un bel article");
    const keys = repo.mediaRows.filter((m) => m.role === "preview").map((m) => m.storageKey);
    expect(new Set(keys).size).toBe(2);

    // unsending the first message deletes its file only
    const deleted = await repo.unsend(first!.id, clock);
    for (const row of deleted ?? []) await storage.remove(row.storageKey);
    const left = repo.mediaRows.filter((m) => m.role === "preview")[0]!;
    expect(await storage.read(left.storageKey)).not.toBeNull();
  });

  test("after 24 hours the page is fetched again", async () => {
    const fetcher = new FakeFetcher({ [PAGE]: htmlPage(OG_PAGE), "https://news.example/cover.png": imageBytes() });
    const service = serviceWith(fetcher);
    await service.run(await textMessage(PAGE));
    const before = fetcher.calls.filter((c) => c.kind === "html").length;
    clock = new Date(T0.getTime() + CACHE_TTL_MS + 1000);
    await service.run(await textMessage(PAGE));
    expect(fetcher.calls.filter((c) => c.kind === "html").length).toBe(before + 1);
  });

  test("a failure is cached too, so a bad link is not hammered", async () => {
    const fetcher = new FakeFetcher({ [PAGE]: { ok: false, reason: "status" } });
    const service = serviceWith(fetcher);
    await service.run(await textMessage(PAGE));
    await service.run(await textMessage(PAGE));
    expect(fetcher.calls).toHaveLength(1);
  });

  test("expired entries and their image files are purged; a refreshed entry does not leak the old file", async () => {
    const fetcher = new FakeFetcher({ [PAGE]: htmlPage(OG_PAGE), "https://news.example/cover.png": imageBytes() });
    const service = serviceWith(fetcher);
    await service.run(await textMessage(PAGE));
    const cacheFiles = () => [...storage.files.keys()].filter((key) => key.startsWith("chat/preview-cache/"));
    expect(cacheFiles()).toHaveLength(1);

    clock = new Date(T0.getTime() + CACHE_TTL_MS + 1000);
    await service.run(await textMessage(PAGE)); // refresh: the old cache file must go
    expect(cacheFiles()).toHaveLength(1);

    clock = new Date(clock.getTime() + CACHE_TTL_MS + 1000);
    expect(await service.purgeExpired()).toBe(1);
    expect(cacheFiles()).toHaveLength(0);
  });
});

describe("with the real guard in front (a hostile page)", () => {
  test("og:image pointing at the cloud metadata address is never requested", async () => {
    const requested: PinnedRequest[] = [];
    const transport: PinnedTransport = {
      async get(request) {
        requested.push(request);
        return { status: 200, headers: { "content-type": "text/html" }, truncated: false,
          body: new TextEncoder().encode(`<meta property="og:title" content="T"><meta property="og:image" content="http://169.254.169.254/latest/meta-data/">`) };
      },
    };
    const fetcher = createGuardedFetcher({ resolver: { resolveAll: async () => ["93.184.216.34"] }, transport });
    const service = createLinkPreviewService({
      fetcher, images, storage, cache, repository: repo, events, now: () => clock,
      presenter: createMessagePresenter({ repository: repo, signUrl: (id) => `u${id}`, receipts: allowAllReceipts }),
      runInBackground: (job) => { jobs.push(job); },
    });
    await service.run(await textMessage("https://evil.example/"));
    expect(requested.map((r) => r.address)).toEqual(["93.184.216.34"]); // the metadata address was not contacted
    expect(repo.messages[0]!.linkPreview).toMatchObject({ title: "T", imageMediaId: null });
  });

  test("a link whose name resolves to loopback gives no preview and no request", async () => {
    const transport: PinnedTransport = { get: async () => { throw new Error("must not be called"); } };
    const fetcher = createGuardedFetcher({ resolver: { resolveAll: async () => ["127.0.0.1"] }, transport });
    const service = createLinkPreviewService({
      fetcher, images, storage, cache, repository: repo, events, now: () => clock,
      presenter: createMessagePresenter({ repository: repo, signUrl: (id) => `u${id}`, receipts: allowAllReceipts }),
      runInBackground: (job) => { jobs.push(job); },
    });
    await service.run(await textMessage("http://looks-public.example/"));
    expect(repo.messages[0]!.linkPreview).toBeNull();
  });
});
