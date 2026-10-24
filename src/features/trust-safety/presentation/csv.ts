import type { TransparencyDto } from "./dto";

// RFC 4180: CRLF line ends, fields with a comma, a quote or a line break are
// quoted and their quotes doubled.
function field(value: string | number | null): string {
  const text = value === null ? "" : String(value);
  return /[",\r\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

export function toCsv(rows: readonly (readonly (string | number | null)[])[]): string {
  return rows.map((row) => row.map(field).join(",")).join("\r\n") + "\r\n";
}

function section(name: string, values: Readonly<Record<string, number>>): (string | number)[][] {
  return Object.entries(values).map(([key, value]) => [name, key, value]);
}

export function transparencyCsv(report: TransparencyDto): string {
  return toCsv([
    ["section", "key", "value"],
    ["period", "from", report.from],
    ["period", "to", report.to],
    ...section("notices_received", report.noticesReceived),
    ["notices", "actioned", report.noticesActioned],
    ["notices", "median_handling_hours", report.medianHandlingHours],
    ...section("sanctions_by_kind", report.sanctionsByKind),
    ...section("sanctions_by_ground", report.sanctionsByGround),
    ["appeals", "received", report.appealsReceived],
    ["appeals", "overturned", report.appealsOverturned],
    ["appeals", "median_hours", report.medianAppealHours],
    ...section("authority_requests", report.authorityRequests),
    ["automated", "decisions", report.automatedDecisions],
  ]);
}
