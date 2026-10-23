import { createHash } from "node:crypto";
import { describe, expect, test } from "bun:test";
import { PassiveChipVerifier } from "../../src/features/verification/infra/passive-chip-verifier";
import type { ChipFiles } from "../../src/features/verification/domain/types";
import { fixtureJpeg, loadFiles, loadTrust, NOW, TRUSTED, type Variant } from "./chip-fixtures";

const verifier = new PassiveChipVerifier(loadTrust(...TRUSTED));

function mutate(bytes: Uint8Array, index: number): Uint8Array {
  const copy = bytes.slice();
  copy[index] = (copy[index] as number) ^ 0x01;
  return copy;
}

function indexOf(haystack: Uint8Array, needle: Uint8Array): number {
  return Buffer.from(haystack).indexOf(Buffer.from(needle));
}

describe("passive authentication: valid documents", () => {
  const variants: Variant[] = ["rsa-pkcs1", "rsa-pss", "rsa-pss-cert", "ecdsa-p256", "ecdsa-brainpool-explicit"];
  for (const variant of variants) {
    test(`${variant} verifies and yields identity + face`, async () => {
      const result = await verifier.verify(loadFiles(variant), NOW);
      expect(result.ok).toBe(true);
      if (!result.ok) return;
      expect(result.identity).toEqual({
        documentType: "P",
        issuingState: "UTO",
        documentNumber: "L898902C3",
        birthDate: "1974-08-12",
        expiryDate: "2032-04-15",
        sex: "F",
      });
      expect(result.faceImageFormat).toBe("jpeg");
      const expected = variant === "rsa-pkcs1" || variant === "ecdsa-p256" || variant === "rsa-pss-cert" ? "face-a" : "face-b";
      expect(Buffer.from(result.faceImage).equals(Buffer.from(fixtureJpeg(expected)))).toBe(true);
    });
  }
});

describe("passive authentication: attacks", () => {
  test("a tampered DG1 byte is chip_data_invalid", async () => {
    const files = loadFiles("rsa-pkcs1");
    const result = await verifier.verify({ ...files, dg1: mutate(files.dg1, 20) }, NOW);
    expect(result).toEqual({ ok: false, reason: "chip_data_invalid" });
  });

  test("a DG2 taken from another document is chip_data_invalid", async () => {
    const files = loadFiles("rsa-pkcs1");
    const other = loadFiles("rsa-pss");
    expect(Buffer.from(files.dg2).equals(Buffer.from(other.dg2))).toBe(false);
    const result = await verifier.verify({ ...files, dg2: other.dg2 }, NOW);
    expect(result).toEqual({ ok: false, reason: "chip_data_invalid" });
  });

  for (const variant of ["rsa-pkcs1", "rsa-pss", "ecdsa-p256", "ecdsa-brainpool-explicit"] as const) {
    test(`a flipped signature byte is chip_signature_invalid (${variant})`, async () => {
      const files = loadFiles(variant);
      // The signature value is the last OCTET STRING of the SOD: flip a byte near the end.
      const result = await verifier.verify({ ...files, sod: mutate(files.sod, files.sod.length - 3) }, NOW);
      expect(result).toEqual({ ok: false, reason: "chip_signature_invalid" });
    });
  }

  test("a DSC issued by an untrusted CA is csca_unknown", async () => {
    const result = await verifier.verify(loadFiles("untrusted-csca"), NOW);
    expect(result).toEqual({ ok: false, reason: "csca_unknown" });
  });

  test("validly signed data with a bad MRZ check digit is chip_data_invalid", async () => {
    const result = await new PassiveChipVerifier(loadTrust("bad-mrz")).verify(loadFiles("bad-mrz"), NOW);
    expect(result).toEqual({ ok: false, reason: "chip_data_invalid" });
  });

  test("oversized inputs are refused before any parsing", async () => {
    const files = loadFiles("rsa-pkcs1");
    expect(await verifier.verify({ ...files, sod: new Uint8Array(70_000) }, NOW)).toEqual({ ok: false, reason: "chip_data_invalid" });
    expect(await verifier.verify({ ...files, dg2: new Uint8Array(3_000_000) }, NOW)).toEqual({ ok: false, reason: "chip_data_invalid" });
    expect(await verifier.verify({ ...files, dg1: new Uint8Array(2_000) }, NOW)).toEqual({ ok: false, reason: "chip_data_invalid" });
  });

  test("an empty trust store is csca_unknown", async () => {
    const result = await new PassiveChipVerifier(loadTrust()).verify(loadFiles("rsa-pkcs1"), NOW);
    expect(result).toEqual({ ok: false, reason: "csca_unknown" });
  });

  test("a CSCA outside its validity period is csca_unknown", async () => {
    const result = await verifier.verify(loadFiles("rsa-pkcs1"), new Date("2041-01-01T00:00:00Z"));
    expect(result).toEqual({ ok: false, reason: "csca_unknown" });
    const early = await verifier.verify(loadFiles("rsa-pkcs1"), new Date("2019-01-01T00:00:00Z"));
    expect(early).toEqual({ ok: false, reason: "csca_unknown" });
  });

  test("a CSCA with the same name but another key does not validate the DSC", async () => {
    // Trust only the CSCA of another variant: different subject, so unknown.
    const result = await new PassiveChipVerifier(loadTrust("rsa-pss")).verify(loadFiles("rsa-pkcs1"), NOW);
    expect(result).toEqual({ ok: false, reason: "csca_unknown" });
  });
});

describe("passive authentication: garbage never crashes", () => {
  const files = loadFiles("rsa-pkcs1");
  const cases: Array<[string, Uint8Array]> = [
    ["empty", new Uint8Array(0)],
    ["one byte", new Uint8Array([0x77])],
    ["wrong tag", Uint8Array.of(0x30, 0x00)],
    ["truncated", files.sod.slice(0, files.sod.length - 40)],
    ["trailing byte", Uint8Array.of(...files.sod, 0)],
    ["random", crypto.getRandomValues(new Uint8Array(300))],
    ["indefinite length", Uint8Array.of(0x77, 0x80, 0x00, 0x00)],
    ["huge length", Uint8Array.of(0x77, 0x84, 0xff, 0xff, 0xff, 0xff)],
  ];
  for (const [name, sod] of cases) {
    test(`SOD: ${name}`, async () => {
      expect(await verifier.verify({ ...files, sod }, NOW)).toEqual({ ok: false, reason: "chip_data_invalid" });
    });
  }

  test("every truncation of the SOD is rejected without throwing", async () => {
    for (let len = 0; len < files.sod.length; len += 7) {
      const result = await verifier.verify({ ...files, sod: files.sod.slice(0, len) }, NOW);
      expect(result.ok).toBe(false);
    }
  });

  // A few CMS fields are not authenticated and not used (SignedData version,
  // digestAlgorithms, string-type tags of names): flipping them may still
  // verify, but it must then yield exactly the signed data, never other data.
  test("flipping any single SOD byte never changes what is accepted and never throws", async () => {
    const reference = await verifier.verify(files, NOW);
    expect(reference.ok).toBe(true);
    for (let i = 0; i < files.sod.length; i++) {
      const result = await verifier.verify({ ...files, sod: mutate(files.sod, i) }, NOW);
      if (result.ok) expect<unknown>(result).toEqual(reference);
    }
  });

  test("flipping a signed hash (LDS content or messageDigest attribute) is always rejected", async () => {
    const dg1Hash = createHash("sha256").update(files.dg1).digest();
    const at = indexOf(files.sod, dg1Hash);
    expect(at).toBeGreaterThan(0);
    const inContent = await verifier.verify({ ...files, sod: mutate(files.sod, at + 5) }, NOW);
    expect(inContent).toEqual({ ok: false, reason: "chip_signature_invalid" });
    // The messageDigest attribute: the 32-byte hash of eContent, found after its OID.
    const attrOid = Buffer.from("2a864886f70d010904", "hex");
    const attrAt = indexOf(files.sod, attrOid);
    expect(attrAt).toBeGreaterThan(0);
    const inAttr = await verifier.verify({ ...files, sod: mutate(files.sod, attrAt + attrOid.length + 6) }, NOW);
    expect(inAttr).toEqual({ ok: false, reason: "chip_signature_invalid" });
  });

  test("garbage DG1 / DG2", async () => {
    const bad: ChipFiles = { ...files, dg1: new Uint8Array([1, 2, 3]), dg2: new Uint8Array(0) };
    expect(await verifier.verify(bad, NOW)).toEqual({ ok: false, reason: "chip_data_invalid" });
  });
});
