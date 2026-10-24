import { describe, expect, test } from "bun:test";
import { csvCell, toCsv } from "../../src/features/admin/admin.csv";

// Spec: OWASP "CSV Injection". A spreadsheet treats a cell whose first character
// is = + - @ TAB or CR as a formula. The cell is neutralised by prefixing a
// single quote; the usual CSV quoting (double the quotes, wrap in quotes) applies on top.
describe("csvCell", () => {
  test.each([
    ['=HYPERLINK("http://evil.example/","x")', `"'=HYPERLINK(""http://evil.example/"",""x"")"`],
    ["=1+1", `"'=1+1"`],
    ["+33123456789", `"'+33123456789"`],
    ["-2+3", `"'-2+3"`],
    ["@SUM(A1:A2)", `"'@SUM(A1:A2)"`],
    ["\t=1+1", `"'\t=1+1"`],
    ["\r=1+1", `"'\r=1+1"`],
  ])("neutralises a formula starting cell %j", (input, expected) => {
    expect(csvCell(input)).toBe(expected);
  });

  test("leaves an ordinary cell alone and still doubles the quotes", () => {
    expect(csvCell("Jeanne Exemple")).toBe('"Jeanne Exemple"');
    expect(csvCell('say "hi"')).toBe('"say ""hi"""');
  });

  test("does not prefix a formula character that is not the first one", () => {
    expect(csvCell("a=b")).toBe('"a=b"');
    expect(csvCell("jeanne-marie@example.com")).toBe('"jeanne-marie@example.com"');
  });

  test("null and undefined become an empty cell", () => {
    expect(csvCell(null)).toBe('""');
    expect(csvCell(undefined)).toBe('""');
  });

  test("numbers and booleans are written as text", () => {
    expect(csvCell(12)).toBe('"12"');
    expect(csvCell(false)).toBe('"false"');
  });
});

describe("toCsv", () => {
  test("writes the header line then one line per row, in header order", () => {
    const csv = toCsv(["email", "name"], [{ name: "Jeanne", email: "j@example.com" }]);
    expect(csv).toBe(`email,name\n"j@example.com","Jeanne"`);
  });
});
