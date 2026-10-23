import { describe, expect, test } from "bun:test";
import { createIssuingStateRegistry, ICAO_STATES } from "../../src/features/verification/domain/chip/icao-states";
import { CscaTrustStore } from "../../src/features/verification/infra/csca-trust-store";
import { join } from "node:path";

describe("ICAO issuing state -> countryName mapping (Doc 9303 Part 3, 5)", () => {
  test("ordinary states follow ISO 3166-1 alpha-3 to alpha-2", () => {
    expect(ICAO_STATES.countryCodesFor("FRA")).toEqual(["FR"]);
    expect(ICAO_STATES.countryCodesFor("DEU")).toEqual(["DE"]);
    expect(ICAO_STATES.countryCodesFor("USA")).toEqual(["US"]);
    expect(ICAO_STATES.countryCodesFor("ISR")).toEqual(["IL"]);
    expect(ICAO_STATES.countryCodesFor("CHE")).toEqual(["CH"]);
  });

  test("ICAO specials", () => {
    expect(ICAO_STATES.countryCodesFor("D")).toEqual(["DE"]);
    for (const code of ["GBR", "GBD", "GBN", "GBO", "GBP", "GBS"]) expect(ICAO_STATES.countryCodesFor(code)).toEqual(["GB"]);
    expect(ICAO_STATES.countryCodesFor("RKS")).toEqual(expect.arrayContaining(["XK", "KS"]));
    expect(ICAO_STATES.countryCodesFor("EUE")).toEqual(["EU"]);
    for (const code of ["UNO", "UNA", "UNK"]) expect(ICAO_STATES.countryCodesFor(code)).toEqual(["UN"]);
  });

  test("unknown or malformed states map to nothing", () => {
    for (const code of ["", "XXX", "ZZZ", "fra", "FR", "FRAN", "UTO"]) expect(ICAO_STATES.countryCodesFor(code)).toEqual([]);
  });

  test("extra entries can be injected without touching the defaults", () => {
    const custom = createIssuingStateRegistry({ UTO: ["UT"] });
    expect(custom.countryCodesFor("UTO")).toEqual(["UT"]);
    expect(custom.countryCodesFor("FRA")).toEqual([]);
    expect(ICAO_STATES.countryCodesFor("UTO")).toEqual([]);
  });

  test("every country present in the committed CSCA bundle is reachable from an ICAO code", async () => {
    const store = await CscaTrustStore.fromFile(join(import.meta.dir, "..", "..", "data", "csca", "csca.pem"));
    const reachable = new Set<string>();
    for (const a of "ABCDEFGHIJKLMNOPQRSTUVWXYZ") {
      for (const b of "ABCDEFGHIJKLMNOPQRSTUVWXYZ") {
        for (const c of "ABCDEFGHIJKLMNOPQRSTUVWXYZ") for (const cc of ICAO_STATES.countryCodesFor(a + b + c)) reachable.add(cc);
      }
    }
    for (const cc of ICAO_STATES.countryCodesFor("D")) reachable.add(cc);
    const missing = [...new Set(store.certificates.map((c) => c.subjectCountry))].filter((c) => c === undefined || !reachable.has(c));
    expect(missing).toEqual([]);
  });

  test("every certificate of the bundle carries exactly one countryName", async () => {
    const store = await CscaTrustStore.fromFile(join(import.meta.dir, "..", "..", "data", "csca", "csca.pem"));
    expect(store.certificates.filter((c) => c.subjectCountry === undefined).length).toBe(0);
  });
});
