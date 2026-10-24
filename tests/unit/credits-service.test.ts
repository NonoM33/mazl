import { beforeEach, describe, expect, test } from "bun:test";
import { CreditsService } from "../../src/features/credits/application/credits-service";
import { FakePlusStatus, InMemoryCredits } from "./support/credits-fakes";
import { FakeJwsVerifier } from "./support/subscriptions-fakes";
import { TransactionVerifier } from "../../src/features/subscriptions/application/transaction-verifier";

// Rules from docs/premium/CREDITS.md, "Règles".

const FREE = 1;
const PLUS = 2;
let repository: InMemoryCredits;
let plus: FakePlusStatus;
let service: CreditsService;

beforeEach(() => {
  repository = new InMemoryCredits();
  plus = new FakePlusStatus();
  plus.plus.add(PLUS);
  const transactions = new TransactionVerifier(new FakeJwsVerifier(), { bundleId: "com.mazl.app", productIds: [] });
  service = new CreditsService({ repository, plus, transactions });
});

describe("reading the balance", () => {
  test("a free member gets 1 super like and 0 boost a day", async () => {
    const credits = await service.credits(FREE);
    expect(credits.super_like).toEqual({ daily_allowance: 1, daily_remaining: 1, purchased_balance: 0, available: 1 });
    expect(credits.boost).toEqual({ daily_allowance: 0, daily_remaining: 0, purchased_balance: 0, available: 0 });
    expect(credits.resets_at).toBe("2026-10-25T00:00:00.000Z");
  });

  test("a mazl+ member gets 5 super likes and 1 boost a day", async () => {
    const credits = await service.credits(PLUS);
    expect(credits.super_like.daily_allowance).toBe(5);
    expect(credits.boost.daily_allowance).toBe(1);
    expect(credits.super_like.available).toBe(5);
    expect(credits.boost.available).toBe(1);
  });
});

describe("spending", () => {
  test("the allowance of the day goes first, then the purchased credits", async () => {
    repository.setBalance(FREE, "super_like", 2);
    const first = await service.spend(FREE, "super_like", 50);
    expect(first.ok).toBe(true);
    expect(repository.spends[0]?.source).toBe("daily");
    expect(repository.balance(FREE, "super_like")).toBe(2);

    const second = await service.spend(FREE, "super_like", 51);
    expect(second.ok).toBe(true);
    expect(repository.spends[1]?.source).toBe("purchased");
    expect(repository.balance(FREE, "super_like")).toBe(1);
    if (second.ok) expect(second.credits.super_like).toEqual({ daily_allowance: 1, daily_remaining: 0, purchased_balance: 1, available: 1 });
  });

  test("a mazl+ member spends 5 super likes a day, the sixth is refused", async () => {
    for (let i = 0; i < 5; i++) expect((await service.spend(PLUS, "super_like", 100 + i)).ok).toBe(true);
    const sixth = await service.spend(PLUS, "super_like", 200);
    expect(sixth.ok).toBe(false);
    expect(sixth.credits.super_like.available).toBe(0);
    expect(repository.spends).toHaveLength(5);
  });

  test("a free member without boost cannot boost", async () => {
    const result = await service.spend(FREE, "boost");
    expect(result.ok).toBe(false);
    expect(repository.spends).toHaveLength(0);
  });

  test("a mazl+ member has one boost a day, then needs a pack", async () => {
    expect((await service.spend(PLUS, "boost")).ok).toBe(true);
    expect((await service.spend(PLUS, "boost")).ok).toBe(false);
    repository.setBalance(PLUS, "boost", 1);
    expect((await service.spend(PLUS, "boost")).ok).toBe(true);
    expect(repository.spends.map((s) => s.source)).toEqual(["daily", "purchased"]);
  });

  test("the allowance comes back the next day, purchased credits never expire", async () => {
    repository.setBalance(FREE, "super_like", 3);
    await service.spend(FREE, "super_like", 1);
    await service.spend(FREE, "super_like", 2);
    repository.nextDay();
    const credits = await service.credits(FREE);
    expect(credits.super_like).toEqual({ daily_allowance: 1, daily_remaining: 1, purchased_balance: 2, available: 3 });
  });

  test("a debit is bound to its member and its target", async () => {
    await service.spend(FREE, "super_like", 77);
    expect(repository.spends[0]).toMatchObject({ userId: FREE, kind: "super_like", targetUserId: 77 });
  });

  test("a lapsed subscription falls back to the free allowance", async () => {
    plus.plus.delete(PLUS);
    expect((await service.credits(PLUS)).super_like.daily_allowance).toBe(1);
  });

  test("cancelling a daily debit gives the allowance back", async () => {
    const spent = await service.spend(FREE, "super_like", 9);
    if (!spent.ok) throw new Error("expected a debit");
    await service.cancelSpend(FREE, spent.spendId);
    expect((await service.credits(FREE)).super_like.daily_remaining).toBe(1);
    expect(repository.spends).toHaveLength(0);
  });

  test("cancelling a purchased debit gives the credit back", async () => {
    repository.setBalance(FREE, "boost", 1);
    const spent = await service.spend(FREE, "boost");
    if (!spent.ok) throw new Error("expected a debit");
    expect(repository.balance(FREE, "boost")).toBe(0);
    await service.cancelSpend(FREE, spent.spendId);
    expect(repository.balance(FREE, "boost")).toBe(1);
  });

  test("a debit cannot be cancelled by someone else", async () => {
    repository.setBalance(FREE, "boost", 1);
    const spent = await service.spend(FREE, "boost");
    if (!spent.ok) throw new Error("expected a debit");
    await service.cancelSpend(PLUS, spent.spendId);
    expect(repository.balance(FREE, "boost")).toBe(0);
  });

  test("a negative balance blocks purchased spending until a pack fills the debt", async () => {
    repository.setBalance(FREE, "boost", -2);
    expect((await service.spend(FREE, "boost")).ok).toBe(false);
    expect((await service.credits(FREE)).boost).toEqual({ daily_allowance: 0, daily_remaining: 0, purchased_balance: -2, available: 0 });
  });
});
