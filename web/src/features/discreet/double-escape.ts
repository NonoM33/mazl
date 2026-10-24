// Two Escape presses within 400 ms toggle the discreet mode
// (docs/web/adr/W10-shabbat-discret.md). Pure, so it can be tested.
export const DOUBLE_ESCAPE_MS = 400;

export function createDoubleEscape(onDouble: () => void, now: () => number = () => performance.now()) {
  let last = Number.NEGATIVE_INFINITY;
  return (key: string): boolean => {
    if (key !== "Escape") return false;
    const at = now();
    if (at - last <= DOUBLE_ESCAPE_MS) {
      last = Number.NEGATIVE_INFINITY;
      onDouble();
      return true;
    }
    last = at;
    return false;
  };
}
