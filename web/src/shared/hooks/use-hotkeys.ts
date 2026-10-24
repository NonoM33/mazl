import { useEffect, useEffectEvent } from "react";

// Keyboard shortcuts of the web (docs/web/CADRAGE.md §2). Single keys are
// ignored while the member types in a field; "mod+k" and "escape" are not.

export type HotkeyMap = Readonly<Record<string, (event: KeyboardEvent) => void>>;

export function isTypingTarget(target: EventTarget | null): boolean {
  if (!(target instanceof HTMLElement)) return false;
  return target.isContentEditable || ["INPUT", "TEXTAREA", "SELECT"].includes(target.tagName);
}

export function hotkeyName(event: Pick<KeyboardEvent, "key" | "metaKey" | "ctrlKey" | "altKey" | "shiftKey">): string {
  const key = event.key.length === 1 ? event.key.toLowerCase() : event.key.toLowerCase();
  const mod = event.metaKey || event.ctrlKey ? "mod+" : "";
  const alt = event.altKey ? "alt+" : "";
  return `${mod}${alt}${key}`;
}

const ALWAYS = new Set(["mod+k", "escape"]);

export function useHotkeys(map: HotkeyMap, enabled = true): void {
  const onKey = useEffectEvent((event: KeyboardEvent) => {
    if (event.defaultPrevented || event.isComposing) return;
    const name = hotkeyName(event);
    const handler = map[name];
    if (!handler) return;
    if (isTypingTarget(event.target) && !ALWAYS.has(name)) return;
    event.preventDefault();
    handler(event);
  });
  useEffect(() => {
    if (!enabled) return undefined;
    const listener = (event: KeyboardEvent) => { onKey(event); };
    window.addEventListener("keydown", listener);
    return () => { window.removeEventListener("keydown", listener); };
  }, [enabled]);
}
