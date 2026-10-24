// One passive scroll listener drives everything tied to the scroll position:
// the hero progress (CSS variable --p and the scene), the phone's rotation,
// the journey line, and the navigation bar's blur.

export interface ScrollState {
  readonly hero: () => number;
  readonly phone: () => number;
}

const clamp01 = (value: number): number => Math.min(1, Math.max(0, value));

export function setupScroll(animate: boolean): ScrollState {
  const nav = document.getElementById("nav");
  const hero = document.querySelector<HTMLElement>("[data-hero]");
  const phoneStage = document.querySelector<HTMLElement>("[data-phone-stage]");
  const journey = document.querySelector<HTMLElement>("[data-progress]");
  const state = { hero: 0, phone: 0.5 };
  let queued = false;

  const update = (): void => {
    queued = false;
    const viewport = window.innerHeight;
    nav?.classList.toggle("is-stuck", window.scrollY > 8);
    if (!animate) return;
    if (hero !== null) {
      state.hero = clamp01(window.scrollY / Math.max(1, hero.offsetHeight - viewport));
      hero.style.setProperty("--p", state.hero.toFixed(4));
    }
    if (phoneStage !== null) {
      const rect = phoneStage.getBoundingClientRect();
      state.phone = clamp01((viewport - rect.top) / (viewport + rect.height));
    }
    if (journey !== null) {
      const rect = journey.getBoundingClientRect();
      journey.style.setProperty("--p", clamp01((viewport * 0.8 - rect.top) / Math.max(1, rect.height + viewport * 0.1)).toFixed(4));
    }
  };
  const queue = (): void => {
    if (queued) return;
    queued = true;
    requestAnimationFrame(update);
  };
  window.addEventListener("scroll", queue, { passive: true });
  window.addEventListener("resize", queue);
  update();
  return { hero: () => state.hero, phone: () => state.phone };
}
