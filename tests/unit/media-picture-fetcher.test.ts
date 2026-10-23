import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { googlePictureFetcher } from "../../src/features/media/infra/google-picture-fetcher";
import { PictureImportError } from "../../src/features/media/domain/errors";

// The host allow-list is the service's job (tested there); this adapter must
// bound time and size and must not follow redirects off the allow-listed host.

let server: ReturnType<typeof Bun.serve>;
let base: string;

beforeAll(() => {
  server = Bun.serve({
    port: 0,
    async fetch(req) {
      const path = new URL(req.url).pathname;
      if (path === "/ok") return new Response(new Uint8Array([1, 2, 3, 4]));
      if (path === "/big-header") return new Response(new Uint8Array(2048), { headers: { "content-length": "2048" } });
      if (path === "/big-stream") {
        const stream = new ReadableStream<Uint8Array>({
          start(controller) {
            for (let i = 0; i < 10; i++) controller.enqueue(new Uint8Array(512));
            controller.close();
          },
        });
        return new Response(stream);
      }
      if (path === "/redirect") return Response.redirect("http://169.254.169.254/latest/meta-data", 302);
      if (path === "/slow") {
        await Bun.sleep(1000);
        return new Response("late");
      }
      return new Response("nope", { status: 404 });
    },
  });
  base = `http://127.0.0.1:${server.port}`;
});

afterAll(() => server.stop(true));

const limits = { timeoutMs: 300, maxBytes: 1024 };
const reasonOf = async (path: string): Promise<string | undefined> => {
  const error = await googlePictureFetcher.fetch(new URL(base + path), limits).catch((e: unknown) => e);
  return error instanceof PictureImportError ? error.reason : undefined;
};

describe("google picture fetcher", () => {
  test("returns the body", async () => {
    expect([...(await googlePictureFetcher.fetch(new URL(`${base}/ok`), limits))]).toEqual([1, 2, 3, 4]);
  });
  test("refuses an oversized declared length", async () => {
    expect(await reasonOf("/big-header")).toBe("too_large");
  });
  test("refuses an oversized stream without a declared length", async () => {
    expect(await reasonOf("/big-stream")).toBe("too_large");
  });
  test("does not follow redirects", async () => {
    expect(await reasonOf("/redirect")).toBe("fetch_failed");
  });
  test("gives up after the timeout", async () => {
    expect(await reasonOf("/slow")).toBe("fetch_failed");
  });
  test("a non-2xx answer is a failure", async () => {
    expect(await reasonOf("/missing")).toBe("fetch_failed");
  });
});
