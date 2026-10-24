// CSV writing for admin exports.
//
// Spreadsheets run a cell as a formula when it starts with = + - @ TAB or CR
// (OWASP "CSV Injection"). Member-controlled text (names, e-mails) ends up in
// the exports, so every cell is neutralised with a leading single quote and then
// quoted the usual way (RFC 4180).

const FORMULA_TRIGGER = /^[=+\-@\t\r]/;

export function csvCell(value: unknown): string {
  const text = value === null || value === undefined ? "" : String(value);
  const safe = FORMULA_TRIGGER.test(text) ? `'${text}` : text;
  return `"${safe.replace(/"/g, '""')}"`;
}

export function toCsv(headers: readonly string[], rows: ReadonlyArray<Record<string, unknown>>): string {
  return [headers.join(","), ...rows.map((row) => headers.map((h) => csvCell(row[h])).join(","))].join("\n");
}
