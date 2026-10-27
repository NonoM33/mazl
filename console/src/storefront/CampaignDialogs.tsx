import { useState, type ReactElement } from "react";
import { Button } from "../shared/ui/Button";
import { Modal } from "../shared/ui/Modal";
import { CANCEL_LINES, publishSummary } from "./publish-summary";
import { campaignState } from "./campaign-state";
import { formatParis } from "./paris-time";
import type { CampaignDto, ProductDto } from "./types";

function Section({ title, lines }: { readonly title: string; readonly lines: readonly string[] }): ReactElement {
  return (
    <section className="confirm-section">
      <h3>{title}</h3>
      <ul>
        {lines.map((line) => (
          <li key={line}>{line}</li>
        ))}
      </ul>
    </section>
  );
}

interface ConfirmProps {
  readonly onClose: () => void;
  readonly onConfirm: () => Promise<string | null>;
}

/** Les deux confirmations partagent le même déroulé : on dit ce qui va se passer, on appelle, on affiche l'erreur du serveur si elle vient. */
function useConfirm(onConfirm: ConfirmProps["onConfirm"]): { readonly busy: boolean; readonly failure: string | null; readonly run: () => void } {
  const [busy, setBusy] = useState(false);
  const [failure, setFailure] = useState<string | null>(null);
  const run = (): void => {
    setBusy(true);
    setFailure(null);
    void onConfirm().then((message) => {
      setBusy(false);
      setFailure(message);
    });
  };
  return { busy, failure, run };
}

export function PublishDialog({ campaign, products, onClose, onConfirm }: ConfirmProps & { readonly campaign: CampaignDto; readonly products: readonly ProductDto[] }): ReactElement {
  const { busy, failure, run } = useConfirm(onConfirm);
  const summary = publishSummary(campaign, products);
  return (
    <Modal title={`Programmer « ${campaign.name} »`} onClose={onClose} wide>
      <div className="stack">
        <p className="modal-lead">
          La campagne sera créée chez Apple et chez Stripe, puis passera à « Programmée ». Elle démarre le {formatParis(campaign.startsAt)} et se termine le {formatParis(campaign.endsAt)}.
        </p>
        <Section title="Chez Apple" lines={summary.apple} />
        <Section title="Chez Stripe (paiement sur le site)" lines={summary.stripe} />
        <Section title="Dans l'app" lines={summary.app} />
        <p className="notice notice-warning">Si Apple refuse une demande, rien n'est programmé : la campagne reste en brouillon avec l'erreur.</p>
        {failure !== null ? (
          <p className="notice notice-error" role="alert">
            {failure}
          </p>
        ) : null}
        <div className="row-actions">
          <Button variant="ghost" onClick={onClose}>
            Pas maintenant
          </Button>
          <Button variant="primary" loading={busy} onClick={run}>
            Programmer la campagne
          </Button>
        </div>
      </div>
    </Modal>
  );
}

export function CancelDialog({ campaign, onClose, onConfirm }: ConfirmProps & { readonly campaign: CampaignDto }): ReactElement {
  const { busy, failure, run } = useConfirm(onConfirm);
  const lines = campaign.status === "draft" ? CANCEL_LINES.draft : CANCEL_LINES.active;
  const live = campaignState(campaign) === "live";
  return (
    <Modal title={`Annuler « ${campaign.name} »`} onClose={onClose}>
      <div className="stack">
        <p className="modal-lead">{live ? "Cette campagne est en cours : l'annuler l'arrête tout de suite." : "Une campagne annulée ne peut pas être relancée ; il faudra en créer une autre."}</p>
        <ul className="confirm-list">
          {lines.map((line) => (
            <li key={line}>{line}</li>
          ))}
        </ul>
        {failure !== null ? (
          <p className="notice notice-error" role="alert">
            {failure}
          </p>
        ) : null}
        <div className="row-actions">
          <Button variant="ghost" onClick={onClose}>
            Garder la campagne
          </Button>
          <Button variant="danger" loading={busy} onClick={run}>
            Annuler la campagne
          </Button>
        </div>
      </div>
    </Modal>
  );
}
