import type { ChipVerifier } from "../application/ports";
import type { ChipFiles, ChipVerification } from "../domain/types";
import { CscaTrustStore } from "./csca-trust-store";
import { PassiveChipVerifier } from "./passive-chip-verifier";

// Loads the CSCA bundle on first use (CSCA_BUNDLE_PATH), so the module can be
// built synchronously at boot. A missing or unreadable bundle is a deployment
// fault: it is rethrown on every call (HTTP 500), never turned into a refusal.
export class LazyChipVerifier implements ChipVerifier {
  private verifier: Promise<ChipVerifier> | null = null;

  constructor(private readonly load: () => Promise<ChipVerifier> = defaultLoad) {}

  async verify(files: ChipFiles, now: Date): Promise<ChipVerification> {
    this.verifier ??= this.load().catch((error: unknown) => {
      this.verifier = null;
      throw error;
    });
    return (await this.verifier).verify(files, now);
  }
}

async function defaultLoad(): Promise<ChipVerifier> {
  return new PassiveChipVerifier(await CscaTrustStore.fromEnv());
}
