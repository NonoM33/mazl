// Tableau des offres : ordre, accroches. Fonctions pures.
import { LANGS, type Lang, type LocalizedText, type ProductDto, type ProductKind } from "./types";

export const HIGHLIGHT_MAX = 40;

export const KIND_LABELS: Readonly<Record<ProductKind, string>> = { subscription: "Abonnement mazl+", boost: "Boost", superlikes: "Super likes" };

export interface OfferGroup {
  readonly id: "subscriptions" | "consumables";
  readonly title: string;
  readonly products: readonly ProductDto[];
}

export const sortProducts = (products: readonly ProductDto[]): readonly ProductDto[] => [...products].sort((a, b) => a.sortOrder - b.sortOrder || a.productId.localeCompare(b.productId));

/** Deux tableaux : les abonnements, puis les achats à l'unité ; chacun trié par ordre d'affichage. */
export function groupProducts(products: readonly ProductDto[]): readonly OfferGroup[] {
  const sorted = sortProducts(products);
  return [
    { id: "subscriptions", title: "Abonnements mazl+", products: sorted.filter((product) => product.kind === "subscription") },
    { id: "consumables", title: "Achats à l'unité", products: sorted.filter((product) => product.kind !== "subscription") },
  ];
}

export interface OrderPatch {
  readonly productId: string;
  readonly sortOrder: number;
}

/**
 * Déplace un produit dans son groupe. Les emplacements d'ordre déjà utilisés par le groupe sont gardés (le tableau global
 * reste cohérent avec l'autre groupe) ; seuls les produits dont l'ordre change sont à envoyer.
 */
export function reorder(group: readonly ProductDto[], productId: string, targetIndex: number): readonly OrderPatch[] {
  const from = group.findIndex((product) => product.productId === productId);
  if (from === -1 || targetIndex < 0 || targetIndex >= group.length || from === targetIndex) return [];
  const slots = group.map((product) => product.sortOrder).sort((a, b) => a - b);
  const next = [...group];
  const [moved] = next.splice(from, 1);
  if (moved === undefined) return [];
  next.splice(targetIndex, 0, moved);
  return next.flatMap((product, index) => {
    const sortOrder = slots[index] ?? index;
    return product.sortOrder === sortOrder ? [] : [{ productId: product.productId, sortOrder }];
  });
}

/** Applique les changements d'ordre à la liste affichée, sans attendre le serveur. */
export function applyOrder(products: readonly ProductDto[], patches: readonly OrderPatch[]): readonly ProductDto[] {
  return products.map((product) => {
    const patch = patches.find((candidate) => candidate.productId === product.productId);
    return patch === undefined ? product : { ...product, sortOrder: patch.sortOrder };
  });
}

export const emptyHighlight = (): Record<Lang, string> => ({ fr: "", en: "", he: "", es: "", ru: "" });

export function highlightDraft(highlight: LocalizedText | null): Record<Lang, string> {
  return { ...emptyHighlight(), ...(highlight ?? {}) };
}

/** Accroche saisie → valeur envoyée : null si tout est vide, erreur par langue si trop longue, français obligatoire si une autre langue est remplie. */
export function validateHighlight(draft: Readonly<Record<Lang, string>>): { readonly ok: true; readonly value: LocalizedText | null } | { readonly ok: false; readonly errors: Readonly<Partial<Record<Lang, string>>> } {
  const trimmed = Object.fromEntries(LANGS.map((lang) => [lang, draft[lang].trim()])) as Record<Lang, string>;
  if (LANGS.every((lang) => trimmed[lang] === "")) return { ok: true, value: null };
  const errors: Partial<Record<Lang, string>> = {};
  if (trimmed.fr === "") errors.fr = "Le français est obligatoire dès qu'une accroche existe.";
  for (const lang of LANGS) {
    if (trimmed[lang].length > HIGHLIGHT_MAX) errors[lang] = `Accroche trop longue (${HIGHLIGHT_MAX} caractères au plus).`;
  }
  if (Object.keys(errors).length > 0) return { ok: false, errors };
  return { ok: true, value: Object.fromEntries(LANGS.map((lang) => [lang, trimmed[lang] === "" ? trimmed.fr : trimmed[lang]])) as LocalizedText };
}
