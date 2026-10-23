import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import sharp from "sharp";
import { startFaceSession } from "../../src/features/verification/application/start-session";
import {
  submitIdentityVerification,
  type SubmitIdentityDeps,
} from "../../src/features/verification/application/submit-identity";
import type { Challenge, ChipFiles } from "../../src/features/verification/domain/types";
import { OpjJp2Decoder } from "../../src/features/verification/infra/opj-jp2-decoder";
import { PassiveChipVerifier } from "../../src/features/verification/infra/passive-chip-verifier";
import { sharedFaceEngine } from "../../src/features/verification/infra/shared-face-engine";
import { SharpImageDecoder } from "../../src/features/verification/infra/sharp-image-decoder";
import { loadFiles, loadTrust, NOW, TEST_STATES } from "./chip-fixtures";
import { FakeSessionRepository, FakeStateRepository } from "./support/face-fakes";
import { FakeIdentityRepository } from "./support/identity-fakes";

// Level 2 end to end with every real component except storage: OpenSSL-signed
// chip files (fictitious state UTO) whose DG2 holds a real public-domain
// portrait, the real passive authentication, the real ONNX face models, and
// live frames of the same person from other photographs.
const FACES = join(import.meta.dir, "..", "fixtures", "faces");
const face = (name: string): Uint8Array => new Uint8Array(readFileSync(join(FACES, name)));
const mirrored = async (name: string): Promise<Uint8Array> =>
  new Uint8Array(await sharp(face(name)).flop().jpeg({ quality: 90 }).toBuffer());

async function liveFrames(challenges: readonly Challenge[], front: string): Promise<Uint8Array[]> {
  const sides = [face("ride-profile-sts7-1983.jpg"), await mirrored("ride-profile-sts7-1983.jpg")];
  const out = [face(front)];
  // A 4-step session ends on a second front: another photo, or the
  // duplicate-frame rule rightly refuses it.
  for (const c of challenges.slice(1)) out.push(c === "front" ? face("ride-portrait-1984.jpg") : (sides.shift() as Uint8Array));
  return out;
}

function deps(identities = new FakeIdentityRepository()): SubmitIdentityDeps & { sessions: FakeSessionRepository } {
  return {
    decoder: new SharpImageDecoder(),
    jp2: new OpjJp2Decoder(),
    engine: sharedFaceEngine(process.env.FACE_MODELS_DIR ?? "models"),
    chip: new PassiveChipVerifier(loadTrust("rsa-pkcs1-face"), undefined, TEST_STATES),
    sessions: new FakeSessionRepository(),
    identities,
    state: new FakeStateRepository(),
    fingerprint: (message) => `fp(${message})`,
    thresholds: { match: 0.363, consistency: 0.363 },
    now: () => NOW,
  };
}

async function run(d: ReturnType<typeof deps>, chip: ChipFiles, front: string) {
  const started = await startFaceSession({ sessions: d.sessions, random: Math.random }, 7, "identity");
  if (!started.ok) throw new Error("session refused");
  return submitIdentityVerification(d, {
    userId: 7,
    sessionId: started.sessionId,
    frames: await liveFrames(started.challenges, front),
    chip,
  });
}

describe("identity verification end to end", () => {
  test("a live selfie of the chip's holder verifies, with the document's birth date", async () => {
    const identities = new FakeIdentityRepository();
    const result = await run(deps(identities), loadFiles("rsa-pkcs1-face"), "ride-flight-deck-1983.jpg");
    expect(result).toEqual({ verified: true });
    // ICAO 9303 Part 4 sample holder: born 1974-08-12, document L898902C3 of UTO.
    expect(identities.saved[0]?.birthDate).toBe("1974-08-12");
    expect(identities.saved[0]?.fingerprint).toBe("fp(UTO|L898902C3|1974-08-12)");
  });

  test("another person in front of the camera is refused", async () => {
    const result = await run(deps(), loadFiles("rsa-pkcs1-face"), "glenn-senate-portrait.jpg");
    expect(result.verified).toBe(false);
  });

  test("a chip photo swapped after signing is refused by passive authentication", async () => {
    const genuine = loadFiles("rsa-pkcs1-face");
    const other = loadFiles("rsa-pkcs1");
    const result = await run(deps(), { ...genuine, dg2: other.dg2 }, "ride-flight-deck-1983.jpg");
    expect(result).toEqual({ verified: false, reason: "chip_data_invalid" });
  });
});
