// Standalone fake OpenPanel for the integration tests: FAKE_OPENPANEL_PORT.
// Records every POST /track (headers and body); GET /__test/requests lists them.

interface Recorded {
  readonly headers: Record<string, string>;
  readonly body: unknown;
}

const port = Number(process.env.FAKE_OPENPANEL_PORT ?? 12114);
const requests: Recorded[] = [];

const server = Bun.serve({
  port,
  hostname: "127.0.0.1",
  async fetch(request) {
    const url = new URL(request.url);
    if (request.method === "POST" && url.pathname === "/track") {
      requests.push({ headers: Object.fromEntries(request.headers.entries()), body: await request.json() });
      return Response.json({ deviceId: "fake" }, { status: 202 });
    }
    if (request.method === "GET" && url.pathname === "/__test/requests") return Response.json(requests);
    return new Response("not found", { status: 404 });
  },
});
console.log(`fake OpenPanel listening on ${server.url}`);
