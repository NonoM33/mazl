import { Dialog } from "../shared/ui/dialog";

const SHORTCUTS: readonly (readonly [string, string])[] = [
  ["←", "Passer"],
  ["→", "Like"],
  ["↑", "Super Like"],
  ["Z", "Annuler le dernier « Passer » (5 s)"],
  ["I", "Détails du profil"],
  ["Espace", "Photo suivante"],
  ["Échap", "Fermer"],
  ["Échap × 2", "Mode discret"],
  ["⌘ K / Ctrl K", "Chercher une conversation"],
  ["?", "Cette aide"],
];

export function ShortcutsHelp({ onClose }: { readonly onClose: () => void }) {
  return (
    <Dialog title="Raccourcis clavier" onClose={onClose}>
      <ul className="list">
        {SHORTCUTS.map(([keys, label]) => (
          <li key={keys} className="row" style={{ minHeight: 44, padding: "10px 0" }}>
            <span className="row-main body-m">{label}</span>
            <span className="inline gap-4">{keys.split(" / ").map((key) => <kbd key={key}>{key}</kbd>)}</span>
          </li>
        ))}
      </ul>
    </Dialog>
  );
}
