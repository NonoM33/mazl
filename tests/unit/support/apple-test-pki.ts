import { createPrivateKey, sign, type KeyObject } from "node:crypto";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

// Throwaway P-256 certificate chain shaped like Apple's StoreKit signing chain
// (root -> intermediate carrying OID 1.2.840.113635.100.6.2.1 -> leaf carrying
// OID 1.2.840.113635.100.6.11.1). Built with the openssl CLI because node
// crypto cannot create X.509 certificates. Nothing here is a real key.

const INTERMEDIATE_OID = "1.2.840.113635.100.6.2.1";
const LEAF_OID = "1.2.840.113635.100.6.11.1";

export interface PkiOptions {
  readonly intermediateOid?: boolean; // default true
  readonly leafOid?: boolean; // default true
}

export interface TestPki {
  readonly rootDer: Buffer;
  readonly intermediateDer: Buffer;
  readonly leafDer: Buffer;
  readonly leafKey: KeyObject;
  // x5c as Apple orders it: leaf, intermediate, root (standard base64 DER).
  readonly x5c: readonly string[];
}

async function openssl(...args: string[]): Promise<void> {
  const proc = Bun.spawn(["openssl", ...args], { stdout: "ignore", stderr: "pipe" });
  const code = await proc.exited;
  if (code !== 0) throw new Error(`openssl ${args[0]} failed: ${await new Response(proc.stderr).text()}`);
}

async function derOf(pemPath: string): Promise<Buffer> {
  const pem = await readFile(pemPath, "utf8");
  const body = pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  return Buffer.from(body, "base64");
}

async function newKey(dir: string, name: string): Promise<string> {
  const path = join(dir, `${name}.key`);
  await openssl("ecparam", "-name", "prime256v1", "-genkey", "-noout", "-out", path);
  return path;
}

async function issue(dir: string, name: string, issuer: string, extensions: string[]): Promise<void> {
  const extFile = join(dir, `${name}.ext`);
  await writeFile(extFile, `${extensions.join("\n")}\n`);
  await openssl("req", "-new", "-key", join(dir, `${name}.key`), "-subj", `/CN=Test ${name}`, "-out", join(dir, `${name}.csr`));
  await openssl(
    "x509", "-req", "-in", join(dir, `${name}.csr`), "-CA", join(dir, `${issuer}.pem`), "-CAkey", join(dir, `${issuer}.key`),
    "-CAcreateserial", "-days", "30", "-sha256", "-extfile", extFile, "-out", join(dir, `${name}.pem`),
  );
}

export async function createTestPki(options: PkiOptions = {}): Promise<TestPki> {
  const dir = await mkdtemp(join(tmpdir(), "mazl-apple-pki-"));
  try {
    await newKey(dir, "root");
    await openssl("req", "-new", "-x509", "-key", join(dir, "root.key"), "-sha256", "-days", "30", "-subj", "/CN=Test root", "-out", join(dir, "root.pem"));
    await newKey(dir, "intermediate");
    await issue(dir, "intermediate", "root", [
      "basicConstraints=critical,CA:TRUE",
      ...(options.intermediateOid === false ? [] : [`${INTERMEDIATE_OID}=ASN1:NULL`]),
    ]);
    await newKey(dir, "leaf");
    await issue(dir, "leaf", "intermediate", options.leafOid === false ? [] : [`${LEAF_OID}=ASN1:NULL`]);

    const [rootDer, intermediateDer, leafDer] = await Promise.all([
      derOf(join(dir, "root.pem")),
      derOf(join(dir, "intermediate.pem")),
      derOf(join(dir, "leaf.pem")),
    ]);
    const leafKey = createPrivateKey(await readFile(join(dir, "leaf.key"), "utf8"));
    return {
      rootDer, intermediateDer, leafDer, leafKey,
      x5c: [leafDer, intermediateDer, rootDer].map((der) => der.toString("base64")),
    };
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

function b64url(value: Buffer | string): string {
  return Buffer.from(value).toString("base64url");
}

export interface JwsParts {
  readonly header: Record<string, unknown>;
  readonly payload: Record<string, unknown>;
}

// RFC 7515 compact JWS, ES256: the signature is the raw 64-byte r||s.
export function signJws(parts: JwsParts, key: KeyObject): string {
  const signingInput = `${b64url(JSON.stringify(parts.header))}.${b64url(JSON.stringify(parts.payload))}`;
  const signature = sign("sha256", Buffer.from(signingInput), { key, dsaEncoding: "ieee-p1363" });
  return `${signingInput}.${b64url(signature)}`;
}

export function signedByPki(pki: TestPki, payload: Record<string, unknown>, header: Record<string, unknown> = {}): string {
  return signJws({ header: { alg: "ES256", x5c: pki.x5c, ...header }, payload }, pki.leafKey);
}

// Replaces the payload of a compact JWS, keeping header and signature.
export function withTamperedPayload(jws: string, payload: Record<string, unknown>): string {
  const [header, , signature] = jws.split(".");
  return `${header}.${b64url(JSON.stringify(payload))}.${signature}`;
}
