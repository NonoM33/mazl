import { createPhotoService, type PhotoService } from "./application/photo-service";
import { createLocationService, type LocationService } from "./application/location-service";
import { noopPhotoFaceChecker } from "./application/no-op-face-checker";
import { fuzzStoredLocations } from "./application/location-backfill";
import { sql } from "../../db";
import { createPostgresLocationBackfill } from "./infra/postgres-location-backfill";
import { createPhotoStorage } from "./infra/photo-storage";
import { googlePictureFetcher } from "./infra/google-picture-fetcher";
import { postgresLocationLog } from "./infra/postgres-location-log";
import { postgresPhotoRepository } from "./infra/postgres-photo-repository";
import { sharpImageProcessor } from "./infra/sharp-image-processor";
import type { ObjectStore } from "../../shared/storage/object-store";
import type { PhotoFaceChecker } from "../verification/application/ports";

// Composition root of the media feature.
export interface MediaModule {
  readonly photos: PhotoService;
  readonly location: LocationService;
}

export function createMediaModule(options: {
  store: ObjectStore;
  faceChecker?: PhotoFaceChecker;
}): MediaModule {
  const photos = createPhotoService({
    processor: sharpImageProcessor,
    storage: createPhotoStorage(options.store),
    repository: postgresPhotoRepository,
    fetcher: googlePictureFetcher,
    faceChecker: options.faceChecker ?? noopPhotoFaceChecker,
  });
  return { photos, location: createLocationService(postgresLocationLog) };
}

export { noopPhotoFaceChecker } from "./application/no-op-face-checker";
export { ensureMediaSchema } from "./infra/schema";

// Boot task, to run right after ensureMediaSchema(): fuzzes once every position
// stored before the socle. Idempotent. Returns the number of rows changed.
export function fuzzExistingLocations(): Promise<number> {
  return fuzzStoredLocations(createPostgresLocationBackfill(sql));
}
