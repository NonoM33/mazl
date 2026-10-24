// Photo position indicator of the card (MOUVEMENT.md: slides in 200 ms).
export function PhotoDots({ count, index }: { readonly count: number; readonly index: number }) {
  if (count < 2) return null;
  return (
    <div className="photo-dots" aria-hidden="true">
      {Array.from({ length: count }, (_, dot) => <span key={dot} className={dot === index ? "on" : undefined} />)}
    </div>
  );
}
