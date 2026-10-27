import { useState, type ReactElement } from "react";
import { useSession } from "../app/session";
import { Button } from "../shared/ui/Button";
import { Modal } from "../shared/ui/Modal";
import { useToast } from "../shared/ui/Toast";
import { storefrontApi } from "./api";
import { storefrontErrorMessage } from "./errors";
import { LangField } from "./LangFields";
import { HIGHLIGHT_MAX, highlightDraft, validateHighlight } from "./offers-model";
import { LANG_LABELS } from "./theme-texts";
import { LANGS, type Lang, type ProductDto } from "./types";

/** Texte d'accroche d'une offre (« Le plus choisi »), en cinq langues. Vide partout = pas d'accroche. */
export function HighlightDialog({ product, onClose, onDone }: { readonly product: ProductDto; readonly onClose: () => void; readonly onDone: () => void }): ReactElement {
  const { api } = useSession();
  const toast = useToast();
  const [draft, setDraft] = useState<Record<Lang, string>>(() => highlightDraft(product.highlight));
  const [errors, setErrors] = useState<Readonly<Partial<Record<Lang, string>>>>({});
  const [failure, setFailure] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const save = async (): Promise<void> => {
    const checked = validateHighlight(draft);
    if (!checked.ok) {
      setErrors(checked.errors);
      return;
    }
    setErrors({});
    setSaving(true);
    setFailure(null);
    const result = await storefrontApi(api).patchProduct(product.productId, { highlight: checked.value });
    setSaving(false);
    if (!result.ok) {
      setFailure(storefrontErrorMessage(result));
      return;
    }
    toast.notify(checked.value === null ? "Accroche retirée." : "Accroche enregistrée dans les cinq langues.", "success");
    onDone();
  };

  return (
    <Modal title={`Accroche — ${product.label}`} onClose={onClose}>
      <div className="stack">
        <p className="modal-lead">Un court texte posé sur l'offre dans l'app (par exemple « Le plus choisi »). Une langue laissée vide reprend le français. Laissez tout vide pour retirer l'accroche.</p>
        {LANGS.map((lang) => (
          <LangField key={lang} label={LANG_LABELS[lang]} lang={lang} value={draft[lang]} max={HIGHLIGHT_MAX} onChange={(value) => setDraft((current) => ({ ...current, [lang]: value }))} error={errors[lang]} />
        ))}
        {failure !== null ? (
          <p className="notice notice-error" role="alert">
            {failure}
          </p>
        ) : null}
        <div className="row-actions">
          <Button variant="ghost" onClick={onClose}>
            Annuler
          </Button>
          <Button variant="primary" loading={saving} onClick={() => void save()}>
            Enregistrer
          </Button>
        </div>
      </div>
    </Modal>
  );
}
