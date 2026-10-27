// A fake Anthropic Messages API for the integration tests: records every request
// (headers and body) and answers according to the mode set by the test.
//   POST /v1/messages     the call of the concierge assistant
//   GET  /__test/requests everything received so far
//   POST /__test/mode     { "mode": "ok" | "invalid" | "error" | "options" }
//   POST /__test/reset    forget the requests, back to "ok"

export interface RecordedRequest {
  readonly headers: Record<string, string>;
  readonly body: unknown;
}

export type FakeMode = "ok" | "options" | "invalid" | "error";

const reply = (text: string): Response => Response.json({ id: "msg_example", type: "message", role: "assistant", content: [{ type: "text", text }], stop_reason: "end_turn" });

export function createFakeAnthropic(port: number) {
  const requests: RecordedRequest[] = [];
  let mode: FakeMode = "ok";
  const server = Bun.serve({
    port,
    hostname: "127.0.0.1",
    async fetch(request) {
      const url = new URL(request.url);
      if (request.method === "POST" && url.pathname === "/v1/messages") {
        requests.push({ headers: Object.fromEntries(request.headers.entries()), body: await request.json() });
        if (mode === "error") return Response.json({ type: "error", error: { type: "overloaded_error", message: "Overloaded" } }, { status: 529 });
        if (mode === "invalid") return reply("Voici mes idées, sans JSON du tout.");
        if (mode === "options") {
          return reply(JSON.stringify({ reply: "Voici trois idées pour votre soirée.", options: [1, 2, 3].map((n) => ({ title: `Idée ${String(n)}`, details: "Un lieu calme, à confirmer par l'équipe.", priceHint: "autour de 80 euros, à confirmer" })) }));
        }
        return reply(`Bien sûr :\n${JSON.stringify({ reply: "Voici une idée pour votre soirée.", options: [{ title: "Table calme dans le Marais", details: "Restaurant casher, à confirmer par l'équipe.", priceHint: "autour de 90 euros pour deux, à confirmer" }] })}`);
      }
      if (request.method === "GET" && url.pathname === "/__test/requests") return Response.json(requests);
      if (request.method === "POST" && url.pathname === "/__test/mode") {
        mode = ((await request.json()) as { mode: FakeMode }).mode;
        return Response.json({ mode });
      }
      if (request.method === "POST" && url.pathname === "/__test/reset") {
        requests.length = 0;
        mode = "ok";
        return Response.json({ ok: true });
      }
      return new Response("not found", { status: 404 });
    },
  });
  return { server, requests };
}
