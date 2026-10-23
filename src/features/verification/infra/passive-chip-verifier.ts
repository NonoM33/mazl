import { authenticatePassively } from "../application/passive-authentication";
import type { ChipCrypto, TrustAnchors } from "../application/chip-crypto";
import type { ChipVerifier } from "../application/ports";
import { ICAO_STATES, type IssuingStateRegistry } from "../domain/chip/icao-states";
import { ChipParseError } from "../domain/chip/errors";
import type { ChipFiles, ChipVerification } from "../domain/types";
import { NodeChipCrypto } from "./node-chip-crypto";

// Generous upper bounds for real chips (SOD ~2-5 KB, DG1 93 B, DG2 15-150 KB).
const MAX_SOD_BYTES = 64 * 1024;
const MAX_DG1_BYTES = 1024;
const MAX_DG2_BYTES = 2 * 1024 * 1024;

// ChipVerifier port: ICAO 9303 passive authentication against a CSCA trust
// store. Never throws on hostile input; never logs chip content.
export class PassiveChipVerifier implements ChipVerifier {
  constructor(
    private readonly trust: TrustAnchors,
    private readonly crypto: ChipCrypto = new NodeChipCrypto(),
    private readonly states: IssuingStateRegistry = ICAO_STATES,
  ) {}

  async verify(files: ChipFiles, now: Date): Promise<ChipVerification> {
    if (files.sod.length > MAX_SOD_BYTES || files.dg1.length > MAX_DG1_BYTES || files.dg2.length > MAX_DG2_BYTES) {
      return { ok: false, reason: "chip_data_invalid" };
    }
    try {
      return authenticatePassively(files, now, { crypto: this.crypto, trust: this.trust, states: this.states });
    } catch (e) {
      if (e instanceof ChipParseError) return { ok: false, reason: "chip_data_invalid" };
      // A bug, not hostile input: surface its class only, never its message.
      console.error("chip verification failed unexpectedly:", e instanceof Error ? e.name : "unknown");
      return { ok: false, reason: "chip_data_invalid" };
    }
  }
}
