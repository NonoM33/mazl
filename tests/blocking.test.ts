import { test, expect, describe, beforeAll } from "bun:test";

// Integration test for user blocking + report.
// Requires a running server (TEST_API_URL, default http://localhost:3000) with a
// reachable Postgres and the dev endpoints enabled (NODE_ENV !== "production").
const BASE_URL = process.env.TEST_API_URL || "http://localhost:3000";

interface TestUser {
  id: number;
  token: string;
}

async function makeUser(label: string): Promise<TestUser> {
  const email = `block-${label}-${Date.now()}-${Math.floor(performance.now())}@mazl.app`;
  const res = await fetch(`${BASE_URL}/api/dev/test-user`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: "test123", name: `Block ${label}` }),
  });
  const data = (await res.json()) as {
    success: boolean;
    user?: { id: number };
    token?: string;
  };
  if (!data.success || !data.user || !data.token) {
    throw new Error(`makeUser(${label}) failed: ${JSON.stringify(data)}`);
  }
  return { id: data.user.id, token: data.token };
}

function authHeaders(token: string): Record<string, string> {
  return { "Content-Type": "application/json", Authorization: `Bearer ${token}` };
}

describe("User blocking & report", () => {
  let alice: TestUser;
  let bob: TestUser;

  beforeAll(async () => {
    alice = await makeUser("alice");
    bob = await makeUser("bob");
  });

  test("block, blocked list, unblock", async () => {
    const blockRes = await fetch(`${BASE_URL}/api/users/${bob.id}/block`, {
      method: "POST",
      headers: authHeaders(alice.token),
    });
    expect(blockRes.status).toBe(200);

    const listRes = await fetch(`${BASE_URL}/api/users/blocked`, {
      headers: authHeaders(alice.token),
    });
    expect(listRes.status).toBe(200);
    const list = (await listRes.json()) as { blocked?: Array<{ user_id: number }> };
    expect(list.blocked?.some((u) => u.user_id === bob.id)).toBe(true);

    const unblockRes = await fetch(`${BASE_URL}/api/users/${bob.id}/block`, {
      method: "DELETE",
      headers: authHeaders(alice.token),
    });
    expect(unblockRes.status).toBe(200);

    const listRes2 = await fetch(`${BASE_URL}/api/users/blocked`, {
      headers: authHeaders(alice.token),
    });
    const list2 = (await listRes2.json()) as { blocked?: Array<{ user_id: number }> };
    expect(list2.blocked?.some((u) => u.user_id === bob.id) ?? false).toBe(false);
  });

  test("cannot block yourself", async () => {
    const res = await fetch(`${BASE_URL}/api/users/${alice.id}/block`, {
      method: "POST",
      headers: authHeaders(alice.token),
    });
    expect(res.status).toBe(400);
  });

  test("report with block_user also blocks", async () => {
    const res = await fetch(`${BASE_URL}/api/users/${bob.id}/report`, {
      method: "POST",
      headers: authHeaders(alice.token),
      body: JSON.stringify({ category: "spam", comment: "integration test", block_user: true }),
    });
    expect(res.status).toBe(200);
    const data = (await res.json()) as { success?: boolean; blocked?: boolean };
    expect(data.success).toBe(true);
    expect(data.blocked).toBe(true);

    // cleanup so re-runs stay idempotent
    await fetch(`${BASE_URL}/api/users/${bob.id}/block`, {
      method: "DELETE",
      headers: authHeaders(alice.token),
    });
  });

  test("legacy POST /api/report still works", async () => {
    const res = await fetch(`${BASE_URL}/api/report`, {
      method: "POST",
      headers: authHeaders(alice.token),
      body: JSON.stringify({ reportedUserId: bob.id, reason: "other", details: "regression" }),
    });
    expect(res.status).toBe(200);
  });
});
