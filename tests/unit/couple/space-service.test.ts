import { describe, expect, test } from "bun:test";
import { CheckinAlreadyDoneError, SpaceService } from "../../../src/features/couple/application/space-service";
import type { CoupleContext, SpaceStore } from "../../../src/features/couple/application/space-ports";
import type { Ratings } from "../../../src/features/couple/domain/checkin";
import { zonedInstant } from "../../../src/features/couple/domain/local-time";
import type { Mood } from "../../../src/features/couple/domain/mood";
import type { OutingCandidate } from "../../../src/features/couple/domain/outings";

const PARIS = "Europe/Paris";
const NOW = zonedInstant(2026, 11, 4, 10, 0, PARIS);
const ME: CoupleContext = { coupleId: 5, userId: 1, partnerId: 2, partnerName: "David", partnerPicture: null, startedAt: "2026-04-03" };
const PARTNER: CoupleContext = { ...ME, userId: 2, partnerId: 1, partnerName: "Léa" };

class Fake implements SpaceStore {
  moodRows = new Map<number, Mood>();
  checkinRows: { period: string; userId: number; ratings: Ratings }[] = [];
  async moods(_c: number, userId: number, partnerId: number) { return { mine: this.moodRows.get(userId) ?? null, partner: this.moodRows.get(partnerId) ?? null }; }
  async setMood(_c: number, userId: number, _day: string, mood: Mood) { const before = this.moodRows.get(userId) ?? null; this.moodRows.set(userId, mood); return before; }
  async checkins(_c: number, period: string) { return this.checkinRows.filter((r) => r.period === period); }
  async saveCheckin(_c: number, userId: number, period: string, ratings: Ratings) {
    if (this.checkinRows.some((r) => r.period === period && r.userId === userId)) return false;
    this.checkinRows.push({ period, userId, ratings });
    return true;
  }
  async dates() { return [{ id: 3, title: "Anniversaire", type: "anniversary", date: "2025-11-20", isRecurring: true }]; }
  async registeredEvents() { return []; }
}

const outings: OutingCandidate[] = [
  { id: 1, kind: "activity", title: "Poterie", subtitle: "Lyon", imageUrl: null, city: "Lyon", startsAt: null, priceCents: 3800, kosher: false, saved: false, partner: false, featured: false },
  { id: 2, kind: "event", title: "Dîner", subtitle: "Paris", imageUrl: null, city: "Paris", startsAt: zonedInstant(2026, 11, 4, 20, 0, PARIS).toISOString(), priceCents: 6500, kosher: true, saved: false, partner: false, featured: true },
];

function setup() {
  const store = new Fake();
  const talks: number[] = [];
  const service = new SpaceService({
    store,
    rituals: { enabled: async () => [] },
    outings: { candidates: async () => outings },
    questions: { today: async () => ({ id: 8, text: "Question ?", myAnswer: null, partnerAnswer: null, partnerAnswered: true }) },
    premium: { of: async () => ({ active: true, paidBy: "partner", renewsAt: null }) },
    moodPush: { talkRequested: async (id) => void talks.push(id) },
    candleLighting: () => null,
  });
  return { store, talks, service };
}

describe("Today (contract section 2)", () => {
  test("days together, the partner, the question flags, the upcoming date, the outing and the rights", async () => {
    const { service } = setup();
    const today = await service.today(ME, "fr", NOW);
    expect(today.days).toBe(215); // 2026-04-03 to 2026-11-04
    expect(today.partner).toEqual({ id: 2, name: "David", picture: null });
    expect(today.question).toEqual({ id: 8, text: "Question ?", myAnswered: false, partnerAnswered: true });
    expect(today.upcoming.map((u) => [u.kind, u.title])).toEqual([["date", "Anniversaire"]]);
    expect(today.outing).not.toBeNull();
    expect(Object.keys(today.outing ?? {})).not.toContain("partner");
    expect(today.checkin).toEqual({ due: true, period: "2026-11" });
    expect(today.premium.active).toBe(true);
  });

  test("the partner's mood shows, mine starts empty", async () => {
    const { service, store } = setup();
    store.moodRows.set(2, "good");
    expect((await service.today(ME, "fr", NOW)).mood).toEqual({ mine: null, partner: "good" });
  });
});

describe("mood", () => {
  test("'talk' warns the partner once a day, other moods never do", async () => {
    const { service, talks } = setup();
    await service.setMood(ME, "good", NOW);
    expect(talks).toEqual([]);
    await service.setMood(ME, "talk", NOW);
    await service.setMood(ME, "talk", NOW);
    expect(talks).toEqual([2]);
  });
});

describe("check-in (contract section 6)", () => {
  test("alone: no summary, the partner not done; the other's notes are never returned", async () => {
    const { service } = setup();
    const view = await service.submitCheckin(ME, { talk: 4, time: 3, close: 5 }, NOW);
    expect(view).toEqual({ period: "2026-11", mine: { talk: 4, time: 3, close: 5 }, partnerDone: false, summary: null });
    const theirs = await service.checkin(PARTNER, NOW);
    expect(theirs.mine).toBeNull();
    expect(theirs.partnerDone).toBe(true);
    expect(JSON.stringify(theirs)).not.toContain('"talk":4');
  });

  test("once both answered, each sees the same summary and still only their own notes", async () => {
    const { service } = setup();
    await service.submitCheckin(ME, { talk: 4, time: 3, close: 5 }, NOW);
    const second = await service.submitCheckin(PARTNER, { talk: 5, time: 1, close: 4 }, NOW);
    expect(second.summary).toEqual({ aligned: 2, lowest: "time", trend: null });
    expect(second.mine).toEqual({ talk: 5, time: 1, close: 4 });
    expect((await service.checkin(ME, NOW)).summary).toEqual(second.summary);
  });

  test("a second answer in the same month is refused (checkin_already_done)", async () => {
    const { service } = setup();
    await service.submitCheckin(ME, { talk: 4, time: 3, close: 5 }, NOW);
    await expect(service.submitCheckin(ME, { talk: 1, time: 1, close: 1 }, NOW)).rejects.toBeInstanceOf(CheckinAlreadyDoneError);
  });

  test("the next month is a new check-in, and the trend compares with the previous one", async () => {
    const { service } = setup();
    const october = zonedInstant(2026, 10, 12, 10, 0, PARIS);
    await service.submitCheckin(ME, { talk: 2, time: 2, close: 2 }, october);
    await service.submitCheckin(PARTNER, { talk: 2, time: 2, close: 2 }, october);
    expect((await service.checkin(ME, NOW)).mine).toBeNull();
    await service.submitCheckin(ME, { talk: 4, time: 4, close: 4 }, NOW);
    expect((await service.submitCheckin(PARTNER, { talk: 4, time: 4, close: 4 }, NOW)).summary?.trend).toBe("up");
  });
});

describe("outings", () => {
  test("featured event first, the rest as items; the filter narrows", async () => {
    const { service } = setup();
    const all = await service.outings(ME, undefined, NOW);
    expect(all.featured?.id).toBe(2);
    expect(all.items.map((o) => o.id)).toEqual([1]);
    expect((await service.outings(ME, "kosher", NOW)).featured?.id).toBe(2);
    expect((await service.outings(ME, "tonight", NOW)).items).toEqual([]);
    expect((await service.outings(ME, "cheap", NOW)).featured?.id).toBe(1);
  });
});
