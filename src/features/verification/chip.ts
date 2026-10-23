// Public surface of the chip (level 2) library. Wiring example:
//
//   const trust = await CscaTrustStore.fromEnv();           // CSCA_BUNDLE_PATH
//   const chipVerifier: ChipVerifier = new PassiveChipVerifier(trust);
//   const jp2: Jp2Decoder = new OpjJp2Decoder();            // OPJ_DECOMPRESS
//
// The use case, not this library, checks expiry, age and the document
// fingerprint (helpers below).
export { PassiveChipVerifier } from "./infra/passive-chip-verifier";
export { CscaTrustStore, TrustStoreError, DEFAULT_CSCA_BUNDLE_PATH } from "./infra/csca-trust-store";
export { OpjJp2Decoder } from "./infra/opj-jp2-decoder";
export { ageOn, documentFingerprintMessage, isExpired } from "./domain/chip/identity-helpers";
export { ChipParseError, TlvError } from "./domain/chip/errors";
