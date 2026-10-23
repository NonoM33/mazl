import { parseDg1 } from "../domain/chip/dg1";
import { parseDg2 } from "../domain/chip/dg2";
import { parseSod, type SignedData } from "../domain/chip/cms";
import type { IssuingStateRegistry } from "../domain/chip/icao-states";
import { parseLdsSecurityObject } from "../domain/chip/lds-security-object";
import { OID } from "../domain/chip/oids";
import type { Certificate } from "../domain/chip/x509";
import type { ChipFiles, ChipVerification } from "../domain/types";
import type { ChipCrypto, TrustAnchors } from "./chip-crypto";
import { isIssuedBy, sameBytes, verifySignedData } from "./signed-data-verification";

// ICAO Doc 9303 Part 11 passive authentication, steps in order:
//   1. EF.SOD is CMS SignedData of type id-icao-ldsSecurityObject
//   2. its signer (the DSC) is one of the embedded certificates
//   3. the signature over the signed attributes verifies with the DSC key
//   4. the DSC chains to a trusted, currently valid CSCA
//   5. DG1 / DG2 hash to the values signed in the LDSSecurityObject
//   6. (after parsing DG1) the countryName of the CSCA and of the DSC issuer
//      corresponds to DG1's issuing state: country binding
// DG1 and DG2 are parsed only after step 5.
//
// Choices (documented deviations from a full 9303 path validation):
//  - Only the CSCA validity is compared with `now`. A DSC signs for months but
//    the documents it covers live ten years, so DSC validity is not checked.
//  - No CRL / revocation, no key-usage or basic-constraints checks.
//  - The DSC must be embedded in the SOD (optional in 9303, near-universal).

type Failure = Extract<ChipVerification, { ok: false }>;
const fail = (reason: Failure["reason"]): Failure => ({ ok: false, reason });

export interface PassiveAuthDeps {
  readonly crypto: ChipCrypto;
  readonly trust: TrustAnchors;
  readonly states: IssuingStateRegistry;
}

function findIssuingCsca(dsc: Certificate, now: Date, deps: PassiveAuthDeps): Certificate | undefined {
  return deps.trust
    .candidatesFor(dsc.issuer, dsc.authorityKeyId)
    .find((csca) => now >= csca.notBefore && now <= csca.notAfter && isIssuedBy(dsc, csca, deps.crypto));
}

// Country binding: the CSCA that vouched for the DSC, and the DSC issuer name,
// must both belong to the state DG1 claims. Without it a CSCA of any country
// could validate a document claiming to be issued by another.
function boundToIssuingState(issuingState: string, csca: Certificate, dsc: Certificate, deps: PassiveAuthDeps): boolean {
  const accepted = deps.states.countryCodesFor(issuingState);
  const matches = (country: string | undefined): boolean => country !== undefined && accepted.includes(country);
  return matches(csca.subjectCountry) && matches(dsc.issuerCountry);
}

function dataGroupsMatch(files: ChipFiles, signedData: SignedData, deps: PassiveAuthDeps): boolean {
  const lds = parseLdsSecurityObject(signedData.eContent);
  const expected: ReadonlyArray<readonly [number, Uint8Array]> = [
    [1, files.dg1],
    [2, files.dg2],
  ];
  return expected.every(([n, bytes]) => {
    const signed = lds.dataGroupHashes.get(n);
    return signed !== undefined && sameBytes(signed, deps.crypto.digest(lds.hashAlgorithm, bytes));
  });
}

export function authenticatePassively(files: ChipFiles, now: Date, deps: PassiveAuthDeps): ChipVerification {
  const signedData = parseSod(files.sod);
  if (signedData.eContentType !== OID.ldsSecurityObject) return fail("chip_data_invalid");
  const signature = verifySignedData(signedData, deps.crypto);
  if (!signature.ok) return fail(signature.reason);
  const csca = findIssuingCsca(signature.signer, now, deps);
  if (csca === undefined) return fail("csca_unknown");
  if (!dataGroupsMatch(files, signedData, deps)) return fail("chip_data_invalid");

  const identity = parseDg1(files.dg1, now);
  const face = parseDg2(files.dg2);
  if (!boundToIssuingState(identity.issuingState, csca, signature.signer, deps)) return fail("csca_unknown");
  return { ok: true, identity, faceImage: face.bytes, faceImageFormat: face.format };
}
