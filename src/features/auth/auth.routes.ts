import { Hono } from "hono";
import { verifyGoogleIdToken, verifyAppleIdToken, generateJWT } from "../../auth";
import { upsertUser, getUserProfile, findUserById, getOwnPhotoUrls } from "../../db";
import { missingProfileFields } from "../profile/domain/profile-completeness";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";
import { createIpRateLimiter } from "../../shared/http/rate-limit";
import type { AppleSignInPort } from "./apple/apple-sign-in";
import { androidCallbackRedirect } from "./apple/android-callback";
import type { ReviewAccount } from "./review/review-account";
import { checkReviewCredentials, parseReviewCredentials, REVIEW_PROVIDER, type PasswordVerifier, type ReviewLoginConfig } from "./review/review-login";

export interface ReviewSignIn {
  readonly config: ReviewLoginConfig | null;
  readonly verify: PasswordVerifier;
  readonly ensureAccount: (username: string) => Promise<{ account: ReviewAccount; isNew: boolean }>;
}

// Sign-in is public: limit it per client address so that a stolen or guessed
// token cannot be tried in bulk.
const signInLimiter = createIpRateLimiter({ max: 30, windowMs: 15 * 60_000 });
// A password can be guessed: far fewer tries for the review sign-in.
const reviewSignInLimiter = createIpRateLimiter({ max: 10, windowMs: 15 * 60_000 });

const accountDisabled = { success: false, error: "account_disabled" } as const;
const isString = (value: unknown): value is string => typeof value === "string" && value.length > 0;
const NAME_MAX = 100;

// Presentation layer for the AUTH feature. These routes are moved verbatim from
// the monolith (src/index.ts) and mounted under `/api/auth`. Behaviour, payloads
// and status codes are identical to the original inline handlers.
export function registerAuthRoutes(app: Hono<{ Variables: AppVariables }>, appleSignIn: AppleSignInPort, review: ReviewSignIn): void {
  // The Services ID Apple's web sign-in uses (site and Android app).
  const appleServicesId = process.env.APPLE_WEB_SERVICES_ID?.trim() || null;
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

      // Issued to the iOS app, or to the Services ID when Android signs in
      // through Apple's web page.
      const fromApp = await verifyAppleIdToken(identityToken);
      const appleUser = fromApp ?? (appleServicesId === null ? null : await verifyAppleIdToken(identityToken, appleServicesId));
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
      // A web sign-in's code belongs to the Services ID: the app's client
      // secret cannot exchange it.
      if (authorizationCode !== undefined && fromApp !== null) await appleSignIn.rememberAuthorization(user.id, authorizationCode);

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

  // Apple's answer to an Android sign-in (form_post), handed to the app.
  auth.post("/apple/android-callback", signInLimiter, async (c) => {
    const form = await c.req.parseBody().catch(() => null);
    const target = form === null ? null : androidCallbackRedirect(form);
    if (target === null) return c.json({ success: false, error: "Invalid Apple answer" }, 400);
    return c.redirect(target, 303);
  });

  // App Store review account: user name + password (docs/launch/REVIEW-LOGIN-CONTRAT.md).
  // Switched off (404) unless the hosting carries both REVIEW_LOGIN_* variables.
  auth.post("/review", reviewSignInLimiter, async (c) => {
    const config = review.config;
    if (config === null) return c.json({ error: "Not found" }, 404);
    try {
      const credentials = parseReviewCredentials(await c.req.json().catch(() => null));
      if (credentials === null) return c.json({ success: false, error: "credentials_required" }, 400);
      if (!(await checkReviewCredentials(config, credentials, review.verify))) {
        console.warn("Review sign-in refused");
        return c.json({ success: false, error: "invalid_credentials" }, 401);
      }

      const { account, isNew } = await review.ensureAccount(config.username);
      if (account.is_active === false) return c.json(accountDisabled, 403);

      const token = generateJWT({
        id: account.id,
        email: account.email,
        name: account.name ?? undefined,
        provider: REVIEW_PROVIDER,
        providerId: config.username,
      });
      const row = await getUserProfile(account.id);
      return c.json({
        success: true,
        token,
        user: { id: account.id, email: account.email, name: account.name, provider: account.provider, isNew, hasProfile: !!row?.is_complete },
      });
    } catch (error) {
      console.error("Review auth error:", error);
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
