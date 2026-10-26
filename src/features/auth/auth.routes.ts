import { Hono } from "hono";
import { verifyGoogleIdToken, verifyAppleIdToken, generateJWT } from "../../auth";
import { upsertUser, getUserProfile, findUserById, getOwnPhotoUrls } from "../../db";
import { missingProfileFields } from "../profile/domain/profile-completeness";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";
import { createIpRateLimiter } from "../../shared/http/rate-limit";
import type { AppleSignInPort } from "./apple/apple-sign-in";

// Sign-in is public: limit it per client address so that a stolen or guessed
// token cannot be tried in bulk.
const signInLimiter = createIpRateLimiter({ max: 30, windowMs: 15 * 60_000 });

const accountDisabled = { success: false, error: "account_disabled" } as const;
const isString = (value: unknown): value is string => typeof value === "string" && value.length > 0;
const NAME_MAX = 100;

// Presentation layer for the AUTH feature. These routes are moved verbatim from
// the monolith (src/index.ts) and mounted under `/api/auth`. Behaviour, payloads
// and status codes are identical to the original inline handlers.
export function registerAuthRoutes(app: Hono<{ Variables: AppVariables }>, appleSignIn: AppleSignInPort): void {
  const auth = new Hono<{ Variables: AppVariables }>();

  // Google OAuth - Verify ID token from mobile app
  auth.post("/google", signInLimiter, async (c) => {
    try {
      const body: unknown = await c.req.json().catch(() => null);
      const idToken = typeof body === "object" && body !== null ? (body as Record<string, unknown>).idToken : undefined;

      if (!isString(idToken)) {
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
      if (user.is_active === false) return c.json(accountDisabled, 403);

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
      const row = await getUserProfile(user.id);
      // The app reads its own photos here (profile view, completion card).
      const profile = row ? { ...row, photos: await getOwnPhotoUrls(user.id) } : null;

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
          hasProfile: !!row?.is_complete,
        },
      });
    } catch (error) {
      console.error("Google auth error:", error);
      return c.json({ success: false, error: "Authentication failed" }, 500);
    }
  });

  // Apple OAuth - Verify identity token from mobile app
  auth.post("/apple", signInLimiter, async (c) => {
    try {
      const body: unknown = await c.req.json().catch(() => null);
      const fields = typeof body === "object" && body !== null ? (body as Record<string, unknown>) : {};
      const identityToken = fields.identityToken;
      // Apple sends the name to the app on the first sign-in only; it is a
      // display value, bounded. The email is NEVER taken from the body.
      const fullName = isString(fields.fullName) ? fields.fullName.trim().slice(0, NAME_MAX) || undefined : undefined;
      // The one-time code the app received from Apple, exchanged below for the
      // refresh token that account deletion must revoke (App Store 5.1.1(v)).
      const authorizationCode = isString(fields.authorizationCode) ? fields.authorizationCode : undefined;

      if (!isString(identityToken)) {
        return c.json({ success: false, error: "Identity token required" }, 400);
      }

      // Verify the Apple identity token
      const appleUser = await verifyAppleIdToken(identityToken);
      if (!appleUser) {
        return c.json({ success: false, error: "Invalid Apple token" }, 401);
      }

      // The email comes from the signed token only: a body field would let
      // anyone attach any address to their account.
      const userEmail = appleUser.email || `${appleUser.sub}@privaterelay.appleid.com`;

      // Create or update user in database
      const { user, isNew } = await upsertUser({
        email: userEmail,
        name: fullName,
        provider: "apple",
        providerId: appleUser.sub,
      });
      if (user.is_active === false) return c.json(accountDisabled, 403);

      // A failure at Apple is logged there and never fails the sign-in.
      if (authorizationCode !== undefined) await appleSignIn.rememberAuthorization(user.id, authorizationCode);

      // Generate JWT token
      const token = generateJWT({
        id: user.id,
        email: user.email,
        name: user.name ?? undefined,
        provider: "apple",
        providerId: appleUser.sub,
      });

      // Get user profile if exists
      const row = await getUserProfile(user.id);
      // The app reads its own photos here (profile view, completion card).
      const profile = row ? { ...row, photos: await getOwnPhotoUrls(user.id) } : null;

      return c.json({
        success: true,
        token,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          provider: user.provider,
          isNew,
          hasProfile: !!row?.is_complete,
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

      const row = await getUserProfile(user.id);
      // The app reads its own photos here (profile view, completion card).
      const profile = row ? { ...row, photos: await getOwnPhotoUrls(user.id) } : null;

      return c.json({
        success: true,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          picture: user.picture,
          provider: user.provider,
          hasProfile: !!row?.is_complete,
        },
        profile,
        missing: missingProfileFields(row),
      });
    } catch (error) {
      console.error("Get user error:", error);
      return c.json({ success: false, error: "Failed to get user" }, 500);
    }
  });

  app.route("/api/auth", auth);
}
