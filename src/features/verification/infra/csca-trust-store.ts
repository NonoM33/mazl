import { ChipParseError } from "../domain/chip/errors";
import { parseCertificate, pemToDerList, type Certificate } from "../domain/chip/x509";
import type { TrustAnchors } from "../application/chip-crypto";

export const DEFAULT_CSCA_BUNDLE_PATH = "data/csca/csca.pem";

export class TrustStoreError extends Error {
  constructor(reason: string) {
    super(reason);
    this.name = "TrustStoreError";
  }
}

function sameBytes(a: Uint8Array, b: Uint8Array): boolean {
  return a.length === b.length && a.every((v, i) => v === b[i]);
}

// CSCA certificates (country signing CAs) loaded from a concatenated PEM bundle.
export class CscaTrustStore implements TrustAnchors {
  private readonly bySubject = new Map<string, Certificate[]>();

  constructor(
    readonly certificates: readonly Certificate[],
    readonly skipped = 0,
  ) {
    for (const cert of certificates) {
      const list = this.bySubject.get(cert.subject) ?? [];
      list.push(cert);
      this.bySubject.set(cert.subject, list);
    }
  }

  static empty(): CscaTrustStore {
    return new CscaTrustStore([]);
  }

  // Certificates that fail to parse are counted in `skipped`, not fatal: one
  // odd entry must not disable every other country.
  static fromPem(pem: string): CscaTrustStore {
    const certs: Certificate[] = [];
    let skipped = 0;
    for (const der of pemToDerList(pem)) {
      try {
        certs.push(parseCertificate(der));
      } catch (e) {
        if (!(e instanceof ChipParseError)) throw e;
        skipped++;
      }
    }
    return new CscaTrustStore(certs, skipped);
  }

  static async fromFile(path: string): Promise<CscaTrustStore> {
    const file = Bun.file(path);
    if (!(await file.exists())) throw new TrustStoreError(`CSCA bundle not found: ${path}`);
    return CscaTrustStore.fromPem(await file.text());
  }

  // CSCA_BUNDLE_PATH, default data/csca/csca.pem (CONTRAT.md 1).
  static fromEnv(env: Record<string, string | undefined> = process.env): Promise<CscaTrustStore> {
    return CscaTrustStore.fromFile(env.CSCA_BUNDLE_PATH ?? DEFAULT_CSCA_BUNDLE_PATH);
  }

  candidatesFor(issuer: string, authorityKeyId: Uint8Array | undefined): readonly Certificate[] {
    const byName = this.bySubject.get(issuer) ?? [];
    if (authorityKeyId === undefined) return byName;
    const aligned = byName.filter((c) => c.subjectKeyId === undefined || sameBytes(c.subjectKeyId, authorityKeyId));
    if (aligned.length > 0 || byName.length > 0) return aligned;
    // Name encoding differences: fall back to the key identifier alone.
    return this.certificates.filter((c) => c.subjectKeyId !== undefined && sameBytes(c.subjectKeyId, authorityKeyId));
  }
}
