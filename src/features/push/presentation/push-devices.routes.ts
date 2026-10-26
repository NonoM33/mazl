import type { Hono, MiddlewareHandler } from "hono";
import { z } from "zod";
import type { AppVariables } from "../../../shared/http/middleware";
import { parseBody } from "../../../shared/http/validation";
import type { PushDeviceStore } from "../application/ports";

// The app declares its APNs token at every signed-in launch and withdraws it
// at sign-out. A token is hexadecimal (APNs gives 32 bytes today; up to 100 allowed).

const tokenSchema = z
  .string()
  .regex(/^[0-9a-fA-F]{64,200}$/, "token: hexadecimal, 64 to 200 characters")
  .transform((token) => token.toLowerCase());

const registerSchema = z.object({ token: tokenSchema, environment: z.enum(["production", "sandbox"]) });
const unregisterSchema = z.object({ token: tokenSchema });

export interface PushDevicesRouteDeps {
  readonly authenticate: MiddlewareHandler<{ Variables: AppVariables }>;
  readonly devices: PushDeviceStore;
}

export function registerPushDevicesRoutes(app: Hono<{ Variables: AppVariables }>, deps: PushDevicesRouteDeps): void {
  app.put("/api/push/devices", deps.authenticate, async (c) => {
    const parsed = await parseBody(registerSchema, c);
    if (!parsed.ok) return c.json({ success: false, error: parsed.error }, 400);
    try {
      await deps.devices.register(c.get("userId"), parsed.data.token, parsed.data.environment);
      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Push device registration failed:", error instanceof Error ? error.name : "unknown");
      return c.json({ success: false, error: "Failed to register the device" }, 500);
    }
  });

  app.delete("/api/push/devices", deps.authenticate, async (c) => {
    const parsed = await parseBody(unregisterSchema, c);
    if (!parsed.ok) return c.json({ success: false, error: parsed.error }, 400);
    try {
      await deps.devices.unregister(c.get("userId"), parsed.data.token);
      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Push device withdrawal failed:", error instanceof Error ? error.name : "unknown");
      return c.json({ success: false, error: "Failed to withdraw the device" }, 500);
    }
  });
}
