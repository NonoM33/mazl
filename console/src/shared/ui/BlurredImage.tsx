import { useState, type ReactElement } from "react";
import { Icon } from "./Icon";

interface BlurredImageProps {
  readonly src: string | null;
  readonly name: string;
  readonly size?: number;
  readonly round?: boolean;
}

/** Photo de membre floutée par défaut ; un bouton accessible la révèle (et la reflou). */
export function BlurredImage({ src, name, size = 40, round = false }: BlurredImageProps): ReactElement {
  const [revealed, setRevealed] = useState(false);
  if (src === null) {
    return (
      <span className={`photo photo-empty${round ? " photo-round" : ""}`} style={{ width: size, height: size }} role="img" aria-label={`Pas de photo pour ${name}`}>
        <Icon name="user" size={Math.round(size * 0.5)} />
      </span>
    );
  }
  return (
    <button
      type="button"
      className={`photo${round ? " photo-round" : ""}${revealed ? " is-revealed" : ""}`}
      style={{ width: size, height: size }}
      aria-pressed={revealed}
      aria-label={revealed ? `Flouter la photo de ${name}` : `Afficher la photo de ${name}`}
      onClick={(event) => {
        event.stopPropagation();
        setRevealed((current) => !current);
      }}
    >
      <img src={src} alt="" width={size} height={size} loading="lazy" decoding="async" />
      {revealed ? null : (
        <span className="photo-hint" aria-hidden="true">
          <Icon name="eye" size={Math.max(12, Math.round(size * 0.32))} />
        </span>
      )}
    </button>
  );
}
