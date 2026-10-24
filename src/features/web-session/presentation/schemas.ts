import { z } from "zod";

export const powSchema = z.object({
  challenge: z.string().min(1).max(600),
  nonce: z.string().max(32),
});

export const qrBody = z.object({ pow: powSchema });
export const googleBody = z.object({ idToken: z.string().min(1).max(8192), pow: powSchema });
export const appleBody = z.object({ identityToken: z.string().min(1).max(8192), pow: powSchema });
export const scanBody = z.object({ code: z.string().min(1).max(200) });
