import type { ChangeEvent, ReactElement } from "react";
import { Field } from "./Field";

export interface Option<V extends string> {
  readonly value: V;
  readonly label: string;
}

interface SelectProps<V extends string> {
  readonly label: string;
  readonly value: V | "";
  readonly options: readonly Option<V>[];
  readonly onChange: (value: V | "") => void;
  readonly placeholder?: string;
  readonly hint?: string;
  readonly error?: string | undefined;
  readonly compact?: boolean;
}

export function Select<V extends string>({ label, value, options, onChange, placeholder, hint, error, compact = false }: SelectProps<V>): ReactElement {
  const handle = (event: ChangeEvent<HTMLSelectElement>): void => {
    const next = options.find((option) => option.value === event.target.value);
    onChange(next === undefined ? "" : next.value);
  };
  return (
    <Field label={label} hint={hint} error={error}>
      {({ id, describedBy, invalid }) => (
        <select id={id} className={`input select${compact ? " select-compact" : ""}`} value={value} onChange={handle} aria-describedby={describedBy} aria-invalid={invalid || undefined}>
          {placeholder !== undefined ? <option value="">{placeholder}</option> : null}
          {options.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
      )}
    </Field>
  );
}
