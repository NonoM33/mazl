import { useState, type ReactElement } from "react";
import type { ApiResult } from "../shared/api/client";
import type { DecisionResultDto, SanctionKind } from "../shared/api/contracts";
import { GROUND_LABELS, GROUND_ORDER, SANCTION_LABELS, SANCTION_ORDER } from "../shared/labels";
import { Badge } from "../shared/ui/Badge";
import { Button } from "../shared/ui/Button";
import { Field, Textarea } from "../shared/ui/Field";
import { Select } from "../shared/ui/Select";
import { useToast } from "../shared/ui/Toast";
import { emptyForm, FACTS_MAX, hasDuration, isValid, NOTE_MAX, validateDecision, type DecisionForm as FormState, type FormErrors, type Outcome } from "./form-model";
import { buildStatementPreview } from "./statement";
import { StatementPreviewCard } from "./StatementPreviewCard";

interface Props {
  /** « report » : on peut classer sans suite ; « member » : sanction directe depuis la fiche. */
  readonly mode: "report" | "member";
  readonly suggested: SanctionKind | null;
  readonly canBan: boolean;
  readonly canSanction: boolean;
  readonly onSubmit: (form: FormState) => Promise<ApiResult<DecisionResultDto>>;
  readonly onDone: (result: DecisionResultDto) => void;
}

const DURATION_HINT: Readonly<Record<"restriction" | "suspension", string>> = {
  restriction: "Nombre de jours pendant lesquels les fonctionnalités sont restreintes.",
  suspension: "Nombre de jours de suspension du compte.",
};

export function DecisionForm({ mode, suggested, canBan, canSanction, onSubmit, onDone }: Props): ReactElement {
  const toast = useToast();
  const [form, setForm] = useState<FormState>(emptyForm(mode === "member" ? "actioned" : "dismissed"));
  const [shown, setShown] = useState(false);
  const [step, setStep] = useState<"edit" | "review">("edit");
  const [busy, setBusy] = useState(false);
  const [failure, setFailure] = useState<string | null>(null);

  const errors: FormErrors = validateDecision(form, { canBan });
  const visibleErrors: FormErrors = shown ? errors : {};
  const patch = (changes: Partial<FormState>): void => setForm((current) => ({ ...current, ...changes }));
  const setOutcome = (outcome: Outcome): void => patch({ outcome });

  const submit = async (): Promise<void> => {
    setShown(true);
    if (!isValid(errors)) {
      setStep("edit");
      return;
    }
    setBusy(true);
    setFailure(null);
    const result = await onSubmit(form);
    setBusy(false);
    if (result.ok) {
      toast.notify(form.outcome === "dismissed" ? "Signalement classé sans suite." : "Décision enregistrée.", "success");
      onDone(result.data);
    } else {
      setFailure(result.message);
      toast.notify(result.message, "error");
    }
  };

  const review = (): void => {
    setShown(true);
    if (isValid(errors)) setStep("review");
  };

  const sanctioning = form.outcome === "actioned";
  const duration = hasDuration(form.kind) ? Number(form.durationDays) : null;

  if (step === "review" && form.kind !== null && form.ground !== null) {
    const preview = buildStatementPreview({ kind: form.kind, ground: form.ground, facts: form.facts, durationDays: duration });
    return (
      <div className="stack">
        <StatementPreviewCard preview={preview} />
        <dl className="recap">
          <div>
            <dt>Note interne</dt>
            <dd>{form.note.trim()}</dd>
          </div>
        </dl>
        {failure !== null ? (
          <p className="notice notice-error" role="alert">
            {failure}
          </p>
        ) : null}
        <div className="row-actions">
          <Button variant="ghost" onClick={() => setStep("edit")} disabled={busy}>
            Modifier
          </Button>
          <Button variant={form.kind === "ban" ? "danger" : "primary"} loading={busy} onClick={() => void submit()}>
            {form.kind === "ban" ? "Bannir définitivement" : "Valider la décision"}
          </Button>
        </div>
      </div>
    );
  }

  return (
    <form
      className="stack"
      noValidate
      onSubmit={(event) => {
        event.preventDefault();
        if (sanctioning) review();
        else void submit();
      }}
    >
      {mode === "report" ? (
        <fieldset className="choice-group">
          <legend>Issue du signalement</legend>
          <div className="choice-row">
            <label className={`choice${!sanctioning ? " is-on" : ""}`}>
              <input type="radio" name="outcome" checked={!sanctioning} onChange={() => setOutcome("dismissed")} />
              <span>Classer sans suite</span>
            </label>
            <label className={`choice${sanctioning ? " is-on" : ""}${canSanction ? "" : " is-disabled"}`}>
              <input type="radio" name="outcome" checked={sanctioning} disabled={!canSanction} onChange={() => setOutcome("actioned")} />
              <span>Sanctionner</span>
            </label>
          </div>
          {!canSanction ? <p className="field-hint">Votre rôle ne permet pas de sanctionner.</p> : null}
        </fieldset>
      ) : null}

      {sanctioning ? (
        <>
          <fieldset className="choice-group">
            <legend>Sanction</legend>
            <div className="choice-row choice-row-4">
              {SANCTION_ORDER.map((kind) => {
                const blocked = kind === "ban" && !canBan;
                return (
                  <label key={kind} className={`choice${form.kind === kind ? " is-on" : ""}${blocked ? " is-disabled" : ""}`}>
                    <input type="radio" name="kind" checked={form.kind === kind} disabled={blocked} onChange={() => patch({ kind, banConfirmed: false })} />
                    <span>{SANCTION_LABELS[kind]}</span>
                    {suggested === kind ? <Badge tone="accent">Suggérée</Badge> : null}
                  </label>
                );
              })}
            </div>
            {visibleErrors.kind !== undefined ? (
              <p className="field-error" role="alert">
                {visibleErrors.kind}
              </p>
            ) : suggested !== null ? (
              <p className="field-hint">La sanction suggérée tient compte de l'historique. Elle n'est jamais appliquée sans votre choix.</p>
            ) : null}
          </fieldset>

          <Select
            label="Motif normalisé de la décision"
            value={form.ground ?? ""}
            options={GROUND_ORDER.map((ground) => ({ value: ground, label: GROUND_LABELS[ground] }))}
            placeholder="Choisir un motif…"
            onChange={(value) => patch({ ground: value === "" ? null : value })}
            error={visibleErrors.ground}
          />

          {form.kind === "restriction" || form.kind === "suspension" ? (
            <Field label="Durée (jours)" hint={DURATION_HINT[form.kind]} error={visibleErrors.durationDays}>
              {({ id, describedBy, invalid }) => (
                <input id={id} className="input input-narrow" type="number" min={1} max={365} inputMode="numeric" value={form.durationDays} aria-describedby={describedBy} aria-invalid={invalid || undefined} onChange={(event) => patch({ durationDays: event.target.value })} />
              )}
            </Field>
          ) : null}

          <Textarea
            label="Faits communiqués au membre"
            hint="Ce texte figure dans l'exposé des motifs lu par le membre. Aucune donnée personnelle d'un tiers."
            value={form.facts}
            onChange={(facts) => patch({ facts })}
            max={FACTS_MAX}
            rows={4}
            error={visibleErrors.facts}
          />
        </>
      ) : null}

      <Textarea
        label="Note interne (obligatoire)"
        hint="Visible par le staff seulement, consignée au journal d'audit."
        value={form.note}
        onChange={(note) => patch({ note })}
        max={NOTE_MAX}
        rows={3}
        error={visibleErrors.note}
      />

      {form.kind === "ban" && sanctioning ? (
        <div className={`ban-confirm${visibleErrors.banConfirmed !== undefined ? " has-error" : ""}`}>
          <label className="check">
            <input type="checkbox" checked={form.banConfirmed} onChange={(event) => patch({ banConfirmed: event.target.checked })} />
            <span>Je confirme le bannissement définitif de ce compte.</span>
          </label>
          {visibleErrors.banConfirmed !== undefined ? (
            <p className="field-error" role="alert">
              {visibleErrors.banConfirmed}
            </p>
          ) : null}
        </div>
      ) : null}

      {failure !== null ? (
        <p className="notice notice-error" role="alert">
          {failure}
        </p>
      ) : null}

      <div className="row-actions">
        {sanctioning ? (
          <Button type="submit" variant="primary">
            Relire l'exposé des motifs
          </Button>
        ) : (
          <Button type="submit" variant="primary" loading={busy}>
            Classer sans suite
          </Button>
        )}
      </div>
    </form>
  );
}
