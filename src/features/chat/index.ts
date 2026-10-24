import type { Hono } from "hono";
import type { AppVariables } from "../../shared/http/middleware";
import { createChatLimits, type ChatLimits } from "./application/chat-limits";
import { limitImageProcessing } from "./application/limited-images";
import { createSemaphore } from "./application/semaphore";
import { createChatMediaService, type ChatMediaService } from "./application/chat-media-service";
import { createChatService, type ChatService } from "./application/chat-service";
import { createGuardedFetcher } from "./application/guarded-fetch";
import { createLinkPreviewService, type LinkPreviewService } from "./application/link-preview-service";
import { createMessagePresenter } from "./application/message-presenter";
import { signChatMediaUrl } from "./application/media-signer";
import { createPinnedHttpTransport } from "./infra/pinned-http-transport";
import { createChatDiskStorage } from "./infra/disk-chat-storage";
import { postgresMediaRepository } from "./infra/postgres-media-repository";
import { postgresMessageRepository } from "./infra/postgres-message-repository";
import { postgresPreviewCache } from "./infra/postgres-preview-cache";
import { websocketEvents } from "./infra/realtime-events";
import { sharpChatImages } from "./infra/sharp-chat-images";
import { systemDnsResolver } from "./infra/system-dns-resolver";
import { registerChatRoutes } from "./presentation/chat.routes";
import { registerChatMediaRoutes } from "./presentation/media.routes";
import { registerMessageRoutes } from "./presentation/message.routes";
import { createChatSocketHandlers, type ChatSocketHandlers } from "./presentation/socket-handlers";
import { startPeriodically } from "./application/maintenance";

// Composition root of the chat feature (CONTRAT.md, docs/chat).
export interface ChatModule {
  readonly chat: ChatService;
  readonly media: ChatMediaService;
  readonly previews: LinkPreviewService;
  readonly sockets: ChatSocketHandlers;
  readonly limits: ChatLimits;
}

// Image decoding for the whole chat (photos and preview images): 3 at a time,
// 24 waiting, the rest told to retry.
const IMAGE_CONCURRENCY = 3;
const IMAGE_QUEUE = 24;

export function createChatModule(options: { uploadsDir: string }): ChatModule {
  const storage = createChatDiskStorage(options.uploadsDir);
  const now = (): Date => new Date();
  const presenter = createMessagePresenter({ repository: postgresMessageRepository, signUrl: (id) => signChatMediaUrl(id) });
  const limits = createChatLimits();
  const images = limitImageProcessing(sharpChatImages, createSemaphore({ permits: IMAGE_CONCURRENCY, maxQueue: IMAGE_QUEUE }));

  const previews = createLinkPreviewService({
    fetcher: createGuardedFetcher({ resolver: systemDnsResolver, transport: createPinnedHttpTransport() }),
    images,
    storage,
    cache: postgresPreviewCache,
    repository: postgresMessageRepository,
    presenter,
    events: websocketEvents,
    now,
    runInBackground: (job) => {
      void job.catch(() => undefined);
    },
  });

  const chat = createChatService({
    repository: postgresMessageRepository, presenter, events: websocketEvents, storage, previews, now,
  });
  const media = createChatMediaService({
    messages: postgresMessageRepository, media: postgresMediaRepository, storage, images, now,
  });
  return { chat, media, previews, sockets: createChatSocketHandlers(chat, limits), limits };
}

export function registerChat(app: Hono<{ Variables: AppVariables }>, module: ChatModule): void {
  registerChatRoutes(app, module.chat, module.limits);
  registerMessageRoutes(app, module.chat, module.limits);
  registerChatMediaRoutes(app, module.media);
}

const MAINTENANCE_INTERVAL_MS = 6 * 60 * 60 * 1000;

// Orphan uploads (older than 24 h and never sent), expired preview cache entries
// and files that no row owns any more (older than 1 h) are removed at boot and
// every six hours.
export function startChatMaintenance(module: ChatModule): () => void {
  return startPeriodically(
    async () => {
      const orphans = await module.media.purgeOrphans();
      const expired = await module.previews.purgeExpired();
      const strays = await module.media.sweepStrayFiles();
      if (orphans + expired + strays > 0) {
        console.log(`Chat maintenance: ${orphans} orphan uploads, ${expired} preview cache entries, ${strays} stray files removed`);
      }
    },
    MAINTENANCE_INTERVAL_MS,
  );
}

export { ensureChatSchema } from "./infra/schema";
