import { describe, expect, test } from "bun:test";
import { isPublicAddress } from "../../src/features/chat/domain/ip-address";

// The SSRF guard's address classifier. Expectations come from the IANA special
// purpose registries (RFC 6890 / RFC 5735 / RFC 4291), not from the code.

describe("IPv4", () => {
  const refused: Array<[string, string]> = [
    ["0.0.0.0", "this host"],
    ["0.1.2.3", "0.0.0.0/8"],
    ["10.0.0.1", "10/8"],
    ["10.255.255.255", "10/8 top"],
    ["100.64.0.1", "CGNAT"],
    ["100.127.255.254", "CGNAT top"],
    ["127.0.0.1", "loopback"],
    ["127.255.255.255", "loopback top"],
    ["169.254.169.254", "link-local / cloud metadata"],
    ["172.16.0.1", "172.16/12"],
    ["172.31.255.255", "172.16/12 top"],
    ["192.0.0.1", "IETF protocol assignments"],
    ["192.0.2.1", "TEST-NET-1"],
    ["192.88.99.1", "6to4 relay anycast"],
    ["192.168.1.1", "192.168/16"],
    ["198.18.0.1", "benchmarking"],
    ["198.19.255.255", "benchmarking top"],
    ["198.51.100.7", "TEST-NET-2"],
    ["203.0.113.9", "TEST-NET-3"],
    ["224.0.0.1", "multicast"],
    ["239.255.255.255", "multicast top"],
    ["240.0.0.1", "reserved"],
    ["255.255.255.255", "broadcast"],
  ];
  for (const [address, why] of refused) {
    test(`refuses ${address} (${why})`, () => expect(isPublicAddress(address)).toBe(false));
  }

  const accepted = ["8.8.8.8", "1.1.1.1", "93.184.216.34", "100.63.255.255", "100.128.0.1", "172.15.255.255", "172.32.0.1", "198.17.255.255", "198.20.0.1", "223.255.255.255"];
  for (const address of accepted) {
    test(`accepts ${address}`, () => expect(isPublicAddress(address)).toBe(true));
  }

  test("refuses malformed IPv4", () => {
    for (const bad of ["", "1.2.3", "1.2.3.4.5", "256.1.1.1", "1.2.3.-4", "01.2.3.4", "a.b.c.d", "1.2.3.4 "]) {
      expect(isPublicAddress(bad)).toBe(false);
    }
  });
});

describe("IPv6", () => {
  const refused: Array<[string, string]> = [
    ["::", "unspecified"],
    ["::1", "loopback"],
    ["0:0:0:0:0:0:0:1", "loopback, long form"],
    ["fc00::1", "unique local"],
    ["fd12:3456:789a::1", "unique local fd"],
    ["fe80::1", "link-local"],
    ["febf::1", "link-local top"],
    ["fec0::1", "site-local (deprecated)"],
    ["ff02::1", "multicast"],
    ["ff00::", "multicast bottom"],
    ["::ffff:127.0.0.1", "mapped loopback, dotted"],
    ["::ffff:7f00:1", "mapped loopback, hex"],
    ["::ffff:10.0.0.1", "mapped private"],
    ["::ffff:169.254.169.254", "mapped metadata"],
    ["::ffff:192.168.0.1", "mapped 192.168"],
    ["::127.0.0.1", "IPv4-compatible loopback"],
    ["64:ff9b::7f00:1", "NAT64 of loopback"],
    ["64:ff9b::a00:1", "NAT64 of 10.0.0.1"],
    ["2001:db8::1", "documentation"],
    ["2001::1", "Teredo"],
    ["2002:7f00:1::1", "6to4 of 127.0.0.1"],
    ["2002:a00:1::1", "6to4 of 10.0.0.1"],
    ["2002:c0a8:101::1", "6to4 of 192.168.1.1"],
    ["100::1", "discard-only"],
    ["3fff::1", "documentation (3fff::/20)"],
    ["::2", "IPv4-compatible space"],
    ["1::1", "outside global unicast"],
    ["[::1]", "bracketed form is not an address"],
    ["fe80::1%eth0", "zone id"],
    ["1:2:3:4:5:6:7:8:9", "too many groups"],
    ["1::2::3", "two compression marks"],
    ["gggg::1", "bad hex"],
    ["12345::1", "group too long"],
  ];
  for (const [address, why] of refused) {
    test(`refuses ${address} (${why})`, () => expect(isPublicAddress(address)).toBe(false));
  }

  const accepted: Array<[string, string]> = [
    ["2606:4700:4700::1111", "Cloudflare DNS"],
    ["2001:4860:4860::8888", "Google DNS"],
    ["2a00:1450:4007:80f::200e", "global unicast"],
    ["::ffff:8.8.8.8", "mapped public IPv4"],
    ["::ffff:808:808", "mapped public IPv4, hex"],
    ["2002:808:808::1", "6to4 of public 8.8.8.8"],
  ];
  for (const [address, why] of accepted) {
    test(`accepts ${address} (${why})`, () => expect(isPublicAddress(address)).toBe(true));
  }
});
