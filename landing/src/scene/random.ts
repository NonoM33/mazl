// Small seeded generator: the scenes look the same on every load (and in the
// captures) instead of depending on Math.random.
export function seeded(seed: number): () => number {
  let state = seed >>> 0;
  return () => {
    state = (state + 0x6d2b79f5) >>> 0;
    let t = state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// Standard normal sample (Box-Muller), clamped so no point flies off screen.
export function gaussian(random: () => number): number {
  const u = Math.max(random(), 1e-6);
  const v = random();
  return Math.max(-2.6, Math.min(2.6, Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v)));
}
