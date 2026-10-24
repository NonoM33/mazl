import { useRef, type ClipboardEvent, type KeyboardEvent, type ReactElement } from "react";
import { CODE_LENGTH, digitsOnly } from "./validation";

interface CodeInputProps {
  readonly legend: string;
  readonly value: string;
  readonly onChange: (value: string) => void;
  readonly disabled?: boolean;
  readonly invalid?: boolean;
}

/** Six cases à un chiffre : collage géré, flèches et retour arrière, saisie semi-automatique du code. */
export function CodeInput({ legend, value, onChange, disabled = false, invalid = false }: CodeInputProps): ReactElement {
  const refs = useRef<(HTMLInputElement | null)[]>([]);
  const focusAt = (index: number): void => refs.current[Math.min(CODE_LENGTH - 1, Math.max(0, index))]?.focus();

  const setDigit = (index: number, raw: string): void => {
    const digits = digitsOnly(raw);
    if (digits === "") {
      onChange(value.slice(0, index) + value.slice(index + 1));
      return;
    }
    const next = digitsOnly(value.slice(0, index) + digits + value.slice(index + 1));
    onChange(next);
    focusAt(index + digits.length);
  };

  const onPaste = (event: ClipboardEvent<HTMLInputElement>): void => {
    event.preventDefault();
    const pasted = digitsOnly(event.clipboardData.getData("text"));
    if (pasted === "") return;
    onChange(pasted);
    focusAt(pasted.length);
  };

  const onKeyDown = (event: KeyboardEvent<HTMLInputElement>, index: number): void => {
    if (event.key === "Backspace" && (value[index] ?? "") === "") {
      event.preventDefault();
      onChange(value.slice(0, Math.max(0, index - 1)) + value.slice(index));
      focusAt(index - 1);
    } else if (event.key === "ArrowLeft") {
      event.preventDefault();
      focusAt(index - 1);
    } else if (event.key === "ArrowRight") {
      event.preventDefault();
      focusAt(index + 1);
    }
  };

  return (
    <fieldset className="code-input" disabled={disabled}>
      <legend className="sr-only">{legend}</legend>
      <div className="code-cells">
        {Array.from({ length: CODE_LENGTH }, (_, index) => (
          <input
            key={index}
            ref={(node) => {
              refs.current[index] = node;
            }}
            className="code-cell"
            type="text"
            inputMode="numeric"
            pattern="[0-9]*"
            autoComplete="one-time-code"
            maxLength={CODE_LENGTH}
            value={value[index] ?? ""}
            aria-label={`Chiffre ${index + 1} sur ${CODE_LENGTH}`}
            aria-invalid={invalid || undefined}
            autoFocus={index === 0}
            onFocus={(event) => event.target.select()}
            onChange={(event) => setDigit(index, event.target.value)}
            onKeyDown={(event) => onKeyDown(event, index)}
            onPaste={onPaste}
          />
        ))}
      </div>
    </fieldset>
  );
}
