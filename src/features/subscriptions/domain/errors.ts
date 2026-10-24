export type InvalidTransactionReason =
  | "malformed_jws"
  | "unsupported_algorithm"
  | "invalid_certificate_chain"
  | "untrusted_root"
  | "invalid_signature"
  | "invalid_payload"
  | "wrong_bundle"
  | "sandbox_not_allowed"
  | "product_not_allowed"
  | "not_consumable"
  | "revoked"
  | "expired";

// Any reason a signed App Store payload cannot be trusted. The reason is for
// logs; callers never show it to the client.
export class InvalidTransactionError extends Error {
  constructor(readonly reason: InvalidTransactionReason) {
    super(`invalid transaction: ${reason}`);
    this.name = "InvalidTransactionError";
  }
}

export class TransactionOwnedByAnotherUserError extends Error {
  constructor() {
    super("transaction is already bound to another user");
    this.name = "TransactionOwnedByAnotherUserError";
  }
}
