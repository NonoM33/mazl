import { createPhotoService, type PhotoService } from "./application/photo-service";
import { createLocationService, type LocationService } from "./application/location-service";
import { noopPhotoFaceChecker } from "./application/no-op-face-checker";
import { createDiskPhotoStorage } from "./infra/disk-photo-storage";
import { googlePictureFetcher } from "./infra/google-picture-fetcher";
import { postgresLocationLog } from "./infra/postgres-location-log";
import { postgresPhotoRepository } from "./infra/postgres-photo-repository";
import { sharpImageProcessor } from "./infra/sharp-image-processor";
import type { PhotoFaceChecker } from "../verification/application/ports";

// Composition root of the media feature.
export interface MediaModule {
  readonly photos: PhotoService;
  readonly location: LocationService;
}

export function createMediaModule(options: {
  uploadsDir: string;
  faceChecker?: PhotoFaceChecker;
}): MediaModule {
  const photos = createPhotoService({
    processor: sharpImageProcessor,
    storage: createDiskPhotoStorage(options.uploadsDir),
    repository: postgresPhotoRepository,
    fetcher: googlePictureFetcher,
    faceChecker: options.faceChecker ?? noopPhotoFaceChecker,
  });
  return { photos, location: createLocationService(postgresLocationLog) };
}

export { noopPhotoFaceChecker } from "./application/no-op-face-checker";
export { ensureMediaSchema } from "./infra/schema";
