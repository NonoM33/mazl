import { useState, type CSSProperties } from "react";
import { useDiscreet } from "../discreet-context";

// A member photo. Signed URLs expire after an hour: when one fails to load,
// `onExpired` lets the owner reload its data instead of showing a broken image.
// Without a URL, a flat tint chosen from the seed (photoTints, no gradient).

const TINTS = ["var(--ph1)", "var(--ph2)", "var(--ph3)", "var(--ph4)", "var(--ph5)"] as const;

export function tintFor(seed: number): string {
  return TINTS[Math.abs(seed) % TINTS.length] ?? "var(--ph1)";
}

interface PhotoProps {
  readonly src: string | null | undefined;
  readonly alt: string;
  readonly seed: number;
  readonly radius?: number;
  readonly className?: string;
  readonly style?: CSSProperties;
  readonly initial?: string;
  readonly onExpired?: () => void;
}

export function Photo({ src, alt, seed, radius = 24, className, style, initial, onExpired }: PhotoProps) {
  const [failed, setFailed] = useState<string | null>(null);
  const { active: discreet } = useDiscreet();
  const showImage = Boolean(src) && failed !== src && !discreet;
  const box: CSSProperties = { position: "relative", overflow: "hidden", borderRadius: radius, background: tintFor(seed), ...style };
  return (
    <div className={className} style={box}>
      {showImage ? (
        <img
          src={src ?? undefined}
          alt={alt}
          draggable={false}
          referrerPolicy="no-referrer"
          style={{ width: "100%", height: "100%", objectFit: "cover" }}
          onError={() => {
            setFailed(src ?? null);
            onExpired?.();
          }}
        />
      ) : (
        <span aria-hidden="true" style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center", fontSize: "min(40%, 96px)", fontWeight: 700, color: "var(--text)", opacity: 0.08 }}>
          {initial ?? ""}
        </span>
      )}
      {!showImage && <span className="visually-hidden">{alt}</span>}
    </div>
  );
}

export function Avatar({ src, name, seed, size = 48, onExpired }: { readonly src: string | null | undefined; readonly name: string; readonly seed: number; readonly size?: number; readonly onExpired?: () => void }) {
  return <Photo src={src} alt={name} seed={seed} radius={size / 2} initial={name.charAt(0).toUpperCase()} style={{ width: size, height: size, flex: "none" }} onExpired={onExpired} />;
}
