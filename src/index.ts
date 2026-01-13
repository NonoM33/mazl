import { Hono } from "hono";
import { serveStatic } from "hono/bun";
import { cors } from "hono/cors";
import { initDb, addToWaitlist, confirmEmail, getConfirmedCount, getTotalCount } from "./db";
import { sendConfirmationEmail } from "./email";

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

    // Generate token
    const token = crypto.randomUUID().replace(/-/g, "") + crypto.randomUUID().replace(/-/g, "");

    // Add to database
    const result = await addToWaitlist(email, token);
    if (!result.success) {
      return c.json({ success: false, error: result.error }, 409);
    }

    // Send confirmation email
    const emailResult = await sendConfirmationEmail(email, token);
    if (!emailResult.success) {
      console.error("Failed to send email:", emailResult.error);
      // Still return success - email is saved
    }

    return c.json({ 
      success: true, 
      message: "Check tes emails pour confirmer ton inscription !" 
    });
  } catch (error: any) {
    console.error("Subscribe error:", error);
    return c.json({ success: false, error: "Erreur serveur" }, 500);
  }
});

app.get("/api/confirm", async (c) => {
  const token = c.req.query("token");

  if (!token) {
    return c.redirect("/?error=token_missing");
  }

  const result = await confirmEmail(token);

  if (result) {
    return c.redirect("/?confirmed=true");
  } else {
    return c.redirect("/?error=invalid_token");
  }
});

app.get("/api/count", async (c) => {
  try {
    const confirmed = await getConfirmedCount();
    const total = await getTotalCount();
    return c.json({ confirmed, total });
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
