import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, expect, test } from "bun:test";
import { createHash } from "node:crypto";
import { parseSod } from "../../src/features/verification/domain/chip/cms";
import { resolveSignatureScheme } from "../../src/features/verification/domain/chip/crypto/signature-schemes";
import { encodeTlv } from "../../src/features/verification/domain/chip/tlv";
import { countryOf, MasterListError, readMasterList, toPem } from "../../src/features/verification/infra/master-list";
import { NodeChipCrypto } from "../../src/features/verification/infra/node-chip-crypto";
import { CscaTrustStore } from "../../src/features/verification/infra/csca-trust-store";
import { readZip } from "../../src/features/verification/infra/zip-reader";
import { loadFiles, NOW } from "./chip-fixtures";

const FIXTURES = join(import.meta.dir, "..", "fixtures", "chip");
const read = (...p: string[]): Uint8Array => new Uint8Array(readFileSync(join(FIXTURES, ...p)));
const crypto = new NodeChipCrypto();

describe("ICAO master list reading", () => {
  test("verifies the signature, the chain to a root in the list, and extracts every CSCA", () => {
    const ml = readMasterList(read("master-list", "ml-good.der"), crypto, { now: NOW });
    expect(ml.certificates.length).toBe(5);
    expect(ml.unreadable).toBe(0);
    expect(ml.pinned).toBe(false);
    expect(countryOf(ml.certificates[0] as never)).toBe("UT");
    const root = readFileSync(join(FIXTURES, "master-list", "csca.pem"), "utf8");
    const store = CscaTrustStore.fromPem(root);
    expect(createHash("sha256").update(store.certificates[0]?.der ?? new Uint8Array()).digest("hex")).toBe(ml.rootSha256);
  });

  test("a pinned root fingerprint is enforced", () => {
    const good = readMasterList(read("master-list", "ml-good.der"), crypto, { now: NOW });
    expect(readMasterList(read("master-list", "ml-good.der"), crypto, { now: NOW, pinnedRoots: ["00".repeat(32), good.rootSha256.toUpperCase()] }).pinned).toBe(true);
    expect(() => readMasterList(read("master-list", "ml-good.der"), crypto, { now: NOW, pinnedRoots: ["00".repeat(32)] })).toThrow(MasterListError);
  });

  test("a list signed by a CA that is not in the list is refused", () => {
    expect(() => readMasterList(read("master-list", "ml-rogue.der"), crypto, { now: NOW })).toThrow(MasterListError);
  });

  test("a tampered list is refused", () => {
    const bytes = read("master-list", "ml-good.der").slice();
    bytes[bytes.length - 5] = (bytes[bytes.length - 5] as number) ^ 1; // signature value
    expect(() => readMasterList(bytes, crypto, { now: NOW })).toThrow(MasterListError);
    const body = read("master-list", "ml-good.der").slice();
    body[200] = (body[200] as number) ^ 1; // inside the content
    expect(() => readMasterList(body, crypto, { now: NOW })).toThrow();
  });

  test("an expired list signer is refused", () => {
    expect(() => readMasterList(read("master-list", "ml-good.der"), crypto, { now: new Date("2041-01-01T00:00:00Z") })).toThrow(MasterListError);
  });

  test("an EF.SOD is not a master list", () => {
    const sod = loadFiles("rsa-pkcs1").sod;
    expect(() => readMasterList(sod.subarray(4), crypto, { now: NOW })).toThrow(MasterListError);
  });

  test("PEM output round-trips through the trust store", () => {
    const ml = readMasterList(read("master-list", "ml-good.der"), crypto, { now: NOW });
    const pem = ml.certificates.map((c) => toPem(c.der)).join("");
    expect(CscaTrustStore.fromPem(pem).certificates.length).toBe(5);
  });
});

describe("RSA keys whose AlgorithmIdentifier omits the NULL parameters (Estonian CSCAs)", () => {
  test("still verify: BoringSSL alone refuses such an SPKI", () => {
    const sod = parseSod(loadFiles("rsa-pkcs1").sod);
    const signer = sod.signerInfos[0];
    const dsc = sod.certificates[0];
    if (!signer || !dsc) throw new Error("fixture");
    const rsaOid = encodeTlv(0x06, Uint8Array.of(0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01));
    const bits = encodeTlv(0x03, Uint8Array.of(0, ...dsc.spki.publicKey));
    const withoutNull = encodeTlv(0x30, Uint8Array.of(...encodeTlv(0x30, rsaOid), ...bits));
    const key = { ...dsc.spki, der: withoutNull, algorithm: { oid: dsc.spki.algorithm.oid, parameters: undefined } };
    const scheme = resolveSignatureScheme(signer.signatureAlgorithm, signer.digestAlgorithm);
    expect(crypto.verifySignature(scheme, key, signer.signedAttrsDer ?? new Uint8Array(), signer.signature)).toBe(true);
  });
});

describe("ZIP reader", () => {
  test.skipIf(Bun.which("zip") === null)("reads a deflated entry written by the zip tool", () => {
    const dir = mkdtempSync(join(tmpdir(), "zip-test-"));
    const payload = Buffer.from("master list bytes ".repeat(500));
    writeFileSync(join(dir, "DE_ML_test.ml"), payload);
    expect(Bun.spawnSync(["zip", "-q", "-j", join(dir, "a.zip"), join(dir, "DE_ML_test.ml")]).exitCode).toBe(0);
    const [entry] = readZip(new Uint8Array(readFileSync(join(dir, "a.zip"))));
    expect(entry?.name).toBe("DE_ML_test.ml");
    expect(Buffer.from(entry?.data ?? new Uint8Array()).equals(payload)).toBe(true);
  });

  test("garbage is refused", () => {
    expect(() => readZip(new Uint8Array(100))).toThrow();
  });
});

describe("committed CSCA bundle (data/csca/csca.pem, real BSI master list)", () => {
  const bundle = join(import.meta.dir, "..", "..", "data", "csca", "csca.pem");

  test("every certificate parses and France is covered", async () => {
    const store = await CscaTrustStore.fromFile(bundle);
    expect(store.skipped).toBe(0);
    expect(store.certificates.length).toBeGreaterThan(500);
    const countries = new Set(store.certificates.map(countryOf));
    for (const code of ["FR", "DE", "ES", "IT", "BE", "NL", "GB", "US"]) expect(countries.has(code)).toBe(true);
  });

  // Real-world check of the RSA / RSA-PSS / ECDSA / brainpool / explicit-parameter
  // code: any certificate whose issuer is in the bundle must verify against it.
  test("every certificate whose issuer is in the bundle verifies against that issuer", async () => {
    const store = await CscaTrustStore.fromFile(bundle);
    let checked = 0;
    const failures: string[] = [];
    for (const cert of store.certificates) {
      const issuers = store.candidatesFor(cert.issuer, cert.authorityKeyId);
      if (issuers.length === 0) continue;
      checked++;
      const ok = issuers.some((issuer) => {
        try {
          return crypto.verifySignature(resolveSignatureScheme(cert.signatureAlgorithm), issuer.spki, cert.tbs, cert.signature);
        } catch {
          return false;
        }
      });
      if (!ok) failures.push(`${countryOf(cert)} ${cert.signatureAlgorithm.oid}`);
    }
    expect(failures).toEqual([]);
    expect(checked).toBeGreaterThan(550);
  });
});
