import { createHash } from "node:crypto";
import { TAG } from "../domain/chip/asn1";
import { parseCmsSignedData } from "../domain/chip/cms";
import { ChipParseError } from "../domain/chip/errors";
import { children, expectTag, parseTlv, raw } from "../domain/chip/tlv";
import { parseCertificate, type Certificate } from "../domain/chip/x509";
import type { ChipCrypto } from "../application/chip-crypto";
import { isIssuedBy, verifySignedData } from "../application/signed-data-verification";
import { CscaTrustStore } from "./csca-trust-store";

// ICAO PKD master list (Doc 9303 Part 12, 8): CMS SignedData of type
// 2.23.136.1.1.2 whose content is CscaMasterList ::= SEQUENCE { version,
// certList SET OF Certificate }. Published by several states; we use the
// German BSI one (see scripts/update-csca.ts).

export const MASTER_LIST_CONTENT_TYPE = "2.23.136.1.1.2";

export class MasterListError extends Error {
  constructor(reason: string) {
    super(reason);
    this.name = "MasterListError";
  }
}

export interface MasterList {
  readonly certificates: readonly Certificate[]; // unique by DER
  readonly unreadable: number;
  readonly signerSubject: string;
  readonly rootSha256: string; // self-signed CSCA vouching for the list signer
  readonly pinned: boolean; // was the root checked against an out-of-band fingerprint?
}

export interface MasterListOptions {
  readonly now: Date;
  // Accepted SHA-256 fingerprints (hex) of the issuing root CSCA, obtained
  // out of band. Empty or absent: trust on first use.
  readonly pinnedRoots?: readonly string[];
}

const sha256Hex = (der: Uint8Array): string => createHash("sha256").update(der).digest("hex");

function extractCertificates(content: Uint8Array): { certs: Certificate[]; unreadable: number } {
  const root = expectTag(parseTlv(content, true), TAG.sequence, "CscaMasterList");
  const [version, list] = children(root);
  expectTag(version, TAG.integer, "version");
  const seen = new Set<string>();
  const certs: Certificate[] = [];
  let unreadable = 0;
  for (const entry of children(expectTag(list, TAG.set, "certList"))) {
    const der = raw(entry);
    const key = sha256Hex(der);
    if (seen.has(key)) continue;
    seen.add(key);
    try {
      certs.push(parseCertificate(der, true));
    } catch (e) {
      if (!(e instanceof ChipParseError)) throw e;
      unreadable++;
    }
  }
  return { certs, unreadable };
}

// Follows issuers from the list signer up to a self-signed CSCA of the list.
function findRoot(signer: Certificate, store: CscaTrustStore, crypto: ChipCrypto, now: Date): Certificate {
  let current = signer;
  for (let depth = 0; depth < 4; depth++) {
    const issuer = store
      .candidatesFor(current.issuer, current.authorityKeyId)
      .find((c) => now >= c.notBefore && now <= c.notAfter && isIssuedBy(current, c, crypto));
    if (issuer === undefined) throw new MasterListError("list signer does not chain to a CSCA of the list");
    if (issuer.subject === issuer.issuer && isIssuedBy(issuer, issuer, crypto)) return issuer;
    current = issuer;
  }
  throw new MasterListError("chain to the root is too long");
}

export function readMasterList(der: Uint8Array, crypto: ChipCrypto, options: MasterListOptions): MasterList {
  const signed = parseCmsSignedData(der, true);
  if (signed.eContentType !== MASTER_LIST_CONTENT_TYPE) throw new MasterListError("not a CSCA master list");
  const check = verifySignedData(signed, crypto);
  if (!check.ok) throw new MasterListError(`master list signature check failed: ${check.reason}`);
  if (options.now < check.signer.notBefore || options.now > check.signer.notAfter) throw new MasterListError("list signer certificate is not valid today");
  const { certs, unreadable } = extractCertificates(signed.eContent);
  const root = findRoot(check.signer, new CscaTrustStore(certs), crypto, options.now);
  const rootSha256 = sha256Hex(root.der);
  const pins = (options.pinnedRoots ?? []).map((p) => p.toLowerCase());
  if (pins.length > 0 && !pins.includes(rootSha256)) throw new MasterListError("issuing CSCA does not match a pinned fingerprint");
  return { certificates: certs, unreadable, signerSubject: check.signer.subject, rootSha256, pinned: pins.length > 0 };
}

export function countryOf(cert: Certificate): string {
  return cert.subjectCountry ?? "??";
}

export function toPem(der: Uint8Array): string {
  const body = Buffer.from(der).toString("base64").replace(/(.{64})/g, "$1\n").trimEnd();
  return `-----BEGIN CERTIFICATE-----\n${body}\n-----END CERTIFICATE-----\n`;
}
