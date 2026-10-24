import { isIP } from "node:net";

// What the phone shows of the address a sign-in request came from: enough to
// notice « that is not my network », never the full address (security review
// B6). IPv4 loses its last part, IPv6 keeps its first three groups.
export function maskedAddress(address: string): string | null {
  const plain = address.startsWith("::ffff:") && isIP(address.slice(7)) === 4 ? address.slice(7) : address;
  if (isIP(plain) === 4) return `${plain.split(".").slice(0, 3).join(".")}.x`;
  if (isIP(plain) !== 6) return null;
  const groups = plain.split("::")[0]?.split(":").filter((group) => group.length > 0) ?? [];
  return `${groups.slice(0, 3).join(":")}::`;
}
