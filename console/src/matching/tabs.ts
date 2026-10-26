export type AlgorithmTab = "comprendre" | "regler" | "historique";

export const ALGORITHM_TABS: readonly { readonly id: AlgorithmTab; readonly label: string }[] = [
  { id: "comprendre", label: "Comprendre" },
  { id: "regler", label: "Régler" },
  { id: "historique", label: "Historique" },
];

/** Onglet demandé par l'adresse (`?onglet=regler`) ; « Comprendre » par défaut. */
export function tabFromParam(value: string | undefined): AlgorithmTab {
  return ALGORITHM_TABS.find((tab) => tab.id === value)?.id ?? "comprendre";
}
