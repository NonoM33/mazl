import { describe, expect, test } from "bun:test";
import { BASE_URL, auth, db, json, makeUser, type TestUser } from "./media-helpers";

// Attack scenarios against the profile routes. Needs a running server
// (TEST_API_URL) and its database (TEST_DATABASE_URL). Every test builds its
// own members so that the suites can run in any order.

async function completeProfile(user: TestUser, fields: { gender?: string; lookingFor?: string } = {}): Promise<void> {
  await db`
    UPDATE profiles
    SET is_complete = true, display_name = ${`Membre ${user.id}`}, birthdate = '1995-04-12',
        gender = ${fields.gender ?? "female"}, looking_for = ${fields.lookingFor ?? "male"}
    WHERE user_id = ${user.id}
  `;
}

const getProfile = (viewer: TestUser, targetId: number) =>
  fetch(`${BASE_URL}/api/profile/${targetId}`, { headers: auth(viewer.token) });

const putProfile = (user: TestUser, body: unknown) =>
  fetch(`${BASE_URL}/api/profile`, { method: "PUT", headers: json(user.token), body: JSON.stringify(body) });

const block = (blocker: TestUser, blockedId: number) =>
  fetch(`${BASE_URL}/api/users/${blockedId}/block`, { method: "POST", headers: json(blocker.token) });

describe("GET /api/profile/:userId only shows what the viewer may see", () => {
  test("a member who blocked the viewer is indistinguishable from a missing member", async () => {
    const viewer = await makeUser("pv-viewer");
    const target = await makeUser("pv-blocker");
    await completeProfile(target);
    expect((await getProfile(viewer, target.id)).status).toBe(200);

    expect((await block(target, viewer.id)).status).toBe(200);
    const hidden = await getProfile(viewer, target.id);
    const missing = await getProfile(viewer, 2_000_000_000);
    expect(hidden.status).toBe(404);
    expect(await hidden.text()).toBe(await missing.text());
  });

  test("a member the viewer blocked is hidden as well", async () => {
    const viewer = await makeUser("pv-blocked-by-me");
    const target = await makeUser("pv-target");
    await completeProfile(target);
    await block(viewer, target.id);
    const res = await getProfile(viewer, target.id);
    expect(res.status).toBe(404);
    expect(JSON.stringify(await res.json())).not.toContain("looking_for");
  });

  test("a banned or deactivated account is not served", async () => {
    const viewer = await makeUser("pv-viewer-inactive");
    const target = await makeUser("pv-inactive");
    await completeProfile(target);
    await db`UPDATE users SET is_active = false WHERE id = ${target.id}`;
    const res = await getProfile(viewer, target.id);
    expect(res.status).toBe(404);
    expect(await res.text()).toBe(await (await getProfile(viewer, 2_000_000_000)).text());
  });

  test("a profile that is not complete is not served to others, but stays readable by its owner", async () => {
    const viewer = await makeUser("pv-viewer-incomplete");
    const target = await makeUser("pv-incomplete");
    expect((await getProfile(viewer, target.id)).status).toBe(404);

    const own = await getProfile(target, target.id);
    expect(own.status).toBe(200);
    const body = (await own.json()) as { profile: { email?: string } };
    expect(body.profile.email).toContain("@");
  });
});
