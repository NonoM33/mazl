import { describe, expect, test } from "bun:test";
import { toCsv } from "../../src/features/trust-safety/presentation/csv";

describe("CSV (RFC 4180)", () => {
  test("CRLF line ends, header kept, null is an empty field", () => {
    expect(toCsv([["a", "b"], ["1", null]])).toBe("a,b\r\n1,\r\n");
  });
  test("fields with a comma, a quote or a line break are quoted, quotes doubled", () => {
    expect(toCsv([["x,y", 'say "hi"', "line\nbreak", "plain"]])).toBe('"x,y","say ""hi""","line\nbreak",plain\r\n');
  });
});
