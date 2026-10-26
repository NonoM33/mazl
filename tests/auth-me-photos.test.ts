import { afterAll, expect, test } from "bun:test";
import postgres from "postgres";
import { THROWAWAY_CREDENTIAL } from "./throwaway-credential";

// Seen on 2026-10-26: a member with six photos saw a silhouette on their own
// profile and « Ajoutez au moins 2 photos »: GET /api/auth/me returned the
// profile without its photos.
const BASE_URL = process.env.TEST_API_URL || "http://localhost:3000";
const sql = postgres(process.env.DATABASE_URL || "postgres://postgres:postgres@localhost:5432/mazl", { max: 1, onnotice: () => undefined });

afterAll(async () => {
  await sql.end({ timeout: 2 });
});

test("GET /api/auth/me returns the member's own photos, primary first, as signed URLs", async () => {
  const made = await fetch(`${BASE_URL}/api/dev/test-user`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: `me-photos-${Date.now()}@example.com`, password: THROWAWAY_CREDENTIAL, name: "Jeanne Exemple" }),
  });
  const { user, token } = (await made.json()) as { user: { id: number }; token: string };
  const headers = { Authorization: `Bearer ${token}`, "Content-Type": "application/json" };
  const saved = await fetch(`${BASE_URL}/api/profile`, {
    method: "PUT",
    headers,
    body: JSON.stringify({ displayName: "Jeanne", birthdate: "1993-02-03", gender: "female", lookingFor: "male" }),
  });
  expect(saved.status).toBe(200);
  await sql`
    INSERT INTO profile_photos (user_id, url, position, is_primary) VALUES
      (${user.id}, ${"photos/00000000-0000-4000-8000-000000000001.jpg"}, 1, false),
      (${user.id}, ${"photos/00000000-0000-4000-8000-000000000002.jpg"}, 0, true)`;

  const me = await fetch(`${BASE_URL}/api/auth/me`, { headers });
  expect(me.status).toBe(200);
  const body = (await me.json()) as { profile: { photos?: string[] } | null };
  const photos = body.profile?.photos ?? [];
  expect(photos).toHaveLength(2);
  const [first] = await sql<{ id: number }[]>`SELECT id FROM profile_photos WHERE user_id = ${user.id} AND is_primary`;
  expect(photos[0]).toContain(`/${first?.id}`);
  for (const url of photos) expect(url).not.toContain("photos/00000000");
});
