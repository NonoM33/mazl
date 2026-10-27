// One passive scroll listener drives everything tied to the scroll position:
// the navigation bar's hairline, the hero progress (--p: the phone tilts, the
// notifications drift apart), the closing wordmark (--o) and any extra effect.

export type ScrollEffect = (viewport: number) => void;

const clamp01 = (value: number): number => Math.min(1, Math.max(0, value));

export function setupScroll(animate: boolean, effects: readonly ScrollEffect[]): void {
  const nav = document.getElementById("nav");
  const hero = document.querySelector<HTMLElement>("[data-hero]");
  const outro = document.querySelector<HTMLElement>("[data-outro-word]");
  let queued = false;

  const update = (): void => {
    queued = false;
    const viewport = window.innerHeight;
    nav?.classList.toggle("is-stuck", window.scrollY > 8);
    if (!animate) return;
    if (hero !== null) hero.style.setProperty("--p", clamp01(window.scrollY / Math.max(1, hero.offsetHeight)).toFixed(4));
    if (outro !== null) {
      const rect = outro.getBoundingClientRect();
      outro.style.setProperty("--o", clamp01((viewport - rect.top) / Math.max(1, rect.height)).toFixed(4));
    }
    for (const effect of effects) effect(viewport);
  };
  const queue = (): void => {
    if (queued) return;
    queued = true;
    requestAnimationFrame(update);
  };
  window.addEventListener("scroll", queue, { passive: true });
  window.addEventListener("resize", queue);
  update();
}
