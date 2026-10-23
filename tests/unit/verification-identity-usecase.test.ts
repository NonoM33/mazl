import { beforeEach, describe, expect, test } from "bun:test";
import type { ChipVerifier, Jp2Decoder, RgbImage } from "../../src/features/verification/application/ports";
import { startFaceSession } from "../../src/features/verification/application/start-session";
import {
  submitIdentityVerification,
  type SubmitIdentityDeps,
} from "../../src/features/verification/application/submit-identity";
import type { Challenge, ChipFiles, ChipIdentity, ChipVerification } from "../../src/features/verification/domain/types";
import {
  FakeFaceEngine,
  FakeImageDecoder,
  FakeSessionRepository,
  FakeStateRepository,
  PERSON_A,
  PERSON_A_TURNED,
  PERSON_B,
  imageOf,
  sceneFace,
  type SceneFace,
} from "./support/face-fakes";
import { FakeIdentityRepository } from "./support/identity-fakes";

// Expectations come from CONTRAT.md §4, not from the implementation.
const USER = 7;
const OTHER_USER = 8;
const NOW = new Date("2026-10-23T12:00:00Z");

const FRONT = 40;
const TURNED_A = 90;
const TURNED_B = 140;
const FINAL_FRONT = 190;
const BLANK = 10;
const DOC_SAME_PERSON = 200;
const DOC_OTHER_PERSON = 210;
const DOC_NO_FACE = 220;

const CHIP: ChipFiles = { dg1: Uint8Array.of(1), dg2: Uint8Array.of(2), sod: Uint8Array.of(3) };

const ADULT: ChipIdentity = {
  documentType: "P",
  issuingState: "FRA",
  documentNumber: "12AB34567",
  birthDate: "1990-05-17",
  expiryDate: "2031-02-01",
  sex: "F",
};

function scenes(): Map<number, readonly SceneFace[]> {
  return new Map<number, readonly SceneFace[]>([
    [FRONT, [sceneFace(PERSON_A, 0.02)]],
    [TURNED_A, [sceneFace(PERSON_A_TURNED, 0.35)]],
    [TURNED_B, [sceneFace(PERSON_A_TURNED, -0.35)]],
    [FINAL_FRONT, [sceneFace(PERSON_A, -0.03)]],
    [BLANK, []],
    [DOC_SAME_PERSON, [sceneFace(PERSON_A, 0.01)]],
    [DOC_OTHER_PERSON, [sceneFace(PERSON_B, 0.01)]],
    [DOC_NO_FACE, []],
  ]);
}

class FakeChipVerifier implements ChipVerifier {
  calls = 0;
  constructor(public result: ChipVerification) {}
  async verify(): Promise<ChipVerification> {
    this.calls += 1;
    return this.result;
  }
}

const chipOk = (identity: ChipIdentity, faceLevel = DOC_SAME_PERSON, format: "jpeg" | "jp2" = "jpeg"): ChipVerification => ({
  ok: true,
  identity,
  faceImage: imageOf(faceLevel),
  faceImageFormat: format,
});

class FakeJp2Decoder implements Jp2Decoder {
  calls = 0;
  async decode(bytes: Uint8Array): Promise<RgbImage> {
    this.calls += 1;
    return new FakeImageDecoder().decode(bytes);
  }
}

let sessions: FakeSessionRepository;
let chip: FakeChipVerifier;
let jp2: FakeJp2Decoder;
let identities: FakeIdentityRepository;
let state: FakeStateRepository;
let fingerprintedMessages: string[];
let deps: SubmitIdentityDeps;

beforeEach(() => {
  sessions = new FakeSessionRepository();
  chip = new FakeChipVerifier(chipOk(ADULT));
  jp2 = new FakeJp2Decoder();
  identities = new FakeIdentityRepository();
  state = new FakeStateRepository();
  fingerprintedMessages = [];
  deps = {
    decoder: new FakeImageDecoder(),
    jp2,
    engine: new FakeFaceEngine(scenes()),
    chip,
    sessions,
    identities,
    state,
    fingerprint: (message) => {
      fingerprintedMessages.push(message);
      return `fp(${message})`;
    },
    thresholds: { match: 0.363, consistency: 0.363 },
    now: () => NOW,
  };
});

function liveFrames(challenges: readonly Challenge[]): Uint8Array[] {
  const levels: number[] = [FRONT];
  for (const c of challenges.slice(1)) {
    if (c === "front") levels.push(FINAL_FRONT);
    else levels.push(levels.includes(TURNED_A) ? TURNED_B : TURNED_A);
  }
  return levels.map(imageOf);
}

async function submit(userId = USER, frames?: (c: readonly Challenge[]) => Uint8Array[]) {
  const started = await startFaceSession({ sessions, random: Math.random }, userId, "identity");
  if (!started.ok) throw new Error("session refused");
  const result = await submitIdentityVerification(deps, {
    userId,
    sessionId: started.sessionId,
    frames: (frames ?? liveFrames)(started.challenges),
    chip: CHIP,
  });
  return { result, sessionId: started.sessionId };
}

describe("submitIdentityVerification: success", () => {
  test("verifies, stores only the result and refreshes the badge", async () => {
    const { result } = await submit();
    expect(result).toEqual({ verified: true });
    expect(identities.saved).toHaveLength(1);
    const record = identities.saved[0];
    expect(record).toEqual({
      userId: USER,
      method: "nfc_passive_auth",
      issuingState: "FRA",
      documentType: "P",
      fingerprint: "fp(FRA|12AB34567|1990-05-17)",
      documentExpiry: "2031-02-01",
      birthDate: "1990-05-17",
    });
    // Neither the document number nor a name is kept in clear.
    expect(JSON.stringify(record)).not.toContain('"12AB34567"');
    expect(state.refreshed).toContain(USER);
  });

  test("the fingerprint message is '<state>|<number>|<birth date>' (CONTRAT §4.4)", async () => {
    await submit();
    expect(fingerprintedMessages).toEqual(["FRA|12AB34567|1990-05-17"]);
  });

  test("a JPEG 2000 chip photo goes through the JP2 decoder", async () => {
    chip.result = chipOk(ADULT, DOC_SAME_PERSON, "jp2");
    const { result } = await submit();
    expect(result).toEqual({ verified: true });
    expect(jp2.calls).toBe(1);
  });

  test("the 18th birthday itself is accepted", async () => {
    chip.result = chipOk({ ...ADULT, birthDate: "2008-10-23" });
    expect((await submit()).result).toEqual({ verified: true });
  });

  test("a member re-verifying with their own document is accepted", async () => {
    identities.owners.set("fp(FRA|12AB34567|1990-05-17)", USER);
    expect((await submit()).result).toEqual({ verified: true });
  });
});

describe("submitIdentityVerification: refusals", () => {
  test("the session is single use", async () => {
    const started = await startFaceSession({ sessions, random: Math.random }, USER, "identity");
    if (!started.ok) throw new Error("session refused");
    const input = { userId: USER, sessionId: started.sessionId, frames: liveFrames(started.challenges), chip: CHIP };
    await submitIdentityVerification(deps, input);
    expect(await submitIdentityVerification(deps, input)).toEqual({ verified: false, reason: "session_used" });
  });

  test("a photo session cannot be used for identity", async () => {
    const started = await startFaceSession({ sessions, random: Math.random }, USER, "photo");
    if (!started.ok) throw new Error("session refused");
    const result = await submitIdentityVerification(deps, {
      userId: USER,
      sessionId: started.sessionId,
      frames: liveFrames(started.challenges),
      chip: CHIP,
    });
    expect(result).toEqual({ verified: false, reason: "session_not_found" });
  });

  test("a failed liveness stops before the chip is even read", async () => {
    const { result } = await submit(USER, (c) => c.map(() => imageOf(BLANK)));
    expect(result).toEqual({ verified: false, reason: "no_face" });
    expect(chip.calls).toBe(0);
  });

  test.each([["chip_data_invalid"], ["chip_signature_invalid"], ["csca_unknown"]] as const)(
    "a chip refusal (%s) is returned as is",
    async (reason) => {
      chip.result = { ok: false, reason };
      expect((await submit()).result).toEqual({ verified: false, reason });
      expect(identities.saved).toHaveLength(0);
    },
  );

  test("an expired document is refused", async () => {
    chip.result = chipOk({ ...ADULT, expiryDate: "2026-10-22" });
    expect((await submit()).result).toEqual({ verified: false, reason: "document_expired" });
  });

  test("a holder one day short of 18 is refused", async () => {
    chip.result = chipOk({ ...ADULT, birthDate: "2008-10-24" });
    expect((await submit()).result).toEqual({ verified: false, reason: "underage" });
  });

  test("a chip photo of someone else is refused BEFORE the registry is consulted", async () => {
    chip.result = chipOk(ADULT, DOC_OTHER_PERSON);
    identities.owners.set("fp(FRA|12AB34567|1990-05-17)", OTHER_USER);
    expect((await submit()).result).toEqual({ verified: false, reason: "document_face_mismatch" });
    expect(identities.lookups).toBe(0);
  });

  test("a chip photo without a face is a mismatch, never a pass", async () => {
    chip.result = chipOk(ADULT, DOC_NO_FACE);
    expect((await submit()).result).toEqual({ verified: false, reason: "document_face_mismatch" });
  });

  test("a banned document is refused", async () => {
    identities.banned.add("fp(FRA|12AB34567|1990-05-17)");
    expect((await submit()).result).toEqual({ verified: false, reason: "document_banned" });
    expect(identities.saved).toHaveLength(0);
  });

  test("a document already used by another account is refused", async () => {
    identities.owners.set("fp(FRA|12AB34567|1990-05-17)", OTHER_USER);
    expect((await submit()).result).toEqual({ verified: false, reason: "document_already_used" });
  });

  test("losing a concurrent race on the same document is refused", async () => {
    identities.raceLost = true;
    expect((await submit()).result).toEqual({ verified: false, reason: "document_already_used" });
    expect(state.refreshed).not.toContain(USER);
  });

  test("the session records the outcome code", async () => {
    chip.result = chipOk({ ...ADULT, expiryDate: "2020-01-01" });
    const { sessionId } = await submit();
    expect(sessions.sessions.get(sessionId)?.outcome).toBe("document_expired");
  });
});
