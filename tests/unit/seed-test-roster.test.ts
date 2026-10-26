import { describe, expect, test } from "bun:test";
import { isDemoPhotoUrl } from "../../src/features/media/domain/stored-photo";
import { CONVERSATION_SCRIPTS, MEN_PHOTOS, TEST_MEMBERS, stockPhoto } from "../../src/features/fixtures/test-profile-roster";
import { RELATIONSHIP_INTENTIONS, updateProfileBodySchema } from "../../src/shared/http/validation";

// The roster of scripts/seed-test-profiles.ts, checked against what the owner asked for and
// against what the server accepts, written from the brief and the schemas, not from the data.

const OWNER_WOMEN = [
  "1580489944761-15a19d654956", "1548382131-e0ebb1f0cdea", "1594756154841-ac5d160dbf46", "1594318223885-20dc4b889f9e",
  "1662850886700-4ec19bd30d11", "1592621385645-e41659e8aabe", "1607569708758-0270aa4651bd", "1611695434369-a8f5d76ceb7b",
  "1623717217554-72ca676de535", "1525186402429-b4ff38bedec6", "1581714161666-dade083654ae", "1619896382906-4f4681290afc",
  "1562337404-3044c84ac061",
];
const OWNER_MEN = ["1507003211169-0a1dd7228f2d", "1528892952291-009c663ce843", "1600603406200-5b2a104684ac", "1583123810408-23e7b5d1af9f", "1583264277168-58ceba4b84e7"];
// The values the mobile app stores (edit_profile_screen.dart).
const DENOMINATIONS = ["Laique", "Traditionaliste", "Massorti", "Modern Orthodox", "Orthodox", "Habad", "Autre"];
const KASHRUT = ["Non", "A la maison", "Strict", "Glatt"];
const SHABBAT = ["Non observant", "Partiellement", "Observant", "Tres observant"];
const CITIES = ["Paris", "Neuilly-sur-Seine", "Boulogne-Billancourt", "Lyon", "Marseille", "Strasbourg", "Nice"];

describe("test members roster", () => {
  const women = TEST_MEMBERS.filter((member) => member.gender === "female");
  const men = TEST_MEMBERS.filter((member) => member.gender === "male");

  test("13 women and 3 men, half of them with a verified photo, one key and one address each", () => {
    expect([women.length, men.length]).toEqual([13, 3]);
    expect(TEST_MEMBERS.filter((member) => member.photoVerified)).toHaveLength(8);
    expect(new Set(TEST_MEMBERS.map((member) => member.providerId)).size).toBe(16);
    for (const member of TEST_MEMBERS) {
      expect(member.providerId).toMatch(/^seed-(female|male)-\d+$/);
      expect(member.email).toBe(`fake.${member.gender}.${member.providerId.split("-")[2]}@mazl.seed`);
    }
  });

  test("every profile is realistic: age 23 to 34, a listed city, 2 to 3 sentences, answers the app stores", () => {
    for (const member of TEST_MEMBERS) {
      expect(member.age).toBeGreaterThanOrEqual(23);
      expect(member.age).toBeLessThanOrEqual(34);
      expect(CITIES).toContain(member.city);
      const sentences = member.bio.split(/(?<=[.!?])\s+/);
      expect([member.displayName, sentences.length >= 2 && sentences.length <= 3]).toEqual([member.displayName, true]);
      expect(DENOMINATIONS).toContain(member.denomination);
      expect(KASHRUT).toContain(member.kashrut);
      expect(SHABBAT).toContain(member.shabbat);
      expect(RELATIONSHIP_INTENTIONS).toContain(member.intention);
      expect(member.name.startsWith(member.displayName)).toBe(true);
    }
    expect(new Set(TEST_MEMBERS.map((member) => member.city))).toEqual(new Set(CITIES));
  });

  test("what the script writes passes the profile schema of the server", () => {
    for (const member of TEST_MEMBERS) {
      const parsed = updateProfileBodySchema.safeParse({
        displayName: member.displayName, gender: member.gender, bio: member.bio, location: member.city,
        denomination: member.denomination, kashrutLevel: member.kashrut, shabbatObservance: member.shabbat,
        relationshipIntention: member.intention, lookingFor: member.gender === "female" ? "male" : "female",
      });
      expect([member.providerId, parsed.success]).toEqual([member.providerId, true]);
    }
  });

  test("photos: only the owner's pictures, a different main picture for everybody, in the exposed format", () => {
    expect(women.map((member) => member.photoId)).toEqual(OWNER_WOMEN);
    expect(men.map((member) => member.photoId)).toEqual(OWNER_MEN.slice(0, 3));
    expect([...MEN_PHOTOS] as string[]).toEqual(OWNER_MEN);
    expect(new Set(TEST_MEMBERS.map((member) => member.photoId)).size).toBe(16);
    for (const member of TEST_MEMBERS) {
      expect(stockPhoto(member.photoId, "portrait")).toBe(`https://images.unsplash.com/photo-${member.photoId}?w=800&h=1000&fit=crop&crop=faces&q=80`);
      expect(stockPhoto(member.photoId, "thumbnail")).toBe(`https://images.unsplash.com/photo-${member.photoId}?w=200&h=200&fit=crop&crop=faces&q=80`);
      for (const url of [stockPhoto(member.photoId, "portrait"), stockPhoto(member.photoId, "portrait", "entropy"), stockPhoto(member.photoId, "thumbnail")]) {
        expect(isDemoPhotoUrl(url)).toBe(true);
      }
    }
  });
});

describe("conversation scripts of the administrator", () => {
  test("four conversations of 3 to 6 messages, in order, a few of them unread, only from the other side", () => {
    expect(CONVERSATION_SCRIPTS).toHaveLength(4);
    let unread = 0;
    for (const script of CONVERSATION_SCRIPTS) {
      expect(script.length).toBeGreaterThanOrEqual(3);
      expect(script.length).toBeLessThanOrEqual(6);
      const minutes = script.map((line) => line.minutesAgo);
      expect(minutes).toEqual([...minutes].sort((a, b) => b - a));
      expect(Math.max(...minutes)).toBeLessThanOrEqual(7 * 24 * 60);
      for (const line of script) {
        if (line.unread === true) {
          expect(line.from).toBe("partner");
          unread += 1;
        }
        expect(line.text).not.toMatch(/@|https?:/);
      }
    }
    expect(unread).toBeGreaterThanOrEqual(3);
  });
});

describe("admin whitelist module", () => {
  test("loads without any secret, so a maintenance script can use it", async () => {
    const env = Object.fromEntries(Object.entries(process.env).filter(([name]) => !/SECRET|ADMIN/.test(name))) as Record<string, string>;
    const proc = Bun.spawn(["bun", "-e", "const m = await import('./src/features/admin/admin.emails'); console.log(m.isAdminEmail('nobody@example.com'))"], {
      cwd: new URL("../../", import.meta.url).pathname, env, stdout: "pipe", stderr: "pipe",
    });
    const [out, code] = [await new Response(proc.stdout).text(), await proc.exited];
    expect([code, out.trim()]).toEqual([0, "false"]);
  });
});
