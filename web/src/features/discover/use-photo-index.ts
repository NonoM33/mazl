import { useState } from "react";
import { stepPhoto } from "./photos";

// Photo shown on the top card; it starts over for each new card.
export function usePhotoIndex(userId: number | undefined, count: number) {
  const [state, setState] = useState({ userId, index: 0 });
  const index = state.userId === userId ? Math.min(state.index, Math.max(0, count - 1)) : 0;
  const step = (delta: 1 | -1, wrap = false) => setState({ userId, index: stepPhoto(index, count, delta, wrap) });
  return { index, step };
}
