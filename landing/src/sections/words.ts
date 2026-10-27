import type { ScrollEffect } from "./scroll";

// The statement lights up word by word as it crosses the viewport, from grey to
// ink. Only the text nodes are split, so the tekhelet dot stays as it is.
export function setupWords(animate: boolean): ScrollEffect {
  const host = document.querySelector<HTMLElement>("[data-words]");
  if (host === null || !animate) return () => undefined;

  const words: HTMLElement[] = [];
  for (const node of Array.from(host.childNodes)) {
    if (node.nodeType !== Node.TEXT_NODE || node.textContent === null) continue;
    const fragment = document.createDocumentFragment();
    for (const part of node.textContent.split(/(\s+)/)) {
      if (part.trim() === "") {
        fragment.append(part);
        continue;
      }
      const word = document.createElement("span");
      word.className = "w";
      word.textContent = part;
      words.push(word);
      fragment.append(word);
    }
    node.replaceWith(fragment);
  }
  host.classList.add("is-words");

  return (viewport) => {
    const rect = host.getBoundingClientRect();
    const progress = (viewport * 0.82 - rect.top) / Math.max(1, rect.height + viewport * 0.3);
    const lit = Math.round(Math.min(1, Math.max(0, progress)) * words.length);
    words.forEach((word, index) => word.classList.toggle("is-lit", index < lit));
  };
}
