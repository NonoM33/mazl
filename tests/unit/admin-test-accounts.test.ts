import { describe, expect, test } from "bun:test";
import { isAdminTestAccount, parseTestAccountIds } from "../../src/features/admin/admin.emails";

describe("the administrators' test accounts", () => {
  test("reads a comma-separated list of ids, ignoring anything else", () => {
    expect([...parseTestAccountIds(" 44, 7 ,abc,,12x")]).toEqual([44, 7]);
    expect(parseTestAccountIds(undefined).size).toBe(0);
  });

  test("an account signed in with an Apple relay address counts when its id is listed", () => {
    const relay = { id: 44, email: "abcd1234@privaterelay.appleid.com" };
    expect(isAdminTestAccount(relay, parseTestAccountIds("44"))).toBe(true);
    expect(isAdminTestAccount(relay, parseTestAccountIds("45"))).toBe(false);
  });

  test("the administrator's e-mail still counts on its own", () => {
    expect(isAdminTestAccount({ id: 1, email: "renaudlemagicien@gmail.com" }, new Set())).toBe(true);
  });
});
