import { createMiddleware } from "hono/factory";
import { verifyJWT, extractBearerToken } from "../../auth";

// Variables shared across the Hono application context.
export type AppVariables = {
  userId: number;
};

// User authentication middleware. Reads the Bearer token, verifies the JWT, and
// stores the resolved user id in the context for downstream handlers. On failure
// it returns exactly the same 401 responses the handlers used to return inline.
export const requireAuth = createMiddleware<{ Variables: AppVariables }>(async (c, next) => {
  const token = extractBearerToken(c.req.header("Authorization"));
  if (!token) {
    return c.json({ success: false, error: "No token provided" }, 401);
  }

  const payload = verifyJWT(token);
  if (!payload) {
    return c.json({ success: false, error: "Invalid token" }, 401);
  }

  c.set("userId", parseInt(payload.sub));
  await next();
});
