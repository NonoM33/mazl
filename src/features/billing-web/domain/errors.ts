export class WithdrawalWaiverRequiredError extends Error {
  constructor() {
    super("The withdrawal waiver was not accepted");
    this.name = "WithdrawalWaiverRequiredError";
  }
}

export class OfferUnavailableError extends Error {
  constructor(readonly offerId: string) {
    super(`No Stripe price is configured for ${offerId}`);
    this.name = "OfferUnavailableError";
  }
}

export class AlreadySubscribedError extends Error {
  constructor(readonly source: "apple" | "stripe") {
    super(`An active mazl+ entitlement already exists (${source})`);
    this.name = "AlreadySubscribedError";
  }
}

export class NoCustomerError extends Error {
  constructor() {
    super("The member has no Stripe customer");
    this.name = "NoCustomerError";
  }
}

export class InvalidSignatureError extends Error {
  constructor() {
    super("The webhook signature is invalid");
    this.name = "InvalidSignatureError";
  }
}

export class UnknownPriceError extends Error {
  constructor(readonly priceId: string | undefined) {
    super(`A Stripe subscription uses a price that maps to no offer (${priceId ?? "none"})`);
    this.name = "UnknownPriceError";
  }
}

// Any failure of the payment provider; the message carries the operation and
// Stripe's error code, never a parameter or a key.
export class StripeGatewayError extends Error {
  constructor(readonly operation: string, readonly code: string | undefined) {
    super(`Stripe ${operation} failed${code === undefined ? "" : ` (${code})`}`);
    this.name = "StripeGatewayError";
  }
}
