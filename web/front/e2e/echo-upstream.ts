// A stand-in for the API used by web/front/e2e/run.sh: answers every request
// with what it received (method, URL, headers, client address), and echoes
// WebSocket frames on /ws. Lets the check see exactly what the website
// container forwards (Host, X-Forwarded-For, Origin, cookies).
const server = Bun.serve<undefined>({
  port: Number(process.env.PORT ?? 3000),
  fetch(req, bun) {
    const url = new URL(req.url);
    if (url.pathname === "/ws" && bun.upgrade(req)) return undefined;
    const headers: Record<string, string> = {};
    req.headers.forEach((value, name) => { headers[name] = value; });
    return Response.json({ method: req.method, path: url.pathname, query: url.search, headers, peer: bun.requestIP(req)?.address ?? null }, {
      headers: { "X-Echo": "1" },
    });
  },
  websocket: {
    message(ws, message) {
      ws.send(`echo:${typeof message === "string" ? message : message.toString()}`);
    },
  },
});
console.log(`echo upstream on ${server.port}`);
