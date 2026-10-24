import { describe, expect, test } from "bun:test";
import { createHash, randomBytes } from "node:crypto";
import { sha256Ascii } from "../../web/src/features/auth/sha256";
import { solve } from "../../web/src/features/auth/pow-solver";
import { checkSolution, issueChallenge } from "../../src/features/web-session/domain/pow";

// The browser's hash is checked against node:crypto (an independent
// implementation), and its solution against the server's own verifier.
describe("browser proof of work", () => {
  test("SHA-256 matches node:crypto on lengths around the block boundaries", () => {
    for (const length of [0, 1, 55, 56, 63, 64, 65, 119, 120, 200]) {
      const text = "a1.-_".repeat(50).slice(0, length);
      expect(Buffer.from(sha256Ascii(text)).toString("hex")).toBe(createHash("sha256").update(text).digest("hex"));
    }
  });

  test("a solved challenge is accepted by the server verifier", async () => {
    const key = randomBytes(32);
    const now = Math.floor(Date.now() / 1000);
    const issued = issueChallenge(key, randomBytes(16), 12, now);
    const nonce = await solve(issued.challenge, issued.difficulty);
    expect(checkSolution(key, issued.challenge, nonce, now).ok).toBe(true);
  });
});
