// A single `Range: bytes=...` request (RFC 9110 §14), as audio players send to
// seek in a remote MP4. Anything unusual is ignored so the whole body is served.

export interface ByteRange {
  readonly start: number;
  readonly end: number; // inclusive
}

export function parseByteRange(header: string | undefined, size: number): ByteRange | "unsatisfiable" | null {
  const match = /^bytes=(\d*)-(\d*)$/.exec((header ?? "").trim());
  if (match === null) return null;
  const [, first = "", last = ""] = match;
  if (first === "" && last === "") return null;

  if (first === "") {
    const suffix = Number(last);
    if (suffix === 0) return "unsatisfiable";
    return { start: Math.max(0, size - suffix), end: size - 1 };
  }
  const start = Number(first);
  if (start >= size) return "unsatisfiable";
  if (last === "") return { start, end: size - 1 };
  const end = Number(last);
  if (end < start) return null;
  return { start, end: Math.min(end, size - 1) };
}
