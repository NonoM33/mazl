import { useLayoutEffect, useRef, useState, type RefObject } from "react";
import type { ThreadMessage } from "./thread-model";

// Scroll behaviour of the thread: open at the bottom, keep the position when an
// older page is added above, follow new messages only while at the bottom
// (otherwise count them for the « ↓ N nouveaux » button). The count is derived
// from the last message the member has had in view.

const NEAR_BOTTOM_PX = 120;
const keyOf = (item: ThreadMessage | undefined): string => (item ? (item.view.client_id ?? String(item.view.id)) : "");
const nearBottom = (element: HTMLElement): boolean => element.scrollHeight - element.scrollTop - element.clientHeight < NEAR_BOTTOM_PX;

export function useThreadScroll(box: RefObject<HTMLDivElement | null>, items: readonly ThreadMessage[], myId: number) {
  const previous = useRef({ first: "", last: "", height: 0, opened: false });
  const [seenLast, setSeenLast] = useState("");

  useLayoutEffect(() => {
    const element = box.current;
    if (!element || items.length === 0) return;
    const before = previous.current;
    const first = keyOf(items[0]);
    const last = keyOf(items[items.length - 1]);
    if (!before.opened) element.scrollTo({ top: element.scrollHeight });
    else if (before.first !== first && before.last === last) element.scrollBy({ top: element.scrollHeight - before.height });
    else if (before.last !== last && (nearBottom(element) || items[items.length - 1]?.view.sender_id === myId)) element.scrollTo({ top: element.scrollHeight });
    previous.current = { first, last, height: element.scrollHeight, opened: true };
  }, [box, items, myId]);

  const onScroll = () => {
    const element = box.current;
    if (element && nearBottom(element)) setSeenLast(keyOf(items[items.length - 1]));
  };
  const jumpToBottom = () => box.current?.scrollTo({ top: box.current.scrollHeight, behavior: "smooth" });

  const seenIndex = items.findIndex((item) => keyOf(item) === seenLast);
  const unseen = seenLast === "" || seenIndex === -1 ? 0 : items.slice(seenIndex + 1).filter((item) => item.view.sender_id !== myId).length;
  return { unseen, onScroll, jumpToBottom };
}
