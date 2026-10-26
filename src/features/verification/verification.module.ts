import type { Sql } from "postgres";
import type { Hono } from "hono";
import type { AppVariables } from "../../shared/http/middleware";
import type { ObjectStore } from "../../shared/storage/object-store";
import { PhotoFaceCheckerService } from "./application/photo-face-checker";
import type { ChipVerifier, FaceEngine, ImageDecoder, Jp2Decoder, PhotoFaceChecker } from "./application/ports";
import type { SubmitIdentityDeps } from "./application/submit-identity";
import { hmacHex } from "../../shared/crypto/signer";
import { LazyChipVerifier } from "./infra/lazy-chip-verifier";
import { OpjJp2Decoder } from "./infra/opj-jp2-decoder";
import { PgIdentityRepository } from "./infra/pg-identity-repository";
import { registerIdentityRoutes } from "./presentation/identity.routes";
import type { FaceThresholds } from "./domain/thresholds";
import { readFaceConfig } from "./infra/config";
import { createStorePhotoReader } from "./infra/store-photo-reader";
import { PgFaceReferenceStore } from "./infra/pg-face-reference-store";
import { PgFaceSessionRepository } from "./infra/pg-face-session-repository";
import { PgQuotaWaiver } from "./infra/pg-quota-waiver";
import { parseWaiverEnd } from "./domain/quota-waiver";
import { PgProfilePhotoStore, type PhotoFileReader } from "./infra/pg-profile-photo-store";
import { PgVerificationState } from "./infra/pg-verification-state";
import { gcmSecretVault } from "./infra/secret-vault";
import { sharedFaceEngine } from "./infra/shared-face-engine";
import { SharpImageDecoder } from "./infra/sharp-image-decoder";
import { registerVerificationRoutes, type VerificationRouteDeps } from "./presentation/verification.routes";

export interface VerificationModuleOptions {
  readonly sql: Sql;
  readonly store: ObjectStore;
  readonly env?: Record<string, string | undefined>;
  // Reads a profile photo from its storage key. Defaults to the object store.
  readonly readPhoto?: PhotoFileReader;
  // Replaceable engine and decoder, for tests of the HTTP layer.
  readonly engine?: FaceEngine;
  readonly decoder?: ImageDecoder;
  // Level 2: chip verification and JPEG 2000 decoding, replaceable in tests.
  readonly chip?: ChipVerifier;
  readonly jp2?: Jp2Decoder;
}

export interface VerificationModule {
  readonly routeDeps: VerificationRouteDeps;
  readonly photoFaceChecker: PhotoFaceChecker;
  readonly thresholds: FaceThresholds;
  readonly identityDeps: SubmitIdentityDeps;
}

export function createVerificationModule(options: VerificationModuleOptions): VerificationModule {
  const config = readFaceConfig(options.env ?? process.env);
  const engine = options.engine ?? sharedFaceEngine(config.modelsDir);
  const decoder = options.decoder ?? new SharpImageDecoder();
  const sessions = new PgFaceSessionRepository(options.sql);
  const references = new PgFaceReferenceStore(options.sql);
  const photos = new PgProfilePhotoStore(options.sql, options.readPhoto ?? createStorePhotoReader(options.store));
  const state = new PgVerificationState(options.sql);
  const vault = gcmSecretVault;
  const waiver = new PgQuotaWaiver(options.sql, parseWaiverEnd((options.env ?? process.env).ADMIN_VERIFICATION_UNLIMITED_UNTIL));

  const routeDeps: VerificationRouteDeps = {
    submit: { decoder, engine, sessions, references, photos, state, vault, thresholds: config.thresholds },
    session: { sessions, random: Math.random, waiver },
    status: { sessions, state, waiver },
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
  const identityDeps: SubmitIdentityDeps = {
    decoder,
    jp2: options.jp2 ?? new OpjJp2Decoder(),
    engine,
    chip: options.chip ?? new LazyChipVerifier(),
    sessions,
    identities: new PgIdentityRepository(options.sql),
    state,
    fingerprint: (message) => hmacHex("DOC_FINGERPRINT_KEY", message),
    thresholds: config.thresholds,
    now: () => new Date(),
  };
  return { routeDeps, photoFaceChecker, thresholds: config.thresholds, identityDeps };
}

// For the profile feature: compares photos added after verification with the
// user's face reference.
export function createPhotoFaceChecker(options: VerificationModuleOptions): PhotoFaceChecker {
  return createVerificationModule(options).photoFaceChecker;
}

export function registerVerification(app: Hono<{ Variables: AppVariables }>, module: VerificationModule): void {
  registerVerificationRoutes(app, module.routeDeps);
  registerIdentityRoutes(app, module.identityDeps);
}

export { registerVerificationRoutes } from "./presentation/verification.routes";
export { ensureVerificationSchema } from "./infra/schema";
export { verifyLiveFrames } from "./application/live-frames";
