import { lookup } from "node:dns/promises";
import type { DnsResolver } from "../application/fetch-ports";

// The system resolver (so /etc/hosts and the platform's search rules apply the
// same way they will for the connection). Returns A and AAAA records together.
export const systemDnsResolver: DnsResolver = {
  async resolveAll(hostname) {
    const records = await lookup(hostname, { all: true, verbatim: true });
    return records.map((record) => record.address);
  },
};
