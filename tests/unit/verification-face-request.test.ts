import { describe, expect, test } from "bun:test";
import {
  MAX_BODY_BYTES,
  MAX_FRAME_BYTES,
  parseFaceSubmission,
  readMultipartCapped,
} from "../../src/features/verification/presentation/face-request";

const SESSION = "11111111-2222-4333-8444-555555555555";

function formWith(frames: Record<string, Uint8Array | string>, session: string | null = SESSION): FormData {
  const form = new FormData();
  if (session !== null) form.set("session_id", session);
  for (const [key, value] of Object.entries(frames)) {
    if (typeof value === "string") form.set(key, value);
    else form.set(key, new Blob([value], { type: "image/jpeg" }), `${key}.jpg`);
  }
  return form;
}

describe("readMultipartCapped", () => {
  test("parses a small form", async () => {
    const req = new Request("http://x/submit", { method: "POST", body: formWith({ frame_0: new Uint8Array([1, 2, 3]) }) });
    const form = await readMultipartCapped(req, 1024 * 1024);
    expect(form).toBeInstanceOf(FormData);
    expect((form as FormData).get("session_id")).toBe(SESSION);
  });

  test("a body over the cap is refused even without a Content-Length", async () => {
    const chunk = new Uint8Array(64 * 1024);
    let sent = 0;
    const stream = new ReadableStream<Uint8Array>({
      pull(controller) {
        if (sent >= 40) return controller.close();
        sent++;
        controller.enqueue(chunk);
      },
    });
    const req = new Request("http://x/submit", {
      method: "POST",
      headers: { "Content-Type": "multipart/form-data; boundary=zzz" },
      body: stream,
      duplex: "half",
    } as RequestInit);
    expect(req.headers.get("content-length")).toBeNull();
    expect(await readMultipartCapped(req, 1024 * 1024)).toBe("too_large");
  });

  test("a body exactly at the cap is read", async () => {
    const body = new Uint8Array(10);
    const req = new Request("http://x/submit", { method: "POST", headers: { "Content-Type": "multipart/form-data; boundary=zzz" }, body });
    expect(await readMultipartCapped(req, 10)).toBe("malformed"); // read fully, then not a valid form
    expect(await readMultipartCapped(new Request("http://x/submit", { method: "POST", headers: { "Content-Type": "multipart/form-data; boundary=zzz" }, body }), 9)).toBe("too_large");
  });

  test("bytes that are not multipart are malformed", async () => {
    const req = new Request("http://x/submit", {
      method: "POST",
      headers: { "Content-Type": "multipart/form-data; boundary=zzz" },
      body: "not a form",
    });
    expect(await readMultipartCapped(req, 1024)).toBe("malformed");
  });

  test("no body at all is malformed", async () => {
    expect(await readMultipartCapped(new Request("http://x/submit", { method: "POST" }), 1024)).toBe("malformed");
  });

  test("the cap leaves room for the largest legal submission", () => {
    expect(MAX_BODY_BYTES).toBeGreaterThan(8 * MAX_FRAME_BYTES);
  });
});

describe("parseFaceSubmission", () => {
  const bytes = (n: number) => new Uint8Array(n).fill(7);

  test("orders frames by their index, not by arrival", async () => {
    const form = formWith({ frame_2: bytes(3), frame_0: bytes(1), frame_1: bytes(2) });
    const r = await parseFaceSubmission(form);
    expect(r.ok).toBe(true);
    if (r.ok) {
      expect(r.sessionId).toBe(SESSION);
      expect(r.frames.map((f) => f.length)).toEqual([1, 2, 3]);
    }
  });

  test("a gap in the numbering yields no frames (wrong_frame_count downstream)", async () => {
    const r = await parseFaceSubmission(formWith({ frame_0: bytes(1), frame_2: bytes(1) }));
    expect(r).toEqual({ ok: true, sessionId: SESSION, frames: [] });
  });

  test("unrelated fields are ignored", async () => {
    const r = await parseFaceSubmission(formWith({ frame_0: bytes(1), note: "hello", frame_x: "nope" }));
    expect(r.ok && r.frames.length).toBe(1);
  });

  test("a missing or empty session_id is a 400", async () => {
    expect(await parseFaceSubmission(formWith({ frame_0: bytes(1) }, null))).toEqual({ ok: false, status: 400, error: "session_id is required" });
    expect((await parseFaceSubmission(formWith({ frame_0: bytes(1) }, ""))).ok).toBe(false);
  });

  test("a frame that is plain text instead of a file is a 400", async () => {
    const r = await parseFaceSubmission(formWith({ frame_0: "text" }));
    expect(r).toEqual({ ok: false, status: 400, error: "frame_0 must be a file" });
  });

  test("a frame over 2 MB is a 413, exactly 2 MB is accepted", async () => {
    expect(await parseFaceSubmission(formWith({ frame_0: bytes(MAX_FRAME_BYTES + 1) }))).toEqual({ ok: false, status: 413, error: "frame_too_large" });
    expect((await parseFaceSubmission(formWith({ frame_0: bytes(MAX_FRAME_BYTES) }))).ok).toBe(true);
  });

  test("more than eight frames is a 400", async () => {
    const many: Record<string, Uint8Array> = {};
    for (let i = 0; i < 9; i++) many[`frame_${i}`] = bytes(1);
    expect(await parseFaceSubmission(formWith(many))).toEqual({ ok: false, status: 400, error: "too_many_frames" });
  });
});
