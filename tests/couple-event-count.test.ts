import { beforeAll, describe, expect, test } from "bun:test";
import { db } from "./media-helpers";
import { TEST_PASSWORD } from "./test-password";

// Regression: registering twice for the same couple event counted the couple
// twice in current_couples, and cancelling twice removed it twice (the count
// was updated even when nothing changed). Requires a running server.
const BASE_URL = process.env.TEST_API_URL || "http://localhost:3000";

interface Ctx { token: string; eventId: number }
let ctx: Ctx;

async function json<T>(res: Response): Promise<T> {
  return (await res.json()) as T;
}

const auth = (token: string): Record<string, string> => ({
  Authorization: `Bearer ${token}`,
  "Content-Type": "application/json",
});

async function currentCouples(): Promise<number> {
  const body = await json<{ event: { current_couples: number | string } }>(
    await fetch(`${BASE_URL}/api/couple/events/${ctx.eventId}`, { headers: auth(ctx.token) }),
  );
  return Number(body.event.current_couples);
}

const register = () =>
  fetch(`${BASE_URL}/api/couple/events/${ctx.eventId}/register`, { method: "POST", headers: auth(ctx.token) });
const cancel = () =>
  fetch(`${BASE_URL}/api/couple/events/${ctx.eventId}/register`, { method: "DELETE", headers: auth(ctx.token) });

beforeAll(async () => {
  const email = `evt-${Date.now()}-${Math.floor(performance.now())}@mazl.app`;
  const user = await json<{ user: { id: number }; token: string }>(
    await fetch(`${BASE_URL}/api/dev/test-user`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password: TEST_PASSWORD, name: "Event Count" }),
    }),
  );
  const enabled = await fetch(`${BASE_URL}/api/dev/couple/enable`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ userId: user.user.id }),
  });
  expect(enabled.ok).toBe(true);
  // A fresh database has no couple event: create one with free places.
  const [event] = await db<{ id: number }[]>`
    INSERT INTO couple_events (title, event_date, max_couples, current_couples)
    VALUES ('Soirée test', CURRENT_DATE + 30, 20, 0) RETURNING id
  `;
  if (!event) throw new Error("could not create the test event");
  ctx = { token: user.token, eventId: event.id };
});

describe("couple event registration count", () => {
  test("registering twice counts the couple once", async () => {
    const before = await currentCouples();
    expect((await register()).status).toBe(200);
    expect((await register()).status).toBe(200);
    expect(await currentCouples()).toBe(before + 1);
  });

  test("cancelling twice removes the couple once", async () => {
    const before = await currentCouples();
    expect((await cancel()).status).toBe(200);
    await cancel();
    expect(await currentCouples()).toBe(before - 1);
  });

  test("registering again after cancelling counts again", async () => {
    const before = await currentCouples();
    expect((await register()).status).toBe(200);
    expect(await currentCouples()).toBe(before + 1);
  });
});
