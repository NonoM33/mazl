import { useEffect, useId, useState, type ReactElement } from "react";
import type { NumericParamSpec } from "../shared/api/contracts";
import { Badge } from "../shared/ui/Badge";
import { Button } from "../shared/ui/Button";
import { formatValue, snapToStep, validateValue } from "./specs";

interface SpecFieldProps {
  readonly spec: NumericParamSpec;
  readonly value: number;
  readonly active: number | undefined;
  readonly fallback: number | undefined;
  readonly onChange: (value: number) => void;
  /** Texte complémentaire à droite du libellé (ex. part d'un poids). */
  readonly extra?: string | undefined;
}

const toText = (value: number): string => String(value).replace(".", ",");
const same = (a: number | undefined, b: number): boolean => a !== undefined && Math.abs(a - b) < 1e-9;

/** Un réglage : libellé lié au champ numérique, curseur, aide, écarts avec la version active et les valeurs par défaut. */
export function SpecField({ spec, value, active, fallback, onChange, extra }: SpecFieldProps): ReactElement {
  const id = useId();
  const [text, setText] = useState(toText(value));
  useEffect(() => {
    // Réécrit le texte seulement quand la valeur vient d'ailleurs (curseur, réinitialisation, version chargée).
    if (Number.isFinite(value) && Number(text.replace(",", ".")) !== value) setText(toText(value));
  }, [value, text]);
  const error = validateValue(spec, value);
  const changed = active !== undefined && !same(active, value);
  const offDefault = fallback !== undefined && !same(fallback, value);
  const delta = active === undefined ? 0 : value - active;
  const onText = (raw: string): void => {
    setText(raw);
    const parsed = raw.trim() === "" ? Number.NaN : Number(raw.replace(",", "."));
    onChange(parsed);
  };
  return (
    <div className={`spec${changed ? " is-changed" : ""}${error !== null ? " has-error" : ""}`}>
      <div className="spec-head">
        <label htmlFor={`${id}-n`}>{spec.label}</label>
        <span className="spec-badges">
          {extra !== undefined ? <span className="muted">{extra}</span> : null}
          {changed ? (
            <Badge tone="accent">
              {delta > 0 ? "+" : "−"}
              {formatValue(Math.abs(delta), spec).replace("×", "")} vs actif
            </Badge>
          ) : null}
        </span>
      </div>
      <div className="spec-controls">
        <input
          type="range"
          className="slider"
          aria-label={`${spec.label}, curseur`}
          aria-describedby={`${id}-h`}
          aria-valuetext={formatValue(value, spec)}
          min={spec.min}
          max={spec.max}
          step={spec.step}
          value={Number.isFinite(value) ? Math.min(spec.max, Math.max(spec.min, value)) : spec.min}
          onChange={(event) => onChange(snapToStep(spec, Number(event.target.value)))}
        />
        <input
          id={`${id}-n`}
          type="text"
          inputMode="decimal"
          className="input spec-number"
          value={text}
          aria-describedby={`${id}-h${error !== null ? ` ${id}-e` : ""}`}
          aria-invalid={error !== null || undefined}
          onChange={(event) => onText(event.target.value)}
        />
        <span className="spec-unit muted">{spec.unit === undefined ? "" : spec.unit}</span>
      </div>
      <p id={`${id}-h`} className="field-hint">
        {spec.help}
      </p>
      {error !== null ? (
        <p id={`${id}-e`} className="field-error" role="alert">
          {error}
        </p>
      ) : null}
      <p className="spec-ref">
        <span>Actif : {active === undefined ? "—" : formatValue(active, spec)}</span>
        <span aria-hidden="true">·</span>
        <span>Défaut : {fallback === undefined ? "—" : formatValue(fallback, spec)}</span>
        {offDefault && fallback !== undefined ? (
          <Button size="s" variant="ghost" onClick={() => onChange(fallback)} aria-label={`Rétablir la valeur par défaut de ${spec.label}`}>
            Rétablir le défaut
          </Button>
        ) : null}
      </p>
    </div>
  );
}
