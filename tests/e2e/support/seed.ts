import postgres from "postgres";
import { THROWAWAY_CREDENTIAL } from "../../throwaway-credential";
import { BASE_URL, DATABASE_URL } from "./env";
import { portrait } from "./portraits";

// Realistic, fictitious members for the e2e scenarios and the screenshots,
// built through the same API the apps use (plus SQL only where no route
// exists: events). Names, cities and texts are invented.

export const db = postgres(DATABASE_URL, { max: 4 });

export interface Member { readonly id: number; readonly token: string; readonly name: string; readonly email: string }

export interface MemberSpec {
  readonly name: string;
  readonly gender: "male" | "female";
  readonly lookingFor?: "male" | "female" | "all";
  readonly birthdate: string;
  readonly city: string;
  readonly latitude: number;
  readonly longitude: number;
  readonly bio?: string;
  readonly denomination?: string;
  readonly kashrutLevel?: string;
  readonly shabbatObservance?: string;
  readonly photos?: number;
  readonly prompts?: readonly (readonly [string, string])[];
  readonly consent?: boolean;
}

const json = (token: string) => ({ Authorization: `Bearer ${token}`, "Content-Type": "application/json" });
let sequence = 0;

async function call<T>(path: string, init: RequestInit): Promise<T> {
  const res = await fetch(`${BASE_URL}${path}`, init);
  const body = (await res.json().catch(() => ({}))) as T & { success?: boolean };
  if (!res.ok) throw new Error(`${init.method ?? "GET"} ${path} → ${res.status} ${JSON.stringify(body)}`);
  return body;
}

export async function createMember(spec: MemberSpec): Promise<Member> {
  sequence += 1;
  const email = `${spec.name.toLowerCase().normalize("NFD").replace(/[^a-z]/g, "")}-${Date.now()}-${sequence}@example.com`;
  const created = await call<{ token: string; user: { id: number } }>("/api/dev/test-user", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: THROWAWAY_CREDENTIAL, name: spec.name }),
  });
  const member: Member = { id: created.user.id, token: created.token, name: spec.name, email };
  await call("/api/profile", {
    method: "PUT",
    headers: json(member.token),
    body: JSON.stringify({
      displayName: spec.name,
      birthdate: spec.birthdate,
      gender: spec.gender,
      lookingFor: spec.lookingFor ?? (spec.gender === "male" ? "female" : "male"),
      bio: spec.bio,
      location: spec.city,
      latitude: spec.latitude,
      longitude: spec.longitude,
      denomination: spec.denomination,
      kashrutLevel: spec.kashrutLevel,
      shabbatObservance: spec.shabbatObservance,
      ageMin: 22,
      ageMax: 45,
      distanceMax: 100,
    }),
  });
  for (let index = 0; index < (spec.photos ?? 3); index += 1) await uploadPhoto(member, await portrait(member.id, index));
  for (const [promptId, answer] of spec.prompts ?? []) {
    await call("/api/profile/prompts", { method: "POST", headers: json(member.token), body: JSON.stringify({ prompt_id: promptId, answer }) });
  }
  // Every member of the community has answered the art. 9 consent in the app;
  // scenarios about the consent screen create their member with consent: false.
  if (spec.consent !== false) await grantReligiousConsent(member);
  return member;
}

export async function uploadPhoto(member: Member, bytes: Buffer): Promise<void> {
  const form = new FormData();
  form.append("photo", new File([bytes], "photo.jpg", { type: "image/jpeg" }));
  await call("/api/profile/photos", { method: "POST", headers: { Authorization: `Bearer ${member.token}` }, body: form });
}

export async function swipe(from: Member, to: Member, action: "like" | "pass" | "super_like"): Promise<{ match: boolean }> {
  return call("/api/swipes", { method: "POST", headers: json(from.token), body: JSON.stringify({ target_user_id: to.id, action }) });
}

export async function match(a: Member, b: Member): Promise<number> {
  await swipe(a, b, "like");
  await swipe(b, a, "like");
  const { matches } = await call<{ matches: { conversationId: number; profile: { user_id: number } }[] }>("/api/matches", { headers: json(a.token) });
  const found = matches.find((item) => item.profile.user_id === b.id);
  if (!found) throw new Error(`no match between ${a.id} and ${b.id}`);
  return found.conversationId;
}

export async function say(from: Member, conversationId: number, content: string): Promise<void> {
  await call(`/api/conversations/${conversationId}/messages`, {
    method: "POST",
    headers: json(from.token),
    body: JSON.stringify({ client_id: crypto.randomUUID(), type: "text", content }),
  });
}

export async function makePlus(member: Member, days = 30): Promise<void> {
  const expires = new Date(Date.now() + days * 86_400_000).toISOString();
  await db`
    INSERT INTO subscriptions (user_id, plan_type, status, store, product_id, original_transaction_id, started_at, expires_at)
    VALUES (${member.id}, 'three_month', 'active', 'apple', 'com.mazl.app.plus.3m', ${`e2e-${member.id}`}, NOW() AT TIME ZONE 'UTC', ${expires}::timestamp)
    ON CONFLICT (user_id) DO UPDATE SET status = 'active', expires_at = EXCLUDED.expires_at`;
}

export async function grantReligiousConsent(member: Member): Promise<void> {
  const res = await fetch(`${BASE_URL}/api/privacy/consents`, { headers: json(member.token) });
  if (!res.ok) return;
  const body = (await res.json()) as { consents: { religious_data: { current_version: string } } };
  await call("/api/privacy/consents/religious_data", {
    method: "PUT",
    headers: json(member.token),
    body: JSON.stringify({ granted: true, version: body.consents.religious_data.current_version, source: "app" }),
  });
}

export async function createEvent(spec: { title: string; description: string; type: string; location: string; address: string; inDays: number; time: string; price: number; maxAttendees: number }): Promise<number> {
  const date = new Date(Date.now() + spec.inDays * 86_400_000).toISOString().slice(0, 10);
  const [row] = await db<{ id: number }[]>`
    INSERT INTO events (title, description, event_type, location, address, date, time, price, currency, max_attendees, is_published)
    VALUES (${spec.title}, ${spec.description}, ${spec.type}, ${spec.location}, ${spec.address}, ${date}, ${spec.time}, ${spec.price}, 'EUR', ${spec.maxAttendees}, true)
    RETURNING id`;
  if (!row) throw new Error("event not created");
  return row.id;
}
