import { useEffect, useRef, useState, type RefObject } from "react";

export interface ScrollProgress {
  readonly hero: () => number;
  readonly phone: () => number;
}

const clamp01 = (value: number): number => Math.min(1, Math.max(0, value));

export function prefersMotion(): boolean {
  return !window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

export function isLightweight(): boolean {
  return window.innerWidth < 760 || window.matchMedia("(pointer: coarse)").matches;
}

// Equivalent of sections/scroll.ts: hero progress (--p), phone rotation,
// journey line and nav blur, driven by one passive scroll listener.
export function useScrollProgress(animate: boolean): ScrollProgress {
  const state = useRef({ hero: 0, phone: 0.5 });
  useEffect(() => {
    const nav = document.getElementById("nav");
    const hero = document.querySelector<HTMLElement>("[data-hero]");
    const phoneStage = document.querySelector<HTMLElement>("[data-phone-stage]");
    const journey = document.querySelector<HTMLElement>("[data-progress]");
    let queued = false;
    const update = (): void => {
      queued = false;
      const viewport = window.innerHeight;
      nav?.classList.toggle("is-stuck", window.scrollY > 8);
      if (!animate) return;
      if (hero !== null) {
        state.current.hero = clamp01(window.scrollY / Math.max(1, hero.offsetHeight - viewport));
        hero.style.setProperty("--p", state.current.hero.toFixed(4));
      }
      if (phoneStage !== null) {
        const rect = phoneStage.getBoundingClientRect();
        state.current.phone = clamp01((viewport - rect.top) / (viewport + rect.height));
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
    return () => {
      window.removeEventListener("scroll", queue);
      window.removeEventListener("resize", queue);
    };
  }, [animate]);
  return { hero: () => state.current.hero, phone: () => state.current.phone };
}

// Equivalent of sections/reveal.ts.
export function useReveal(animate: boolean): void {
  useEffect(() => {
    const targets = document.querySelectorAll<HTMLElement>("[data-reveal], [data-chips]");
    for (const group of document.querySelectorAll<HTMLElement>("[data-chips]")) {
      group.querySelectorAll<HTMLElement>(".chip").forEach((chip, index) => chip.style.setProperty("--i", String(index)));
    }
    if (!animate || !("IntersectionObserver" in window)) {
      for (const target of targets) target.classList.add("is-in");
      return;
    }
    const observer = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        entry.target.classList.add("is-in");
        observer.unobserve(entry.target);
      }
    }, { threshold: 0.18, rootMargin: "0px 0px -6% 0px" });
    for (const target of targets) observer.observe(target);
    return () => observer.disconnect();
  }, [animate]);
}

interface Disposable {
  readonly dispose: () => void;
}

// Mounts a framework-independent scene on a canvas; false once WebGL is known to be missing.
export function useScene(
  canvas: RefObject<HTMLCanvasElement | null>,
  create: (canvas: HTMLCanvasElement) => Disposable | null,
): { readonly ready: boolean; readonly failed: boolean } {
  const [status, setStatus] = useState<"loading" | "ready" | "failed">("loading");
  const factory = useRef(create);
  factory.current = create;
  useEffect(() => {
    const element = canvas.current;
    if (element === null) return;
    const scene = factory.current(element);
    if (scene === null) {
      setStatus("failed");
      return;
    }
    const frame = requestAnimationFrame(() => requestAnimationFrame(() => setStatus("ready")));
    return () => {
      cancelAnimationFrame(frame);
      scene.dispose();
    };
  }, [canvas]);
  return { ready: status === "ready", failed: status === "failed" };
}
