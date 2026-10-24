import type { PromptDefinition } from "../../shared/api/types";

export const MAX_PROMPTS = 3;
export const ANSWER_MIN = 10;
export const ANSWER_MAX = 150;

export function answerProblem(answer: string): string | null {
  const length = answer.trim().length;
  if (length < ANSWER_MIN) return `Au moins ${ANSWER_MIN} caractères (encore ${ANSWER_MIN - length}).`;
  if (length > ANSWER_MAX) return `${ANSWER_MAX} caractères au maximum.`;
  return null;
}

const CATEGORY_LABELS: Readonly<Record<string, string>> = {
  personality: "Personnalité",
  lifestyle: "Style de vie",
  jewish: "Vie juive",
  conversation: "Pour lancer la conversation",
};
const CATEGORY_ORDER = ["personality", "lifestyle", "jewish", "conversation"];

export interface PromptGroup { readonly category: string; readonly label: string; readonly prompts: readonly PromptDefinition[] }

// Catalogue grouped by category, fixed order, prompts already answered left out.
export function groupCatalog(catalog: readonly PromptDefinition[], usedIds: readonly string[]): readonly PromptGroup[] {
  const free = catalog.filter((prompt) => !usedIds.includes(prompt.id));
  const categories = [...new Set([...CATEGORY_ORDER, ...free.map((prompt) => prompt.category)])];
  return categories
    .map((category) => ({ category, label: CATEGORY_LABELS[category] ?? category, prompts: free.filter((prompt) => prompt.category === category) }))
    .filter((group) => group.prompts.length > 0);
}

// Lowest slot index (0 to 2) not taken by an existing prompt.
export function freePosition(positions: readonly number[]): number {
  for (let slot = 0; slot < MAX_PROMPTS; slot += 1) if (!positions.includes(slot)) return slot;
  return MAX_PROMPTS - 1;
}
