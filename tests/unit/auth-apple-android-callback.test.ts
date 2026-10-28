import { describe, expect, test } from "bun:test";
import { androidCallbackRedirect } from "../../src/features/auth/apple/android-callback";

// Sign in with Apple on Android: Apple posts its answer (form_post) to the
// server, which hands it to the app through an Android intent link. The
// format is the one the sign_in_with_apple plugin listens to
// (package README, "Android" section): intent://callback?<query>#Intent;
// package=<app id>;scheme=signinwithapple;end.

describe("Apple's answer handed back to the Android app", () => {
  test("carries Apple's fields to the app's intent link", () => {
    const target = androidCallbackRedirect({ code: "c-1", id_token: "header.payload.sig", state: "s-1" });
    expect(target).not.toBeNull();
    const [head, fragment] = (target ?? "").split("#");
    expect(head?.startsWith("intent://callback?")).toBe(true);
    expect(fragment).toBe("Intent;package=com.mazl.app;scheme=signinwithapple;end");
    const query = new URLSearchParams(head?.slice("intent://callback?".length));
    expect(query.get("code")).toBe("c-1");
    expect(query.get("id_token")).toBe("header.payload.sig");
    expect(query.get("state")).toBe("s-1");
  });

  test("keeps the name Apple sends on the first sign-in", () => {
    const user = JSON.stringify({ name: { firstName: "Jeanne", lastName: "Exemple" } });
    const query = new URLSearchParams((androidCallbackRedirect({ code: "c", id_token: "t", user }) ?? "").split("?")[1]?.split("#")[0]);
    expect(query.get("user")).toBe(user);
  });

  test("drops anything Apple does not send", () => {
    const query = new URLSearchParams((androidCallbackRedirect({ code: "c", id_token: "t", extra: "x" }) ?? "").split("?")[1]?.split("#")[0]);
    expect(query.has("extra")).toBe(false);
  });

  test("refuses an answer without a code, and oversized fields", () => {
    expect(androidCallbackRedirect({ id_token: "t" })).toBeNull();
    expect(androidCallbackRedirect({ code: "c".repeat(5000), id_token: "t" })).toBeNull();
  });

  test("passes Apple's error through, so the app can stop waiting", () => {
    const query = new URLSearchParams((androidCallbackRedirect({ error: "user_cancelled_authorize" }) ?? "").split("?")[1]?.split("#")[0]);
    expect(query.get("error")).toBe("user_cancelled_authorize");
  });
});
