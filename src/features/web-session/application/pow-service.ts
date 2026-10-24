import { randomBytes } from "node:crypto";
import type { PowFailure } from "../domain/errors";
import { checkSolution, issueChallenge, type IssuedChallenge } from "../domain/pow";
import type { Clock } from "./ports";

export interface ProofOfWork {
  readonly challenge: string;
  readonly nonce: string;
}

// Issues and verifies challenges. Each challenge is accepted once: the ones
// already spent are remembered until they would have expired anyway.
export class PowService {
  private readonly key = randomBytes(32);
  private readonly spent = new Map<string, number>();

  constructor(
    readonly difficulty: number,
    private readonly now: Clock,
  ) {}

  issue(): IssuedChallenge {
    return issueChallenge(this.key, randomBytes(16), this.difficulty, this.nowSeconds());
  }

  // null when the proof is good (and now spent), otherwise why it is refused.
  verify(proof: ProofOfWork): PowFailure | null {
    const nowSeconds = this.nowSeconds();
    this.forgetExpired(nowSeconds);
    if (this.spent.has(proof.challenge)) return "replayed";
    const check = checkSolution(this.key, proof.challenge, proof.nonce, nowSeconds);
    if (!check.ok) return check.reason;
    this.spent.set(proof.challenge, check.expiresAt);
    return null;
  }

  private nowSeconds(): number {
    return Math.floor(this.now().getTime() / 1000);
  }

  private forgetExpired(nowSeconds: number): void {
    for (const [challenge, expiresAt] of this.spent) {
      if (expiresAt <= nowSeconds) this.spent.delete(challenge);
    }
  }
}
