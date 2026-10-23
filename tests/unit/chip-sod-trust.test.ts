import { readFileSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, expect, test } from "bun:test";
import { parseSod } from "../../src/features/verification/domain/chip/cms";
import { resolveSignatureScheme } from "../../src/features/verification/domain/chip/crypto/signature-schemes";
import { UnsupportedAlgorithmError } from "../../src/features/verification/domain/chip/errors";
import { OID } from "../../src/features/verification/domain/chip/oids";
import { parseLdsSecurityObject } from "../../src/features/verification/domain/chip/lds-security-object";
import { CscaTrustStore, TrustStoreError } from "../../src/features/verification/infra/csca-trust-store";
import { loadFiles, loadTrust } from "./chip-fixtures";

describe("EF.SOD structure (OpenSSL-made)", () => {
  test("LDSSecurityObject: SHA-256, data groups 1 and 2", () => {
    const sod = parseSod(loadFiles("rsa-pkcs1").sod);
    expect(sod.eContentType).toBe(OID.ldsSecurityObject);
    const lds = parseLdsSecurityObject(sod.eContent);
    expect(lds.hashAlgorithm).toBe("sha256");
    expect([...lds.dataGroupHashes.keys()]).toEqual([1, 2]);
  });

  test("signer identified by issuerAndSerialNumber or by subjectKeyIdentifier", () => {
    expect(parseSod(loadFiles("rsa-pkcs1").sod).signerInfos[0]?.sid.kind).toBe("issuerAndSerial");
    expect(parseSod(loadFiles("ecdsa-p256").sod).signerInfos[0]?.sid.kind).toBe("subjectKeyId");
  });

  test("signature schemes resolved from the real SignerInfos", () => {
    const scheme = (v: Parameters<typeof loadFiles>[0]) => {
      const signer = parseSod(loadFiles(v).sod).signerInfos[0];
      if (!signer) throw new Error("no signer");
      return resolveSignatureScheme(signer.signatureAlgorithm, signer.digestAlgorithm);
    };
    expect(scheme("rsa-pkcs1")).toEqual({ kind: "rsa-pkcs1", hash: "sha256" });
    expect(scheme("rsa-pss")).toEqual({ kind: "rsa-pss", hash: "sha256", saltLength: 32 });
    expect(scheme("ecdsa-p256").kind).toBe("ecdsa");
  });

  test("an unknown signature OID is refused", () => {
    expect(() => resolveSignatureScheme({ oid: "1.2.3.4", parameters: undefined })).toThrow(UnsupportedAlgorithmError);
    expect(() => resolveSignatureScheme({ oid: OID.rsaEncryption, parameters: undefined })).toThrow(UnsupportedAlgorithmError);
  });

  test("the explicit-parameter brainpool DSC is parsed with its curve", () => {
    const sod = parseSod(loadFiles("ecdsa-brainpool-explicit").sod);
    const dsc = sod.certificates[0];
    expect(dsc?.spki.algorithm.oid).toBe(OID.ecPublicKey);
    expect(dsc?.spki.algorithm.parameters?.tag).toBe(0x30); // explicit ECParameters, not a named-curve OID
    expect(dsc?.notAfter.toISOString()).toBe("2025-04-01T00:00:00.000Z");
  });
});

describe("CSCA trust store", () => {
  const pem = (v: Parameters<typeof loadTrust>[0]): string => readFileSync(join(import.meta.dir, "..", "fixtures", "chip", v, "csca.pem"), "utf8");

  test("loads concatenated PEMs and counts unreadable entries instead of failing", () => {
    const junk = "-----BEGIN CERTIFICATE-----\nAAAA\n-----END CERTIFICATE-----\n";
    const store = CscaTrustStore.fromPem(pem("rsa-pkcs1") + junk + pem("ecdsa-p256"));
    expect(store.certificates.length).toBe(2);
    expect(store.skipped).toBe(1);
  });

  test("candidates are found by issuer name and narrowed by authority key id", () => {
    const store = loadTrust("rsa-pkcs1", "rsa-pss");
    const dsc = parseSod(loadFiles("rsa-pkcs1").sod).certificates[0];
    if (!dsc) throw new Error("no dsc");
    const found = store.candidatesFor(dsc.issuer, dsc.authorityKeyId);
    expect(found.length).toBe(1);
    expect(found[0]?.subject).toBe(dsc.issuer);
    expect(store.candidatesFor("1.2.3=nobody", undefined)).toEqual([]);
    expect(store.candidatesFor(dsc.issuer, new Uint8Array(20))).toEqual([]);
  });

  test("a missing bundle is a TrustStoreError; CSCA_BUNDLE_PATH selects the file", async () => {
    await expect(CscaTrustStore.fromFile("/nonexistent/csca.pem")).rejects.toBeInstanceOf(TrustStoreError);
    const dir = mkdtempSync(join(tmpdir(), "csca-test-"));
    writeFileSync(join(dir, "bundle.pem"), pem("rsa-pkcs1"));
    const store = await CscaTrustStore.fromEnv({ CSCA_BUNDLE_PATH: join(dir, "bundle.pem") });
    expect(store.certificates.length).toBe(1);
  });
});
