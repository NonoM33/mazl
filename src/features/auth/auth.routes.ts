import { Hono } from "hono";
import { verifyGoogleIdToken, verifyAppleIdToken, generateJWT } from "../../auth";
import { upsertUser, getUserProfile, findUserById } from "../../db";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";

// Presentation layer for the AUTH feature. These routes are moved verbatim from
// the monolith (src/index.ts) and mounted under `/api/auth`. Behaviour, payloads
// and status codes are identical to the original inline handlers.
export function registerAuthRoutes(app: Hono<{ Variables: AppVariables }>): void {
  const auth = new Hono<{ Variables: AppVariables }>();

  // Google OAuth - Verify ID token from mobile app
  auth.post("/google", async (c) => {
    try {
      const { idToken, accessToken } = await c.req.json();

      if (!idToken) {
        return c.json({ success: false, error: "ID token required" }, 400);
      }

      // Verify the Google ID token
      const googleUser = await verifyGoogleIdToken(idToken);
      if (!googleUser) {
        return c.json({ success: false, error: "Invalid Google token" }, 401);
      }

      // Create or update user in database
      const { user, isNew } = await upsertUser({
        email: googleUser.email,
        name: googleUser.name,
        picture: googleUser.picture,
        provider: "google",
        providerId: googleUser.sub,
      });

      // Generate JWT token
      const token = generateJWT({
        id: user.id,
        email: user.email,
        name: user.name ?? undefined,
        picture: user.picture ?? undefined,
        provider: "google",
        providerId: googleUser.sub,
      });

      // Get user profile if exists
      const profile = await getUserProfile(user.id);

      return c.json({
        success: true,
        token,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          picture: user.picture,
          provider: user.provider,
          isNew,
          hasProfile: !!profile?.is_complete,
        },
      });
    } catch (error) {
      console.error("Google auth error:", error);
      return c.json({ success: false, error: "Authentication failed" }, 500);
    }
  });

  // Apple OAuth - Verify identity token from mobile app
  auth.post("/apple", async (c) => {
    try {
      const { identityToken, authorizationCode, email, fullName } = await c.req.json();

      if (!identityToken) {
        return c.json({ success: false, error: "Identity token required" }, 400);
      }

      // Verify the Apple identity token
      const appleUser = await verifyAppleIdToken(identityToken);
      if (!appleUser) {
        return c.json({ success: false, error: "Invalid Apple token" }, 401);
      }

      // Apple only sends email on first sign-in, use provided email or token email
      const userEmail = appleUser.email || email || `${appleUser.sub}@privaterelay.appleid.com`;

      // Create or update user in database
      const { user, isNew } = await upsertUser({
        email: userEmail,
        name: fullName,
        provider: "apple",
        providerId: appleUser.sub,
      });

      // Generate JWT token
      const token = generateJWT({
        id: user.id,
        email: user.email,
        name: user.name ?? undefined,
        provider: "apple",
        providerId: appleUser.sub,
      });

      // Get user profile if exists
      const profile = await getUserProfile(user.id);

      return c.json({
        success: true,
        token,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          provider: user.provider,
          isNew,
          hasProfile: !!profile?.is_complete,
        },
      });
    } catch (error) {
      console.error("Apple auth error:", error);
      return c.json({ success: false, error: "Authentication failed" }, 500);
    }
  });

  // Get current user
  auth.get("/me", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      const user = await findUserById(userId);
      if (!user) {
        return c.json({ success: false, error: "User not found" }, 404);
      }

      const profile = await getUserProfile(user.id);

      return c.json({
        success: true,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          picture: user.picture,
          provider: user.provider,
          hasProfile: !!profile?.is_complete,
        },
        profile,
      });
    } catch (error) {
      console.error("Get user error:", error);
      return c.json({ success: false, error: "Failed to get user" }, 500);
    }
  });

  app.route("/api/auth", auth);
}
