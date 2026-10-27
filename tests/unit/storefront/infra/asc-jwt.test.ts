import { describe, expect, test } from "bun:test";
import { generateKeyPairSync, verify } from "node:crypto";
import { createAppStorePricing, readAscConfig } from "../../../../src/features/storefront/infra/app-store-connect";
import { AscTokenProvider, signAscToken } from "../../../../src/features/storefront/infra/app-store-connect/jwt";

const decode = (part: string): Record<string, unknown> => JSON.parse(Buffer.from(part, "base64url").toString("utf8")) as Record<string, unknown>;

function keyPair() {
  const { privateKey, publicKey } = generateKeyPairSync("ec", { namedCurve: "P-256" });
  return { pem: privateKey.export({ type: "pkcs8", format: "pem" }).toString(), publicKey };
}

describe("App Store Connect token (RFC 7515 / RFC 7518 ES256)", () => {
  test("is a three-part JWT whose signature the public key verifies", async () => {
    const { pem, publicKey } = keyPair();
    const { token } = await signAscToken({ keyId: "ABC123DEFG", issuerId: "11111111-2222-3333-4444-555555555555", privateKeyPem: pem }, 1_800_000_000);
    const [header, claims, signature] = token.split(".") as [string, string, string];
    expect(decode(header)).toEqual({ alg: "ES256", kid: "ABC123DEFG", typ: "JWT" });
    const body = decode(claims);
    expect(body.iss).toBe("11111111-2222-3333-4444-555555555555");
    expect(body.aud).toBe("appstoreconnect-v1");
    expect(body.iat).toBe(1_800_000_000);
    expect(Number(body.exp) - Number(body.iat)).toBeLessThanOrEqual(20 * 60);
    // JWS ES256 signature = 64 raw bytes (r || s), not DER.
    const raw = Buffer.from(signature, "base64url");
    expect(raw.length).toBe(64);
    const ok = verify("sha256", Buffer.from(`${header}.${claims}`), { key: publicKey, dsaEncoding: "ieee-p1363" }, raw);
    expect(ok).toBe(true);
  });

  test("a signature over other content does not verify", async () => {
    const { pem, publicKey } = keyPair();
    const { token } = await signAscToken({ keyId: "K", issuerId: "I", privateKeyPem: pem }, 1_800_000_000);
    const [header, claims, signature] = token.split(".") as [string, string, string];
    expect(verify("sha256", Buffer.from(`${header}.${claims}x`), { key: publicKey, dsaEncoding: "ieee-p1363" }, Buffer.from(signature, "base64url"))).toBe(false);
  });

  test("is cached until a minute before expiry, then renewed", async () => {
    const { pem } = keyPair();
    let now = 1_800_000_000_000;
    const provider = new AscTokenProvider({ keyId: "K", issuerId: "I", privateKeyPem: pem }, () => now);
    const first = await provider.token();
    now += 10 * 60 * 1000;
    expect(await provider.token()).toBe(first);
    now += 5 * 60 * 1000; // 15 min lifetime - 60 s margin passed
    expect(await provider.token()).not.toBe(first);
  });
});

describe("configuration", () => {
  const full = { ASC_KEY_ID: "K", ASC_ISSUER_ID: "I", ASC_PRIVATE_KEY: "-----BEGIN PRIVATE KEY-----\\nAAAA\\n-----END PRIVATE KEY-----" };

  test("accepts a PEM whose newlines are escaped", () => {
    expect(readAscConfig(full)?.privateKeyPem).toBe("-----BEGIN PRIVATE KEY-----\nAAAA\n-----END PRIVATE KEY-----");
  });

  test.each(["ASC_KEY_ID", "ASC_ISSUER_ID", "ASC_PRIVATE_KEY"])("is null when %s is missing, so the factory returns null", (name) => {
    const env: Record<string, string | undefined> = { ...full, [name]: undefined };
    expect(readAscConfig(env)).toBeNull();
    expect(createAppStorePricing(env)).toBeNull();
    expect(createAppStorePricing({ ...full, [name]: "  " })).toBeNull();
  });
});
