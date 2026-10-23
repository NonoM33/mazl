// Address classification for the link-preview SSRF guard (CONTRAT.md §0.5).
// Pure, allow-list based: an address is public only when it is positively
// known to be globally routable. Anything malformed, reserved, local, private,
// shared, multicast or documentation is refused.

type Ipv4 = readonly [number, number, number, number];

const DECIMAL_OCTET = /^(0|[1-9]\d{0,2})$/;

function parseIpv4(text: string): Ipv4 | null {
  const parts = text.split(".");
  if (parts.length !== 4) return null;
  const octets: number[] = [];
  for (const part of parts) {
    if (!DECIMAL_OCTET.test(part)) return null;
    const value = Number(part);
    if (value > 255) return null;
    octets.push(value);
  }
  const [a, b, c, d] = octets;
  if (a === undefined || b === undefined || c === undefined || d === undefined) return null;
  return [a, b, c, d];
}

function isPublicIpv4([a, b, c]: Ipv4): boolean {
  if (a === 0 || a === 10 || a === 127) return false;
  if (a >= 224) return false; // multicast, reserved, broadcast
  if (a === 100 && b >= 64 && b <= 127) return false; // CGNAT 100.64/10
  if (a === 169 && b === 254) return false; // link-local, cloud metadata
  if (a === 172 && b >= 16 && b <= 31) return false;
  if (a === 192) {
    if (b === 168) return false;
    if (b === 0 && (c === 0 || c === 2)) return false; // 192.0.0/24, TEST-NET-1
    if (b === 88 && c === 99) return false; // 6to4 relay anycast
  }
  if (a === 198) {
    if (b === 18 || b === 19) return false; // benchmarking
    if (b === 51 && c === 100) return false; // TEST-NET-2
  }
  if (a === 203 && b === 0 && c === 113) return false; // TEST-NET-3
  return true;
}

const HEX_GROUP = /^[0-9a-fA-F]{1,4}$/;

// Eight 16-bit groups, or null when the text is not a valid IPv6 address.
function parseIpv6(text: string): number[] | null {
  if (text === "" || /[^0-9a-fA-F:.]/.test(text)) return null;
  const halves = text.split("::");
  if (halves.length > 2) return null;

  const toGroups = (side: string): number[] | null => {
    if (side === "") return [];
    const out: number[] = [];
    const pieces = side.split(":");
    for (const [index, piece] of pieces.entries()) {
      if (piece.includes(".")) {
        if (index !== pieces.length - 1) return null;
        const v4 = parseIpv4(piece);
        if (v4 === null) return null;
        out.push((v4[0] << 8) | v4[1], (v4[2] << 8) | v4[3]);
      } else {
        if (!HEX_GROUP.test(piece)) return null;
        out.push(parseInt(piece, 16));
      }
    }
    return out;
  };

  const head = toGroups(halves[0] ?? "");
  if (head === null) return null;
  if (halves.length === 1) return head.length === 8 ? head : null;

  const tail = toGroups(halves[1] ?? "");
  if (tail === null) return null;
  const missing = 8 - head.length - tail.length;
  if (missing < 1) return null;
  return [...head, ...new Array<number>(missing).fill(0), ...tail];
}

function embeddedIpv4(high: number, low: number): Ipv4 {
  return [high >> 8, high & 0xff, low >> 8, low & 0xff];
}

function isPublicIpv6(g: readonly number[]): boolean {
  const [g0, g1, g2, g3, g4, g5, g6, g7] = g;
  if (
    g0 === undefined || g1 === undefined || g2 === undefined || g3 === undefined ||
    g4 === undefined || g5 === undefined || g6 === undefined || g7 === undefined
  ) {
    return false;
  }
  // ::ffff:0:0/96, IPv4-mapped: judged as the IPv4 address it carries.
  if (g0 === 0 && g1 === 0 && g2 === 0 && g3 === 0 && g4 === 0 && g5 === 0xffff) {
    return isPublicIpv4(embeddedIpv4(g6, g7));
  }
  // Everything outside 2000::/3 is unspecified, loopback, IPv4-compatible,
  // NAT64, discard, unique-local, link-local, site-local or multicast.
  if ((g0 & 0xe000) !== 0x2000) return false;
  if (g0 === 0x2001 && g1 < 0x0200) return false; // 2001::/23 protocol assignments, Teredo
  if (g0 === 0x2001 && g1 === 0x0db8) return false; // documentation
  if ((g0 & 0xfff0) === 0x3ff0) return false; // 3fff::/20 documentation
  if (g0 === 0x2002) return isPublicIpv4(embeddedIpv4(g1, g2)); // 6to4
  return true;
}

export function isPublicAddress(address: string): boolean {
  const v4 = parseIpv4(address);
  if (v4 !== null) return isPublicIpv4(v4);
  const v6 = parseIpv6(address);
  return v6 !== null && isPublicIpv6(v6);
}

export function isIpLiteral(text: string): boolean {
  return parseIpv4(text) !== null || parseIpv6(text) !== null;
}
