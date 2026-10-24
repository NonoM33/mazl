// Profile completeness for the statistics screen: what is filled in, what is
// missing, and where to go to fix it. Only facts the API gives.

export interface CompletenessInput {
  readonly photos: number;
  readonly prompts: number;
  readonly hasBio: boolean;
  readonly hasPractice: boolean;
  readonly verified: boolean;
}

export interface CompletenessStep {
  readonly key: "photos" | "prompts" | "bio" | "practice" | "verification";
  readonly label: string;
  readonly done: boolean;
  // Route to the screen that fixes it; null when it only happens on the phone.
  readonly to: string | null;
  readonly hint: string;
}

export const PHOTO_TARGET = 6;
export const PROMPT_TARGET = 3;

export function completenessSteps(input: CompletenessInput): readonly CompletenessStep[] {
  return [
    { key: "photos", label: `Photos ${Math.min(input.photos, PHOTO_TARGET)}/${PHOTO_TARGET}`, done: input.photos >= PHOTO_TARGET, to: "/profil/modifier", hint: `Ajoutez ${PHOTO_TARGET - input.photos} photo${PHOTO_TARGET - input.photos > 1 ? "s" : ""}.` },
    { key: "prompts", label: `Prompts ${Math.min(input.prompts, PROMPT_TARGET)}/${PROMPT_TARGET}`, done: input.prompts >= PROMPT_TARGET, to: "/profil/modifier", hint: `Répondez à ${PROMPT_TARGET - input.prompts} prompt${PROMPT_TARGET - input.prompts > 1 ? "s" : ""} de plus.` },
    { key: "bio", label: "Présentation", done: input.hasBio, to: "/profil/modifier", hint: "Écrivez quelques lignes sur vous." },
    { key: "practice", label: "Pratique", done: input.hasPractice, to: "/profil/modifier", hint: "Renseignez votre pratique." },
    { key: "verification", label: "Vérification", done: input.verified, to: null, hint: "Faites vérifier votre profil depuis l'app." },
  ];
}

// 0 to 100, one share per step.
export function completenessPercent(input: CompletenessInput): number {
  const parts = [
    Math.min(input.photos, PHOTO_TARGET) / PHOTO_TARGET,
    Math.min(input.prompts, PROMPT_TARGET) / PROMPT_TARGET,
    input.hasBio ? 1 : 0,
    input.hasPractice ? 1 : 0,
    input.verified ? 1 : 0,
  ];
  return Math.round((parts.reduce((sum, part) => sum + part, 0) / parts.length) * 100);
}
