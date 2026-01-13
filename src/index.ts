import { Hono } from "hono";
import { serveStatic } from "hono/bun";
import { cors } from "hono/cors";
import { initDb, addToWaitlist, getTotalCount } from "./db";

const app = new Hono();

// CORS
app.use("/api/*", cors());

// Static files
app.use("/*", serveStatic({ root: "./public" }));

// API Routes
app.post("/api/subscribe", async (c) => {
  try {
    const { email } = await c.req.json();

    // Validate email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!email || !emailRegex.test(email)) {
      return c.json({ success: false, error: "Email invalide" }, 400);
    }

    // Add directly to database (no double opt-in)
    const result = await addToWaitlist(email);
    if (!result.success) {
      return c.json({ success: false, error: result.error }, 409);
    }

    return c.json({ 
      success: true, 
      message: "Bienvenue sur la waitlist MZL !" 
    });
  } catch (error: any) {
    console.error("Subscribe error:", error);
    return c.json({ success: false, error: "Erreur serveur" }, 500);
  }
});

app.get("/api/count", async (c) => {
  try {
    const total = await getTotalCount();
    return c.json({ confirmed: total, total });
  } catch (error) {
    return c.json({ confirmed: 0, total: 0 });
  }
});

// Health check
app.get("/api/health", (c) => c.json({ status: "ok" }));

// Initialize and start
const port = parseInt(process.env.PORT || "3000");

initDb()
  .then(() => {
    console.log(`Server running on http://localhost:${port}`);
  })
  .catch((err) => {
    console.error("Database init failed:", err);
  });

export default {
  port,
  fetch: app.fetch,
};
