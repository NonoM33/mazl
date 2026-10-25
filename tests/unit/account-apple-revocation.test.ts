import { describe, expect, test } from "bun:test";
import { withAppleRevocation, type AppleRevoker } from "../../src/features/account/apple-revocation";
import type { UserErasure } from "../../src/features/admin/admin.erasure";

// The erasure of a member (self-service DELETE /api/users/me, admin) revokes
// the member's Sign in with Apple grant: read first (the rows are about to be
// erased), revoke once the erasure has succeeded.

function fixture(options: { erasureFails?: boolean; revokeThrows?: boolean } = {}) {
  const events: string[] = [];
  const apple: AppleRevoker = {
    beginRevocation: async (userId) => {
      events.push(`read ${userId}`);
      return async () => {
        events.push(`revoke ${userId}`);
        if (options.revokeThrows) throw new Error("apple down");
      };
    },
  };
  const inner: UserErasure = {
    around: async (userId, deletion) => {
      events.push(`erase ${userId}`);
      if (options.erasureFails) throw new Error("deletion failed");
      return deletion();
    },
  };
  return { events, erasure: withAppleRevocation(inner, apple) };
}

describe("withAppleRevocation", () => {
  test("reads the token, erases, then revokes — in that order", async () => {
    const { events, erasure } = fixture();
    const result = await erasure.around(7, async () => {
      events.push("deletion");
      return { deleted: true };
    });
    expect(result).toEqual({ deleted: true });
    expect(events).toEqual(["read 7", "erase 7", "deletion", "revoke 7"]);
  });

  test("a failed erasure revokes nothing and stays a failure", async () => {
    const { events, erasure } = fixture({ erasureFails: true });
    await expect(erasure.around(7, async () => "never")).rejects.toThrow("deletion failed");
    expect(events).toEqual(["read 7", "erase 7"]);
  });

  test("a failing revocation never fails the erasure that already happened", async () => {
    const { erasure } = fixture({ revokeThrows: true });
    await expect(erasure.around(7, async () => "erased")).resolves.toBe("erased");
  });
});
