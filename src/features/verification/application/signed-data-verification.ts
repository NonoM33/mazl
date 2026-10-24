import { ChipParseError, UnsupportedAlgorithmError } from "../domain/chip/errors";
import { HASH_OIDS } from "../domain/chip/oids";
import { resolveSignatureScheme } from "../domain/chip/crypto/signature-schemes";
import type { SignedData, SignerInfo } from "../domain/chip/cms";
import type { Certificate } from "../domain/chip/x509";
import type { ChipCrypto } from "./chip-crypto";

// CMS SignedData signature check shared by EF.SOD and ICAO master lists
// (RFC 5652 5.4, 5.6): the signer is one of the embedded certificates, the
// signed attributes bind the content type and the digest of eContent, and the
// signature covers their DER encoding re-tagged as SET.

export type SignedDataCheck =
  | { readonly ok: true; readonly signer: Certificate }
  | { readonly ok: false; readonly reason: "chip_data_invalid" | "chip_signature_invalid" };

export function sameBytes(a: Uint8Array, b: Uint8Array): boolean {
  return a.length === b.length && a.every((v, i) => v === b[i]);
}

function findSigner(signedData: SignedData, signer: SignerInfo): Certificate | undefined {
  return signedData.certificates.find((cert) => {
    const sid = signer.sid;
    if (sid.kind === "subjectKeyId") return cert.subjectKeyId !== undefined && sameBytes(cert.subjectKeyId, sid.keyId);
    return cert.issuer === sid.issuer && sameBytes(cert.serial, sid.serial);
  });
}

// Messages covered by the signature: the signed attributes (which must bind
// the content type and the digest of eContent), or eContent itself.
function signedMessage(signedData: SignedData, signer: SignerInfo, crypto: ChipCrypto): Uint8Array | undefined {
  if (signer.signedAttrsDer === undefined) return signedData.eContent;
  const hash = HASH_OIDS[signer.digestAlgorithm.oid];
  if (hash === undefined) throw new UnsupportedAlgorithmError("signer digest");
  if (signer.contentTypeAttr !== signedData.eContentType || signer.messageDigestAttr === undefined) return undefined;
  if (!sameBytes(signer.messageDigestAttr, crypto.digest(hash, signedData.eContent))) return undefined;
  return signer.signedAttrsDer;
}

// Throws ChipParseError for unusable algorithms or keys; callers map it.
export function verifySignedData(signedData: SignedData, crypto: ChipCrypto): SignedDataCheck {
  const [signer, ...others] = signedData.signerInfos;
  if (signer === undefined || others.length > 0) return { ok: false, reason: "chip_data_invalid" };
  const cert = findSigner(signedData, signer);
  if (cert === undefined) return { ok: false, reason: "chip_data_invalid" };
  const message = signedMessage(signedData, signer, crypto);
  if (message === undefined) return { ok: false, reason: "chip_signature_invalid" };
  const scheme = resolveSignatureScheme(signer.signatureAlgorithm, signer.digestAlgorithm);
  if (!crypto.verifySignature(scheme, cert.spki, message, signer.signature)) return { ok: false, reason: "chip_signature_invalid" };
  return { ok: true, signer: cert };
}


// Is `cert` signed by `issuer`'s key? An unusable issuer key (unsupported
// curve, bad point) counts as "no" so that another candidate can still match.
export function isIssuedBy(cert: Certificate, issuer: Certificate, crypto: ChipCrypto): boolean {
  try {
    const scheme = resolveSignatureScheme(cert.signatureAlgorithm);
    return crypto.verifySignature(scheme, issuer.spki, cert.tbs, cert.signature);
  } catch (e) {
    if (e instanceof ChipParseError) return false;
    throw e;
  }
}
