import type { Sql } from "postgres";
import type { Hono } from "hono";
import type { AppVariables } from "../../shared/http/middleware";
import { PhotoFaceCheckerService } from "./application/photo-face-checker";
import type { FaceEngine, ImageDecoder, PhotoFaceChecker } from "./application/ports";
import type { FaceThresholds } from "./domain/thresholds";
import { readFaceConfig } from "./infra/config";
import { createLocalPhotoReader } from "./infra/local-photo-reader";
import { PgFaceReferenceStore } from "./infra/pg-face-reference-store";
import { PgFaceSessionRepository } from "./infra/pg-face-session-repository";
import { PgProfilePhotoStore, type PhotoFileReader } from "./infra/pg-profile-photo-store";
import { PgVerificationState } from "./infra/pg-verification-state";
import { gcmSecretVault } from "./infra/secret-vault";
import { sharedFaceEngine } from "./infra/shared-face-engine";
import { SharpImageDecoder } from "./infra/sharp-image-decoder";
import { registerVerificationRoutes, type VerificationRouteDeps } from "./presentation/verification.routes";

export interface VerificationModuleOptions {
  readonly sql: Sql;
  readonly uploadsDir: string;
  readonly env?: Record<string, string | undefined>;
  // Reads a profile photo from its storage key. Defaults to files under uploadsDir.
  readonly readPhoto?: PhotoFileReader;
  // Replaceable engine and decoder, for tests of the HTTP layer.
  readonly engine?: FaceEngine;
  readonly decoder?: ImageDecoder;
}

export interface VerificationModule {
  readonly routeDeps: VerificationRouteDeps;
  readonly photoFaceChecker: PhotoFaceChecker;
  readonly thresholds: FaceThresholds;
}

export function createVerificationModule(options: VerificationModuleOptions): VerificationModule {
  const config = readFaceConfig(options.env ?? process.env);
  const engine = options.engine ?? sharedFaceEngine(config.modelsDir);
  const decoder = options.decoder ?? new SharpImageDecoder();
  const sessions = new PgFaceSessionRepository(options.sql);
  const references = new PgFaceReferenceStore(options.sql);
  const photos = new PgProfilePhotoStore(options.sql, options.readPhoto ?? createLocalPhotoReader(options.uploadsDir));
  const state = new PgVerificationState(options.sql);
  const vault = gcmSecretVault;

  const routeDeps: VerificationRouteDeps = {
    submit: { decoder, engine, sessions, references, photos, state, vault, thresholds: config.thresholds },
    session: { sessions, random: Math.random },
    status: { sessions, state },
    reference: { references, photos, state },
  };
  const photoFaceChecker = new PhotoFaceCheckerService({
    decoder,
    engine,
    references,
    photos,
    state,
    vault,
    matchThreshold: config.thresholds.match,
  });
  return { routeDeps, photoFaceChecker, thresholds: config.thresholds };
}

// For the profile feature: compares photos added after verification with the
// user's face reference.
export function createPhotoFaceChecker(options: VerificationModuleOptions): PhotoFaceChecker {
  return createVerificationModule(options).photoFaceChecker;
}

export function registerVerification(app: Hono<{ Variables: AppVariables }>, module: VerificationModule): void {
  registerVerificationRoutes(app, module.routeDeps);
}

export { registerVerificationRoutes } from "./presentation/verification.routes";
export { ensureVerificationSchema } from "./infra/schema";
export { verifyLiveFrames } from "./application/live-frames";
