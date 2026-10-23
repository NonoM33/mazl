import { constants, createHash, createPublicKey, verify } from "node:crypto";
import { InvalidKeyError } from "../domain/chip/errors";
import { OID, type HashName } from "../domain/chip/oids";
import { candidateSignatures, verifyEcdsa } from "../domain/chip/crypto/ecdsa";
import { parseEcParameters } from "../domain/chip/crypto/ec-params";
import { decodePoint } from "../domain/chip/crypto/ec-math";
import { encodeTlv } from "../domain/chip/tlv";
import type { SignatureScheme } from "../domain/chip/crypto/signature-schemes";
import type { SubjectPublicKeyInfo } from "../domain/chip/x509";
import type { ChipCrypto } from "../application/chip-crypto";

const RSA_ALGORITHM_IDENTIFIER = Uint8Array.of(0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00);

// Some CSCAs (e.g. Estonian) omit the NULL parameters of rsaEncryption, which
// BoringSSL refuses; re-wrap the key bits in the RFC 3279 canonical form.
function canonicalRsaSpki(publicKey: Uint8Array): Uint8Array {
  const bits = encodeTlv(0x03, Uint8Array.of(0, ...publicKey));
  return encodeTlv(0x30, Uint8Array.of(...RSA_ALGORITHM_IDENTIFIER, ...bits));
}

// Hashing and RSA through node:crypto (BoringSSL in Bun); ECDSA through our
// own BigInt implementation because BoringSSL has no brainpool curves.
export class NodeChipCrypto implements ChipCrypto {
  digest(hash: HashName, data: Uint8Array): Uint8Array {
    return new Uint8Array(createHash(hash).update(data).digest());
  }

  verifySignature(scheme: SignatureScheme, key: SubjectPublicKeyInfo, message: Uint8Array, signature: Uint8Array): boolean {
    switch (scheme.kind) {
      case "ecdsa":
        return this.verifyEc(scheme, key, message, signature);
      case "rsa-pkcs1":
      case "rsa-pss":
        return this.verifyRsa(scheme, key, message, signature);
    }
  }

  private verifyRsa(scheme: Extract<SignatureScheme, { kind: "rsa-pkcs1" | "rsa-pss" }>, key: SubjectPublicKeyInfo, message: Uint8Array, signature: Uint8Array): boolean {
    if (key.algorithm.oid !== OID.rsaEncryption) throw new InvalidKeyError("not an RSA key");
    let publicKey;
    try {
      publicKey = createPublicKey({ key: Buffer.from(canonicalRsaSpki(key.publicKey)), format: "der", type: "spki" });
    } catch {
      throw new InvalidKeyError("unreadable RSA key");
    }
    const options =
      scheme.kind === "rsa-pss"
        ? { key: publicKey, padding: constants.RSA_PKCS1_PSS_PADDING, saltLength: scheme.saltLength }
        : { key: publicKey, padding: constants.RSA_PKCS1_PADDING };
    try {
      return verify(scheme.hash, message, options, signature);
    } catch {
      return false; // malformed signature value
    }
  }

  private verifyEc(scheme: Extract<SignatureScheme, { kind: "ecdsa" }>, key: SubjectPublicKeyInfo, message: Uint8Array, signature: Uint8Array): boolean {
    if (key.algorithm.oid !== OID.ecPublicKey) throw new InvalidKeyError("not an EC key");
    const curve = parseEcParameters(key.algorithm.parameters);
    const point = decodePoint(curve, key.publicKey);
    const digest = this.digest(scheme.hash, message);
    return candidateSignatures(signature, scheme.format, curve.orderBytes).some((sig) => verifyEcdsa(curve, point, digest, sig));
  }
}

