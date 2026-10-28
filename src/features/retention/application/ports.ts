import type { RetentionRule } from "../domain/rules";

export interface RetentionStore {
  // Deletes the rows older than the rule allows; returns how many.
  purge(rule: RetentionRule): Promise<number>;
}
