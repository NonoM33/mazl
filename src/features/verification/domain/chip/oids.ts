// Object identifiers used by ICAO 9303 Part 11/12, CMS and X.509.

export const OID = {
  contentTypeSignedData: "1.2.840.113549.1.7.2",
  ldsSecurityObject: "2.23.136.1.1.1", // ICAO 9303-10, id-icao-ldsSecurityObject
  attrContentType: "1.2.840.113549.1.9.3",
  attrMessageDigest: "1.2.840.113549.1.9.4",
  extSubjectKeyIdentifier: "2.5.29.14",
  extAuthorityKeyIdentifier: "2.5.29.35",
  rsaEncryption: "1.2.840.113549.1.1.1",
  rsaPss: "1.2.840.113549.1.1.10",
  mgf1: "1.2.840.113549.1.1.8",
  ecPublicKey: "1.2.840.10045.2.1",
  primeField: "1.2.840.10045.1.1",
} as const;

export type HashName = "sha1" | "sha224" | "sha256" | "sha384" | "sha512";

export const HASH_OIDS: Readonly<Record<string, HashName>> = {
  "1.3.14.3.2.26": "sha1",
  "2.16.840.1.101.3.4.2.4": "sha224",
  "2.16.840.1.101.3.4.2.1": "sha256",
  "2.16.840.1.101.3.4.2.2": "sha384",
  "2.16.840.1.101.3.4.2.3": "sha512",
};

export const HASH_OUTPUT_BYTES: Readonly<Record<HashName, number>> = {
  sha1: 20,
  sha224: 28,
  sha256: 32,
  sha384: 48,
  sha512: 64,
};
