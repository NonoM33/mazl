import type { HashName } from "../domain/chip/oids";
import type { SignatureScheme } from "../domain/chip/crypto/signature-schemes";
import type { Certificate, SubjectPublicKeyInfo } from "../domain/chip/x509";

// Ports used by passive authentication. Adapters live in ../infra.

export interface ChipCrypto {
  digest(hash: HashName, data: Uint8Array): Uint8Array;
  // false for a wrong signature; throws ChipParseError for a key or
  // parameter set that cannot be used (invalid point, unsupported curve...).
  verifySignature(scheme: SignatureScheme, key: SubjectPublicKeyInfo, message: Uint8Array, signature: Uint8Array): boolean;
}

export interface TrustAnchors {
  // CSCA certificates that could have issued a certificate with this
  // (canonical) issuer name and authority key identifier.
  candidatesFor(issuer: string, authorityKeyId: Uint8Array | undefined): readonly Certificate[];
}
