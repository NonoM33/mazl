import type { ReciprocityMode } from "./params";

export function fuse(forward: number, backward: number, mode: ReciprocityMode): number {
  switch (mode) {
    case "harmonic":
      return forward + backward === 0 ? 0 : (2 * forward * backward) / (forward + backward);
    case "geometric":
      return Math.sqrt(forward * backward);
    case "min":
      return Math.min(forward, backward);
    case "forward_only":
      return forward;
  }
}
