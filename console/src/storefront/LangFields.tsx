import type { ChangeEvent, ReactElement } from "react";
import { Field } from "../shared/ui/Field";
import { isRtl } from "./theme-texts";
import type { Lang } from "./types";

interface Props {
  readonly label: string;
  readonly lang: Lang;
  readonly value: string;
  readonly onChange: (value: string) => void;
  readonly max?: number;
  readonly multiline?: boolean;
  readonly hint?: string;
  readonly error?: string | undefined;
  readonly disabled?: boolean;
}

/** Champ de texte d'une langue : l'hébreu s'écrit de droite à gauche, et le compteur dit la limite. */
export function LangField({ label, lang, value, onChange, max, multiline = false, hint, error, disabled = false }: Props): ReactElement {
  const over = max !== undefined && value.length > max;
  return (
    <Field label={label} hint={hint} error={error} counter={max === undefined ? undefined : <span className={over ? "is-over" : undefined}>{value.length}&nbsp;/&nbsp;{max}</span>}>
      {({ id, describedBy, invalid }) =>
        multiline ? (
          <textarea
            id={id}
            className="input textarea"
            rows={2}
            dir={isRtl(lang) ? "rtl" : "ltr"}
            lang={lang}
            value={value}
            disabled={disabled}
            aria-describedby={describedBy}
            aria-invalid={invalid || over || undefined}
            onChange={(event: ChangeEvent<HTMLTextAreaElement>) => onChange(event.target.value)}
          />
        ) : (
          <input
            id={id}
            className="input"
            dir={isRtl(lang) ? "rtl" : "ltr"}
            lang={lang}
            value={value}
            disabled={disabled}
            aria-describedby={describedBy}
            aria-invalid={invalid || over || undefined}
            onChange={(event: ChangeEvent<HTMLInputElement>) => onChange(event.target.value)}
          />
        )
      }
    </Field>
  );
}
