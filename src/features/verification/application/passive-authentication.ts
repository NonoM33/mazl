import { parseDg1 } from "../domain/chip/dg1";
import { parseDg2 } from "../domain/chip/dg2";
import { parseSod, type SignedData, type SignerInfo } from "../domain/chip/cms";
import { ChipParseError, UnsupportedAlgorithmError } from "../domain/chip/errors";
import { parseLdsSecurityObject } from "../domain/chip/lds-security-object";
import { HASH_OIDS, OID } from "../domain/chip/oids";
import { resolveSignatureScheme } from "../domain/chip/crypto/signature-schemes";
import type { Certificate } from "../domain/chip/x509";
import type { ChipFiles, ChipVerification } from "../domain/types";
import type { ChipCrypto, TrustAnchors } from "./chip-crypto";

// ICAO Doc 9303 Part 11 passive authentication, steps in order:
//   1. EF.SOD is CMS SignedData of type id-icao-ldsSecurityObject
//   2. its signer (the DSC) is one of the embedded certificates
//   3. the signature over the signed attributes verifies with the DSC key
//   4. the DSC chains to a trusted, currently valid CSCA
//   5. DG1 / DG2 hash to the values signed in the LDSSecurityObject
// Only then are DG1 and DG2 parsed.
//
// Choices (documented deviations from a full 9303 path validation):
//  - Only the CSCA validity is compared with `now`. A DSC signs for months but
//    the documents it covers live ten years, so DSC validity is not checked.
//  - No CRL / revocation, no key-usage or basic-constraints checks.
//  - The DSC must be embedded in the SOD (optional in 9303, near-universal).

type Failure = Extract<ChipVerification, { ok: false }>;
const fail = (reason: Failure["reason"]): Failure => ({ ok: false, reason });

export interface PassiveAuthDeps {
  readonly crypto: ChipCrypto;
  readonly trust: TrustAnchors;
}

function sameBytes(a: Uint8Array, b: Uint8Array): boolean {
  return a.length === b.length && a.every((v, i) => v === b[i]);
}

function findSigner(signedData: SignedData, signer: SignerInfo): Certificate | undefined {
  return signedData.certificates.find((cert) => {
    const sid = signer.sid;
    if (sid.kind === "subjectKeyId") return cert.subjectKeyId !== undefined && sameBytes(cert.subjectKeyId, sid.keyId);
    return cert.issuer === sid.issuer && sameBytes(cert.serial, sid.serial);
  });
}

// Messages covered by the DSC signature: the signed attributes (which must
// bind the content type and the digest of eContent), or eContent itself.
type SignedMessage = { readonly ok: true; readonly message: Uint8Array } | { readonly ok: false };

function signedMessage(signedData: SignedData, signer: SignerInfo, deps: PassiveAuthDeps): SignedMessage {
  if (signer.signedAttrsDer === undefined) return { ok: true, message: signedData.eContent };
  const hash = HASH_OIDS[signer.digestAlgorithm.oid];
  if (hash === undefined) throw new UnsupportedAlgorithmError("signer digest");
  if (signer.contentTypeAttr !== signedData.eContentType || signer.messageDigestAttr === undefined) return { ok: false };
  if (!sameBytes(signer.messageDigestAttr, deps.crypto.digest(hash, signedData.eContent))) return { ok: false };
  return { ok: true, message: signer.signedAttrsDer };
}

function chainsToCsca(dsc: Certificate, now: Date, deps: PassiveAuthDeps): boolean {
  for (const csca of deps.trust.candidatesFor(dsc.issuer, dsc.authorityKeyId)) {
    if (now < csca.notBefore || now > csca.notAfter) continue;
    try {
      const scheme = resolveSignatureScheme(dsc.signatureAlgorithm);
      if (deps.crypto.verifySignature(scheme, csca.spki, dsc.tbs, dsc.signature)) return true;
    } catch (e) {
      // A trust-store key we cannot use must not hide another valid candidate.
      if (!(e instanceof ChipParseError)) throw e;
    }
  }
  return false;
}

function dataGroupsMatch(files: ChipFiles, signedData: SignedData, deps: PassiveAuthDeps): boolean {
  const lds = parseLdsSecurityObject(signedData.eContent);
  const expected: ReadonlyArray<readonly [number, Uint8Array]> = [
    [1, files.dg1],
    [2, files.dg2],
  ];
  return expected.every(([n, bytes]) => {
    const signed = lds.dataGroupHashes.get(n);
    return signed !== undefined && sameBytes(signed, deps.crypto.digest(lds.hashAlgorithm, bytes));
  });
}

export function authenticatePassively(files: ChipFiles, now: Date, deps: PassiveAuthDeps): ChipVerification {
  const signedData = parseSod(files.sod);
  if (signedData.eContentType !== OID.ldsSecurityObject) return fail("chip_data_invalid");
  const [signer, ...others] = signedData.signerInfos;
  if (signer === undefined || others.length > 0) return fail("chip_data_invalid");
  const dsc = findSigner(signedData, signer);
  if (dsc === undefined) return fail("chip_data_invalid");

  const covered = signedMessage(signedData, signer, deps);
  if (!covered.ok) return fail("chip_signature_invalid");
  const scheme = resolveSignatureScheme(signer.signatureAlgorithm, signer.digestAlgorithm);
  if (!deps.crypto.verifySignature(scheme, dsc.spki, covered.message, signer.signature)) return fail("chip_signature_invalid");

  if (!chainsToCsca(dsc, now, deps)) return fail("csca_unknown");
  if (!dataGroupsMatch(files, signedData, deps)) return fail("chip_data_invalid");

  const identity = parseDg1(files.dg1, now);
  const face = parseDg2(files.dg2);
  return { ok: true, identity, faceImage: face.bytes, faceImageFormat: face.format };
}
