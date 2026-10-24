import { createMiddleware } from "hono/factory";
import { verifyJWT, extractBearerToken } from "../../auth";
import { isAccountActive } from "./account-state";

// Variables shared across the Hono application context.
export type AppVariables = {
  userId: number;
};

export type AccountActiveCheck = (userId: number) => Promise<boolean>;

// User authentication middleware. Reads the Bearer token, verifies the JWT,
// checks that the account still exists and is not banned, and stores the user
// id in the context for downstream handlers.
export function createRequireAuth(accountActive: AccountActiveCheck) {
  return createMiddleware<{ Variables: AppVariables }>(async (c, next) => {
    const token = extractBearerToken(c.req.header("Authorization"));
    if (!token) {
      return c.json({ success: false, error: "No token provided" }, 401);
    }

    const payload = verifyJWT(token);
    if (!payload) {
      return c.json({ success: false, error: "Invalid token" }, 401);
    }

    const userId = Number(payload.sub);
    if (!(await accountActive(userId))) {
      return c.json({ success: false, error: "account_disabled" }, 401);
    }

    c.set("userId", userId);
    await next();
  });
}

export const requireAuth = createRequireAuth(isAccountActive);
