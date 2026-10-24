import { useId, type ChangeEvent, type ReactElement, type ReactNode } from "react";

interface FieldShellProps {
  readonly label: string;
  readonly hint?: string | undefined;
  readonly error?: string | undefined;
  readonly children: (ids: { readonly id: string; readonly describedBy: string | undefined; readonly invalid: boolean }) => ReactNode;
  readonly counter?: ReactNode;
}

/** Libellé + champ + aide + erreur, reliés par aria-describedby. */
export function Field({ label, hint, error, children, counter }: FieldShellProps): ReactElement {
  const id = useId();
  const hintId = `${id}-hint`;
  const errorId = `${id}-error`;
  const describedBy = [hint !== undefined ? hintId : null, error !== undefined ? errorId : null].filter((part) => part !== null).join(" ");
  return (
    <div className="field">
      <div className="field-head">
        <label htmlFor={id}>{label}</label>
        {counter !== undefined ? <span className="field-counter">{counter}</span> : null}
      </div>
      {children({ id, describedBy: describedBy === "" ? undefined : describedBy, invalid: error !== undefined })}
      {hint !== undefined ? (
        <p id={hintId} className="field-hint">
          {hint}
        </p>
      ) : null}
      {error !== undefined ? (
        <p id={errorId} className="field-error" role="alert">
          {error}
        </p>
      ) : null}
    </div>
  );
}

interface TextInputProps {
  readonly label: string;
  readonly value: string;
  readonly onChange: (value: string) => void;
  readonly type?: "text" | "email" | "password" | "search";
  readonly autoComplete?: string;
  readonly placeholder?: string;
  readonly hint?: string;
  readonly error?: string | undefined;
  readonly autoFocus?: boolean;
}

export function TextInput({ label, value, onChange, type = "text", autoComplete, placeholder, hint, error, autoFocus }: TextInputProps): ReactElement {
  return (
    <Field label={label} hint={hint} error={error}>
      {({ id, describedBy, invalid }) => (
        <input
          id={id}
          className="input"
          type={type}
          value={value}
          autoComplete={autoComplete}
          placeholder={placeholder}
          autoFocus={autoFocus}
          aria-describedby={describedBy}
          aria-invalid={invalid || undefined}
          onChange={(event: ChangeEvent<HTMLInputElement>) => onChange(event.target.value)}
        />
      )}
    </Field>
  );
}

interface TextareaProps {
  readonly label: string;
  readonly value: string;
  readonly onChange: (value: string) => void;
  readonly max: number;
  readonly rows?: number;
  readonly hint?: string;
  readonly error?: string | undefined;
  readonly placeholder?: string;
  readonly autoFocus?: boolean;
}

export function Textarea({ label, value, onChange, max, rows = 4, hint, error, placeholder, autoFocus }: TextareaProps): ReactElement {
  const length = value.length;
  return (
    <Field
      label={label}
      hint={hint}
      error={error}
      counter={
        <span className={length > max ? "is-over" : undefined}>
          {length}&nbsp;/&nbsp;{max}
        </span>
      }
    >
      {({ id, describedBy, invalid }) => (
        <textarea
          id={id}
          className="input textarea"
          rows={rows}
          value={value}
          placeholder={placeholder}
          autoFocus={autoFocus}
          aria-describedby={describedBy}
          aria-invalid={invalid || undefined}
          onChange={(event: ChangeEvent<HTMLTextAreaElement>) => onChange(event.target.value)}
        />
      )}
    </Field>
  );
}
