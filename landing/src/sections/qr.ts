const SIZE = 15;

// Small deterministic generator (mulberry32): the same pattern on every visit.
function seeded(seed: number): () => number {
  let state = seed >>> 0;
  return () => {
    state = (state + 0x6d2b79f5) >>> 0;
    let t = state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// Decorative code for the computer mock-up: finder squares and a fixed pattern.
// It is not a real QR code and carries nothing.
export function paintDecorativeCode(): void {
  const grid = document.querySelector<HTMLElement>("[data-qr]");
  if (grid === null) return;
  const random = seeded(613);
  const inFinder = (x: number, y: number): boolean => (x < 5 && y < 5) || (x > SIZE - 6 && y < 5) || (x < 5 && y > SIZE - 6);
  const finderOn = (x: number, y: number): boolean => {
    const fx = x < 5 ? x : x - (SIZE - 5);
    const fy = y < 5 ? y : y - (SIZE - 5);
    const edge = fx === 0 || fx === 4 || fy === 0 || fy === 4;
    return edge || (fx === 2 && fy === 2);
  };
  const cells: HTMLElement[] = [];
  for (let y = 0; y < SIZE; y++) {
    for (let x = 0; x < SIZE; x++) {
      const cell = document.createElement("i");
      const on = inFinder(x, y) ? finderOn(x, y) : random() > 0.52;
      if (!on) cell.className = "off";
      cells.push(cell);
    }
  }
  grid.replaceChildren(...cells);
}
