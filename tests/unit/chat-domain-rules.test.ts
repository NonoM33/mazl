import { describe, expect, test } from "bun:test";
import { parseWaveform, WAVEFORM_POINTS } from "../../src/features/chat/domain/waveform";
import { firstHttpUrl } from "../../src/features/chat/domain/url-extract";
import { parseOpenGraph } from "../../src/features/chat/domain/open-graph";
import { parseByteRange } from "../../src/features/chat/domain/byte-range";
import {
  ALLOWED_REACTIONS, UNSEND_WINDOW_MS, canUnsend, isAllowedReaction, replyPreview,
} from "../../src/features/chat/domain/message-rules";

describe("waveform (CONTRAT.md §1: 48 integers, 0-100)", () => {
  const good = Array.from({ length: 48 }, (_, i) => (i * 2) % 101);
  test("a JSON array of 48 ints in range", () => expect(parseWaveform(JSON.stringify(good))).toEqual(good));
  test("bounds 0 and 100 are valid", () => {
    expect(parseWaveform(JSON.stringify(new Array<number>(48).fill(0)))).not.toBeNull();
    expect(parseWaveform(JSON.stringify(new Array<number>(48).fill(100)))).not.toBeNull();
  });
  test("exactly 48 points", () => expect(WAVEFORM_POINTS).toBe(48));
  const bad: Array<[string, string]> = [
    ["not JSON", "[1,2"],
    ["47 values", JSON.stringify(good.slice(0, 47))],
    ["49 values", JSON.stringify([...good, 1])],
    ["101", JSON.stringify([...good.slice(1), 101])],
    ["-1", JSON.stringify([...good.slice(1), -1])],
    ["a float", JSON.stringify([...good.slice(1), 1.5])],
    ["a string", JSON.stringify([...good.slice(1), "3"])],
    ["null", JSON.stringify([...good.slice(1), null])],
    ["an object", JSON.stringify({ length: 48 })],
    ["empty", ""],
  ];
  for (const [label, raw] of bad) test(`refuses ${label}`, () => expect(parseWaveform(raw)).toBeNull());
});

describe("firstHttpUrl", () => {
  test("finds the first http(s) URL", () => {
    expect(firstHttpUrl("regarde https://example.com/a?b=1 et http://other.example")).toBe("https://example.com/a?b=1");
  });
  test("trims trailing punctuation", () => {
    expect(firstHttpUrl("va sur https://example.com/page.")).toBe("https://example.com/page");
    expect(firstHttpUrl("(https://example.com/x)")).toBe("https://example.com/x");
    expect(firstHttpUrl("https://example.com/x, puis")).toBe("https://example.com/x");
    expect(firstHttpUrl("https://example.com/x?!")).toBe("https://example.com/x");
  });
  test("scheme is case-insensitive", () => expect(firstHttpUrl("HTTPS://Example.com/A")).toBe("HTTPS://Example.com/A"));
  test("ignores other schemes and bare domains", () => {
    expect(firstHttpUrl("ftp://example.com file:///etc/passwd javascript:alert(1) www.example.com example.com")).toBeNull();
  });
  test("none", () => {
    expect(firstHttpUrl("")).toBeNull();
    expect(firstHttpUrl("Salut, on se voit jeudi ?")).toBeNull();
  });
  test("a very long run is bounded", () => {
    const url = firstHttpUrl(`http://example.com/${"a".repeat(5000)}`);
    expect(url === null || url.length <= 2048).toBe(true);
  });
});

describe("parseOpenGraph", () => {
  test("og tags, any attribute order and quoting", () => {
    const html = `<html><head>
      <meta property="og:title" content="Un titre">
      <meta content='Une description' property='og:description'>
      <META PROPERTY=og:image CONTENT=https://cdn.example.com/i.png>
      <meta property="og:site_name" content="Exemple">
      <title>Ignoré</title></head></html>`;
    expect(parseOpenGraph(html)).toEqual({
      title: "Un titre", description: "Une description", imageUrl: "https://cdn.example.com/i.png", siteName: "Exemple",
    });
  });
  test("falls back to <title>, meta description and twitter tags", () => {
    const html = `<head><title>  Page \n titre </title><meta name="description" content="Desc"><meta name="twitter:image" content="/img.jpg"></head>`;
    expect(parseOpenGraph(html)).toEqual({ title: "Page titre", description: "Desc", imageUrl: "/img.jpg" });
  });
  test("og wins over the fallbacks", () => {
    const html = `<title>T</title><meta name="description" content="D"><meta property="og:title" content="OT"><meta property="og:description" content="OD">`;
    const og = parseOpenGraph(html);
    expect([og.title, og.description]).toEqual(["OT", "OD"]);
  });
  test("strips HTML, decodes entities, drops control characters", () => {
    const html = `<meta property="og:title" content="Caf&eacute; &amp; <b>co</b> &lt;script&gt;alert(1)&lt;/script&gt; &#233;&#x41;\u0007\u0000x">`;
    const title = parseOpenGraph(html).title ?? "";
    expect(title).not.toMatch(/[<>]/);
    expect(title).not.toMatch(/[\u0000-\u001f]/);
    expect(title).toContain("& co");
    expect(title).toContain("éA");
  });
  test("caps lengths", () => {
    const long = "x".repeat(2000);
    const og = parseOpenGraph(`<meta property="og:title" content="${long}"><meta property="og:description" content="${long}"><meta property="og:site_name" content="${long}">`);
    expect(og.title?.length).toBeLessThanOrEqual(200);
    expect(og.description?.length).toBeLessThanOrEqual(300);
    expect(og.siteName?.length).toBeLessThanOrEqual(100);
  });
  test("ignores tags inside comments, scripts and styles", () => {
    const html = `<!-- <meta property="og:title" content="comment"> --><script>var a = '<meta property="og:title" content="script">';</script><meta property="og:title" content="real">`;
    expect(parseOpenGraph(html).title).toBe("real");
  });
  test("an overlong image URL is dropped", () => {
    expect(parseOpenGraph(`<meta property="og:image" content="https://e.com/${"a".repeat(3000)}">`).imageUrl).toBeUndefined();
  });
  test("nothing useful gives an empty result", () => {
    expect(parseOpenGraph("<html><body>hello</body></html>")).toEqual({});
    expect(parseOpenGraph("")).toEqual({});
  });
  test("adversarial input stays fast", () => {
    const started = Date.now();
    parseOpenGraph(`<meta ${"a=".repeat(100_000)}`);
    parseOpenGraph("<title>".repeat(50_000));
    parseOpenGraph("<!--".repeat(50_000));
    expect(Date.now() - started).toBeLessThan(1500);
  });
});

describe("parseByteRange", () => {
  test("a bounded range", () => expect(parseByteRange("bytes=0-99", 1000)).toEqual({ start: 0, end: 99 }));
  test("open-ended", () => expect(parseByteRange("bytes=900-", 1000)).toEqual({ start: 900, end: 999 }));
  test("suffix", () => expect(parseByteRange("bytes=-100", 1000)).toEqual({ start: 900, end: 999 }));
  test("end past the file is clamped", () => expect(parseByteRange("bytes=0-99999", 1000)).toEqual({ start: 0, end: 999 }));
  test("start past the end is unsatisfiable", () => expect(parseByteRange("bytes=1000-", 1000)).toBe("unsatisfiable"));
  test("start after end is ignored", () => expect(parseByteRange("bytes=50-10", 1000)).toBeNull());
  test("no header, other units, several ranges and garbage are ignored (full body)", () => {
    for (const header of [undefined, "", "items=0-1", "bytes=0-1,5-6", "bytes=abc", "bytes=-", "bytes=--1"]) {
      expect(parseByteRange(header, 1000)).toBeNull();
    }
  });
});

describe("message rules", () => {
  test("reactions are exactly the six of the contract", () => {
    expect([...ALLOWED_REACTIONS]).toEqual(["❤️", "😂", "😮", "😢", "😡", "👍"]);
    expect(isAllowedReaction("❤️")).toBe(true);
    expect(isAllowedReaction("❤")).toBe(false); // without the variation selector
    expect(isAllowedReaction("🔥")).toBe(false);
    expect(isAllowedReaction("")).toBe(false);
  });
  test("unsend: the author, within 15 minutes", () => {
    const created = new Date("2026-10-23T10:00:00Z");
    const at = (ms: number) => new Date(created.getTime() + ms);
    expect(UNSEND_WINDOW_MS).toBe(15 * 60 * 1000);
    expect(canUnsend({ senderId: 7, userId: 7, createdAt: created, now: at(0) })).toBe("allowed");
    expect(canUnsend({ senderId: 7, userId: 7, createdAt: created, now: at(UNSEND_WINDOW_MS) })).toBe("allowed");
    expect(canUnsend({ senderId: 7, userId: 7, createdAt: created, now: at(UNSEND_WINDOW_MS + 1) })).toBe("too_late");
    expect(canUnsend({ senderId: 7, userId: 8, createdAt: created, now: at(1000) })).toBe("not_author");
  });
  test("reply preview", () => {
    expect(replyPreview({ type: "text", content: "On se voit jeudi ?", unsent: false })).toBe("On se voit jeudi ?");
    expect(replyPreview({ type: "text", content: "x".repeat(200), unsent: false })).toBe(`${"x".repeat(79)}…`);
    expect(replyPreview({ type: "photo", content: "belle vue", unsent: false })).toBe("Photo");
    expect(replyPreview({ type: "voice", content: "", unsent: false })).toBe("Message vocal");
    expect(replyPreview({ type: "text", content: "secret", unsent: true })).toBe("Message retiré");
  });
  test("reply preview never splits a surrogate pair", () => {
    const preview = replyPreview({ type: "text", content: "😀".repeat(100), unsent: false });
    expect(Array.from(preview).length).toBeLessThanOrEqual(80);
    expect(preview).not.toMatch(/[\ud800-\udbff]$/);
  });
});

describe("parseOpenGraph on a hostile title", () => {
  test("a huge <title> of angle brackets stays fast", () => {
    const started = Date.now();
    parseOpenGraph(`<title>${"<".repeat(400_000)}</title>`);
    parseOpenGraph(`<meta property="og:title" content="${"<".repeat(1500)}">`);
    expect(Date.now() - started).toBeLessThan(1000);
  });
});
