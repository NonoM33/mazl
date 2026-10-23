// Issuing-state codes of the MRZ (ICAO Doc 9303 Part 3, section 5) mapped to the
// countryName (C) used in CSCA / DSC distinguished names (ISO 3166-1 alpha-2).
//
// The ICAO list is ISO 3166-1 alpha-3 plus a few special codes, listed after
// the ISO table. Special cases checked against the real BSI master list
// (data/csca/csca.pem, 2026-10-23): 117 countryName values, all ISO alpha-2
// except Kosovo ("KS", not ISO's "XK"), the EU ("EU") and the UN ("UN").
// Cross-certification between GB and BM exists in the list but is not
// accepted here: a document says who issued it, and that CSCA must be theirs.

export interface IssuingStateRegistry {
  // Accepted countryName values for an ICAO issuing-state code; [] if unknown.
  countryCodesFor(icaoState: string): readonly string[];
}

// ISO 3166-1 alpha-3:alpha-2
const ISO_PAIRS = `AFG:AF ALA:AX ALB:AL DZA:DZ ASM:AS AND:AD AGO:AO AIA:AI ATA:AQ ATG:AG ARG:AR ARM:AM ABW:AW AUS:AU AUT:AT AZE:AZ
BHS:BS BHR:BH BGD:BD BRB:BB BLR:BY BEL:BE BLZ:BZ BEN:BJ BMU:BM BTN:BT BOL:BO BES:BQ BIH:BA BWA:BW BVT:BV BRA:BR IOT:IO BRN:BN
BGR:BG BFA:BF BDI:BI CPV:CV KHM:KH CMR:CM CAN:CA CYM:KY CAF:CF TCD:TD CHL:CL CHN:CN CXR:CX CCK:CC COL:CO COM:KM COG:CG COD:CD
COK:CK CRI:CR CIV:CI HRV:HR CUB:CU CUW:CW CYP:CY CZE:CZ DNK:DK DJI:DJ DMA:DM DOM:DO ECU:EC EGY:EG SLV:SV GNQ:GQ ERI:ER EST:EE
SWZ:SZ ETH:ET FLK:FK FRO:FO FJI:FJ FIN:FI FRA:FR GUF:GF PYF:PF ATF:TF GAB:GA GMB:GM GEO:GE DEU:DE GHA:GH GIB:GI GRC:GR GRL:GL
GRD:GD GLP:GP GUM:GU GTM:GT GGY:GG GIN:GN GNB:GW GUY:GY HTI:HT HMD:HM VAT:VA HND:HN HKG:HK HUN:HU ISL:IS IND:IN IDN:ID IRN:IR
IRQ:IQ IRL:IE IMN:IM ISR:IL ITA:IT JAM:JM JPN:JP JEY:JE JOR:JO KAZ:KZ KEN:KE KIR:KI PRK:KP KOR:KR KWT:KW KGZ:KG LAO:LA LVA:LV
LBN:LB LSO:LS LBR:LR LBY:LY LIE:LI LTU:LT LUX:LU MAC:MO MDG:MG MWI:MW MYS:MY MDV:MV MLI:ML MLT:MT MHL:MH MTQ:MQ MRT:MR MUS:MU
MYT:YT MEX:MX FSM:FM MDA:MD MCO:MC MNG:MN MNE:ME MSR:MS MAR:MA MOZ:MZ MMR:MM NAM:NA NRU:NR NPL:NP NLD:NL NCL:NC NZL:NZ NIC:NI
NER:NE NGA:NG NIU:NU NFK:NF MKD:MK MNP:MP NOR:NO OMN:OM PAK:PK PLW:PW PSE:PS PAN:PA PNG:PG PRY:PY PER:PE PHL:PH PCN:PN POL:PL
PRT:PT PRI:PR QAT:QA REU:RE ROU:RO RUS:RU RWA:RW BLM:BL SHN:SH KNA:KN LCA:LC MAF:MF SPM:PM VCT:VC WSM:WS SMR:SM STP:ST SAU:SA
SEN:SN SRB:RS SYC:SC SLE:SL SGP:SG SXM:SX SVK:SK SVN:SI SLB:SB SOM:SO ZAF:ZA SGS:GS SSD:SS ESP:ES LKA:LK SDN:SD SUR:SR SJM:SJ
SWE:SE CHE:CH SYR:SY TWN:TW TJK:TJ TZA:TZ THA:TH TLS:TL TGO:TG TKL:TK TON:TO TTO:TT TUN:TN TUR:TR TKM:TM TCA:TC TUV:TV UGA:UG
UKR:UA ARE:AE GBR:GB USA:US UMI:UM URY:UY UZB:UZ VUT:VU VEN:VE VNM:VN VGB:VG VIR:VI WLF:WF ESH:EH YEM:YE ZMB:ZM ZWE:ZW`;

// ICAO codes that are not ISO alpha-3 codes (9303 Part 3, 5). Codes without a
// CSCA of their own (stateless persons, XBA, XIM...) are deliberately absent:
// no trusted CSCA can vouch for them, so they are refused.
const ICAO_SPECIALS: Readonly<Record<string, readonly string[]>> = {
  D: ["DE"],
  GBD: ["GB"], // British Overseas Territories citizen
  GBN: ["GB"], // British National (Overseas)
  GBO: ["GB"], // British Overseas citizen
  GBP: ["GB"], // British Protected Person
  GBS: ["GB"], // British Subject
  RKS: ["XK", "KS"], // Kosovo: the CSCA in the master list uses "KS"
  EUE: ["EU"], // European Union laissez-passer
  UNO: ["UN"], // United Nations organization official
  UNA: ["UN"], // United Nations specialized agency official
  UNK: ["UN"], // UNMIK travel document
};

const CODE = /^[A-Z]{1,3}$/;

export function createIssuingStateRegistry(extra: Readonly<Record<string, readonly string[]>> = {}, base: boolean = false): IssuingStateRegistry {
  const table = new Map<string, readonly string[]>();
  if (base) {
    for (const pair of ISO_PAIRS.split(/\s+/)) {
      const [alpha3, alpha2] = pair.split(":") as [string, string];
      table.set(alpha3, [alpha2]);
    }
    for (const [code, countries] of Object.entries(ICAO_SPECIALS)) table.set(code, countries);
  }
  for (const [code, countries] of Object.entries(extra)) table.set(code, countries);
  return {
    countryCodesFor: (icaoState) => (CODE.test(icaoState) ? (table.get(icaoState) ?? []) : []),
  };
}

// Production registry: real ICAO states only. Tests inject their own.
export const ICAO_STATES: IssuingStateRegistry = createIssuingStateRegistry({}, true);
