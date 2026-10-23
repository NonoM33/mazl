import type { Challenge } from "./types";

// "front" first, then "left" and "right" in a random order, optionally a
// second "front" at the end. The server picks the order so that a recorded
// clip cannot be replayed: the sequence is unknown until the session starts.
export function generateChallenges(random: () => number): Challenge[] {
  const sides: Challenge[] = random() < 0.5 ? ["left", "right"] : ["right", "left"];
  const withFinalFront = random() >= 0.5;
  return withFinalFront ? ["front", ...sides, "front"] : ["front", ...sides];
}
