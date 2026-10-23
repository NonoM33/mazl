import { readFileSync } from "node:fs";
import { join } from "node:path";
import type { ChipFiles } from "../../src/features/verification/domain/types";
import { CscaTrustStore } from "../../src/features/verification/infra/csca-trust-store";

// Loads the OpenSSL-generated fixtures of tests/fixtures/chip (make-fixtures.sh).
const ROOT = join(import.meta.dir, "..", "fixtures", "chip");

export const NOW = new Date("2026-10-23T12:00:00Z");

export type Variant = "rsa-pkcs1" | "rsa-pss" | "rsa-pss-cert" | "ecdsa-p256" | "ecdsa-brainpool-explicit" | "untrusted-csca" | "bad-mrz";

export function loadFiles(variant: Variant): ChipFiles {
  const read = (name: string): Uint8Array => new Uint8Array(readFileSync(join(ROOT, variant, name)));
  return { dg1: read("dg1.bin"), dg2: read("dg2.bin"), sod: read("sod.bin") };
}

export function loadTrust(...variants: Variant[]): CscaTrustStore {
  return CscaTrustStore.fromPem(variants.map((v) => readFileSync(join(ROOT, v, "csca.pem"), "utf8")).join("\n"));
}

export function fixtureJpeg(name: "face-a" | "face-b"): Uint8Array {
  return new Uint8Array(readFileSync(join(ROOT, `${name}.jpg`)));
}

export const TRUSTED: readonly Variant[] = ["rsa-pkcs1", "rsa-pss", "rsa-pss-cert", "ecdsa-p256", "ecdsa-brainpool-explicit"];
