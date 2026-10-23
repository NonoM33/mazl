import { randomUUID } from "node:crypto";
import { firstHttpUrl } from "../domain/url-extract";
import { parseOpenGraph } from "../domain/open-graph";
import type { MessageRecord } from "../domain/types";
import { updatedEvent } from "./chat-events";
import type { GuardedFetcher } from "./guarded-fetch";
import type { PreviewScheduler } from "./chat-service";
import type { MessagePresenter } from "./message-presenter";
import type {
  ChatImageProcessor, FileStorage, MessageRepository, NewMedia, PreviewCache, PreviewCacheData, RealtimeEvents,
} from "./ports";

// Link previews, CONTRAT.md §0.5. After a text message is stored, the first
// http(s) link is fetched in the background through the SSRF guard. The page's
// og:image is NOT hot-linked: it goes through the same guard, is re-encoded and
// stored like any chat photo, and leaves only through a signed URL.

export const PAGE_MAX_BYTES = 512 * 1024;
export const IMAGE_MAX_BYTES = 4 * 1024 * 1024;
export const FETCH_TIMEOUT_MS = 5000;
export const CACHE_TTL_MS = 24 * 60 * 60 * 1000;

export interface LinkPreviewDeps {
  readonly fetcher: GuardedFetcher;
  readonly images: ChatImageProcessor;
  readonly storage: FileStorage;
  readonly cache: PreviewCache;
  readonly repository: Pick<MessageRepository, "attachPreview" | "findConversationOf">;
  readonly presenter: MessagePresenter;
  readonly events: RealtimeEvents;
  readonly now: () => Date;
  // Where the job runs; production lets it float, tests capture and await it.
  readonly runInBackground: (job: Promise<void>) => void;
}

export interface LinkPreviewService extends PreviewScheduler {
  // Resolves when the preview for this message has been attempted (never rejects).
  run(message: MessageRecord): Promise<void>;
  // Drops cache entries older than 24 h together with their image files.
  purgeExpired(): Promise<number>;
}

function absoluteImageUrl(candidate: string | undefined, pageUrl: string): string | null {
  if (candidate === undefined) return null;
  try {
    return new URL(candidate, pageUrl).toString();
  } catch {
    return null;
  }
}

export function createLinkPreviewService(deps: LinkPreviewDeps): LinkPreviewService {
  const { fetcher, images, storage, cache, repository, presenter, events, now } = deps;

  async function downloadImage(imageUrl: string): Promise<{ key: string; width: number; height: number } | null> {
    const fetched = await fetcher.fetch(imageUrl, { kind: "image", maxBytes: IMAGE_MAX_BYTES, timeoutMs: FETCH_TIMEOUT_MS });
    if (!fetched.ok) return null;
    try {
      const processed = await images.toPreviewJpeg(fetched.body);
      const key = `chat/preview-cache/${randomUUID()}.jpg`;
      await storage.save(key, processed.bytes);
      return { key, width: processed.width, height: processed.height };
    } catch {
      return null;
    }
  }

  async function fetchPreview(url: string): Promise<PreviewCacheData | null> {
    const page = await fetcher.fetch(url, { kind: "html", maxBytes: PAGE_MAX_BYTES, timeoutMs: FETCH_TIMEOUT_MS });
    if (!page.ok) return null;
    const og = parseOpenGraph(new TextDecoder("utf-8").decode(page.body));
    const imageUrl = absoluteImageUrl(og.imageUrl, url);
    const image = imageUrl === null ? null : await downloadImage(imageUrl);
    if (og.title === undefined && og.description === undefined && image === null) return null;
    return {
      title: og.title ?? null,
      description: og.description ?? null,
      siteName: og.siteName ?? null,
      imageKey: image?.key ?? null,
      imageWidth: image?.width ?? null,
      imageHeight: image?.height ?? null,
    };
  }

  // Cached for 24 h per URL, failures included.
  async function previewFor(url: string): Promise<PreviewCacheData | null> {
    const cached = await cache.get(url, new Date(now().getTime() - CACHE_TTL_MS));
    if (cached.found) return cached.data;
    const fresh = await fetchPreview(url);
    const replacedKey = await cache.put(url, fresh, now());
    if (replacedKey !== null) await storage.remove(replacedKey);
    return fresh;
  }

  // Each message owns a copy of the image, so that unsending it deletes only its own file.
  async function imageCopyFor(message: MessageRecord, data: PreviewCacheData): Promise<{ media: NewMedia; key: string } | null> {
    if (data.imageKey === null) return null;
    const bytes = await storage.read(data.imageKey);
    if (bytes === null) return null;
    const key = `chat/${message.conversationId}/${randomUUID()}.jpg`;
    await storage.save(key, bytes);
    return {
      key,
      media: {
        conversationId: message.conversationId, uploaderId: message.senderId, kind: "photo", storageKey: key,
        width: data.imageWidth, height: data.imageHeight, durationMs: null, waveform: null, role: "preview",
      },
    };
  }

  async function run(message: MessageRecord): Promise<void> {
    try {
      const url = firstHttpUrl(message.content);
      if (url === null) return;
      const data = await previewFor(url);
      if (data === null) return;
      const copy = await imageCopyFor(message, data);
      const updated = await repository.attachPreview({
        messageId: message.id,
        preview: { url, title: data.title, description: data.description, siteName: data.siteName },
        image: copy?.media ?? null,
      });
      if (updated === null) {
        // Unsent in the meantime: the copy has no owner.
        if (copy !== null) await storage.remove(copy.key);
        return;
      }
      const conversation = await repository.findConversationOf(message.conversationId, message.senderId);
      if (conversation === null) return;
      const [view] = await presenter.present([updated]);
      if (view !== undefined) events.emit([conversation.user1Id, conversation.user2Id], updatedEvent(view));
    } catch (error: unknown) {
      // Never the URL or the text: only the kind of failure.
      console.error("Link preview failed:", error instanceof Error ? error.name : "unknown");
    }
  }

  async function purgeExpired(): Promise<number> {
    const keys = await cache.deleteExpired(new Date(now().getTime() - CACHE_TTL_MS));
    for (const key of keys) {
      try {
        await storage.remove(key);
      } catch (error: unknown) {
        console.error("Preview cache removal failed:", error instanceof Error ? error.name : "unknown");
      }
    }
    return keys.length;
  }

  return { schedule: (message) => deps.runInBackground(run(message)), run, purgeExpired };
}
