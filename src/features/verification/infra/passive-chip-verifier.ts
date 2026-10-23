import { authenticatePassively } from "../application/passive-authentication";
import type { ChipCrypto, TrustAnchors } from "../application/chip-crypto";
import type { ChipVerifier } from "../application/ports";
import { ChipParseError } from "../domain/chip/errors";
import type { ChipFiles, ChipVerification } from "../domain/types";
import { NodeChipCrypto } from "./node-chip-crypto";

// ChipVerifier port: ICAO 9303 passive authentication against a CSCA trust
// store. Never throws on hostile input; never logs chip content.
export class PassiveChipVerifier implements ChipVerifier {
  constructor(
    private readonly trust: TrustAnchors,
    private readonly crypto: ChipCrypto = new NodeChipCrypto(),
  ) {}

  async verify(files: ChipFiles, now: Date): Promise<ChipVerification> {
    try {
      return authenticatePassively(files, now, { crypto: this.crypto, trust: this.trust });
    } catch (e) {
      if (e instanceof ChipParseError) return { ok: false, reason: "chip_data_invalid" };
      // A bug, not hostile input: surface its class only, never its message.
      console.error("chip verification failed unexpectedly:", e instanceof Error ? e.name : "unknown");
      return { ok: false, reason: "chip_data_invalid" };
    }
  }
}
