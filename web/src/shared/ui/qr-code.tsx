import { encode } from "uqr";
import { useMemo } from "react";

// QR code drawn locally as SVG (no network). Ink modules on paper, with the
// quiet zone, readable in both themes.
export function QrCode({ value, size = 220, label }: { readonly value: string; readonly size?: number; readonly label: string }) {
  const path = useMemo(() => {
    const { data, size: modules } = encode(value, { ecc: "M", border: 2 });
    let d = "";
    data.forEach((row, y) => row.forEach((on, x) => { if (on) d += `M${x} ${y}h1v1h-1z`; }));
    return { d, modules };
  }, [value]);
  return (
    <svg role="img" aria-label={label} width={size} height={size} viewBox={`0 0 ${path.modules} ${path.modules}`} shapeRendering="crispEdges" style={{ background: "#fff", borderRadius: 16, display: "block" }}>
      <path d={path.d} fill="#0b0b0f" />
    </svg>
  );
}
