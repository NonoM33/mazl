import { describe, expect, test } from "bun:test";
import { CheckoutService, PortalService, WITHDRAWAL_SHA256 } from "../../src/features/billing-web/application/checkout-service";
import {
  AlreadySubscribedError,
  NoCustomerError,
  OfferUnavailableError,
  WithdrawalWaiverRequiredError,
} from "../../src/features/billing-web/domain/errors";
import { offerById, type Offer } from "../../src/features/billing-web/domain/offers";
import { WITHDRAWAL_TEXT, WITHDRAWAL_VERSION } from "../../src/features/billing-web/domain/withdrawal";
import { FakeGateway, InMemoryBilling, SETTINGS } from "./support/billing-fakes";

function offer(id: string): Offer {
  const found = offerById(id);
  if (found === undefined) throw new Error(id);
  return found;
}

function setup() {
  const gateway = new FakeGateway();
  const repository = new InMemoryBilling();
  return { gateway, repository, checkout: new CheckoutService(gateway, repository, SETTINGS), portal: new PortalService(gateway, repository, SETTINGS) };
}

const accepted = { waiverAccepted: true, waiverVersion: WITHDRAWAL_VERSION } as const;

describe("checkout", () => {
  test("without the waiver, no customer, no proof and no session", async () => {
    const { checkout, gateway, repository } = setup();
    for (const request of [
      { waiverAccepted: undefined, waiverVersion: WITHDRAWAL_VERSION },
      { waiverAccepted: false, waiverVersion: WITHDRAWAL_VERSION },
      { waiverAccepted: true, waiverVersion: "2025-01-01" },
      { waiverAccepted: true, waiverVersion: undefined },
    ]) {
      await expect(checkout.start(1, { offer: offer("plus_3m"), ...request })).rejects.toBeInstanceOf(WithdrawalWaiverRequiredError);
    }
    expect(gateway.customers).toHaveLength(0);
    expect(gateway.sessions).toHaveLength(0);
    expect(repository.waivers).toHaveLength(0);
  });

  test("the proof is stored before the session, then linked to it", async () => {
    const { checkout, gateway, repository } = setup();
    const { url } = await checkout.start(1, { offer: offer("plus_3m"), ...accepted });
    expect(url).toBe("https://checkout.stripe.test/cs_1");
    expect(repository.waivers).toEqual([
      { id: 1, userId: 1, offer: "plus_3m", textVersion: "2026-10-24", textSha256: WITHDRAWAL_SHA256, sessionId: "cs_1" },
    ]);
    expect(gateway.sessions[0]).toMatchObject({ customerId: "cus_1", userId: 1, priceId: "price_plus_3m", waiverId: 1, successUrl: SETTINGS.successUrl, cancelUrl: SETTINGS.cancelUrl });
  });

  test("the stored hash is the SHA-256 of the exact legal text", async () => {
    const digest = new Bun.CryptoHasher("sha256").update(WITHDRAWAL_TEXT).digest("hex");
    expect(WITHDRAWAL_SHA256).toBe(digest);
  });

  test("the Stripe customer is created once and reused", async () => {
    const { checkout, gateway } = setup();
    await checkout.start(1, { offer: offer("boost_1"), ...accepted });
    await checkout.start(1, { offer: offer("boost_3"), ...accepted });
    expect(gateway.customers).toEqual([{ userId: 1, email: "member1@example.com" }]);
    expect(gateway.sessions.map((s) => s.customerId)).toEqual(["cus_1", "cus_1"]);
  });

  test("an offer without a configured price is unavailable", async () => {
    const { gateway, repository } = setup();
    const { plus_1m: _gone, ...prices } = SETTINGS.prices;
    const checkout = new CheckoutService(gateway, repository, { ...SETTINGS, prices });
    await expect(checkout.start(1, { offer: offer("plus_1m"), ...accepted })).rejects.toBeInstanceOf(OfferUnavailableError);
    expect(repository.waivers).toHaveLength(0);
  });

  test("an Apple mazl+ in force refuses a web subscription, source apple", async () => {
    const { checkout, repository, gateway } = setup();
    repository.setApple(1, new Date("2027-01-01T00:00:00Z"));
    const error = await checkout.start(1, { offer: offer("plus_1m"), ...accepted }).catch((e: unknown) => e);
    expect(error).toBeInstanceOf(AlreadySubscribedError);
    expect((error as AlreadySubscribedError).source).toBe("apple");
    expect(gateway.sessions).toHaveLength(0);
    expect(repository.waivers).toHaveLength(0);
  });

  test("a Stripe mazl+ in force refuses another one, source stripe", async () => {
    const { checkout, repository } = setup();
    repository.entitlements.set(1, {
      userId: 1, store: "stripe", status: "active", planType: "monthly", originalTransactionId: "sub_1",
      expiresAt: new Date("2027-01-01T00:00:00Z"), live: true,
    });
    const error = await checkout.start(1, { offer: offer("plus_6m"), ...accepted }).catch((e: unknown) => e);
    expect((error as AlreadySubscribedError).source).toBe("stripe");
  });

  test("credit packs stay buyable with mazl+, and an expired Apple row does not block", async () => {
    const { checkout, repository, gateway } = setup();
    repository.setApple(1, new Date("2027-01-01T00:00:00Z"));
    await checkout.start(1, { offer: offer("superlikes_15"), ...accepted });
    repository.setApple(2, new Date("2026-01-01T00:00:00Z"));
    await checkout.start(2, { offer: offer("plus_12m"), ...accepted });
    expect(gateway.sessions.map((s) => s.offer.id)).toEqual(["superlikes_15", "plus_12m"]);
  });
});

describe("portal", () => {
  test("no customer, 404 material", async () => {
    await expect(setup().portal.open(1)).rejects.toBeInstanceOf(NoCustomerError);
  });

  test("opens the portal of the member's customer with the return URL", async () => {
    const { portal, repository, gateway } = setup();
    await repository.saveCustomer(1, "cus_1");
    expect(await portal.open(1)).toEqual({ url: "https://billing.stripe.test/portal" });
    expect(gateway.portals).toEqual([{ customerId: "cus_1", returnUrl: SETTINGS.returnUrl }]);
  });
});

// Security review B4: the waiver is confirmed to the member when paying and,
// for packs, on the invoice Stripe e-mails (a durable medium, L221-13).
describe("confirmation of the waiver", () => {
  test("the session carries the dated waiver text", async () => {
    const { checkout, gateway } = setup();
    await checkout.start(1, { offer: offer("boost_1"), ...accepted });
    const confirmation = gateway.sessions[0]?.waiverConfirmation ?? "";
    expect(confirmation).toContain(WITHDRAWAL_TEXT);
    expect(confirmation).toMatch(/^Renoncement exprès au droit de rétractation accepté le \d{2}\/\d{2}\/\d{4} à \d{2}:\d{2} \(UTC\)/);
  });
});
