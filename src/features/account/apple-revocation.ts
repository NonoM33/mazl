import type { UserErasure } from "../admin/admin.erasure";

// What the erasure needs from Sign in with Apple, without importing the feature.
export interface AppleRevoker {
  // Reads the member's Apple token now and returns the function that revokes it.
  // The function never throws.
  beginRevocation(userId: number): Promise<() => Promise<void>>;
}

// Revokes the member's Sign in with Apple authorization once the erasure has
// succeeded (App Store rule 5.1.1(v)). The token is read first, because the
// erasure deletes its row. A failed erasure revokes nothing; a failed revocation
// is logged by the Apple module and never undoes an erasure.
export function withAppleRevocation(erasure: UserErasure, apple: AppleRevoker): UserErasure {
  return {
    around: async (userId, deletion) => {
      const revoke = await apple.beginRevocation(userId);
      const erased = await erasure.around(userId, deletion);
      await revoke().catch((error: unknown) => {
        console.error("Apple revocation failed:", error instanceof Error ? error.name : "unknown");
      });
      return erased;
    },
  };
}
