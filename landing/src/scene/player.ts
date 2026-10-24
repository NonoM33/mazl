import { WebGLRenderer } from "three";

export interface PlayerOptions {
  readonly canvas: HTMLCanvasElement;
  readonly host: HTMLElement;
  readonly maxPixelRatio: number;
  readonly transparent: boolean;
  // Opaque background colour, when the canvas is not transparent.
  readonly background?: number;
  // Called whenever the drawing buffer changes size (CSS pixels).
  readonly onResize: (width: number, height: number) => void;
  // Called for each frame while the scene is on screen; draws into `renderer`.
  readonly onFrame: (renderer: WebGLRenderer, seconds: number, delta: number) => void;
}

export interface Player {
  readonly pixelRatio: () => number;
  // Draws one frame at the given time, whatever the visibility (still image).
  readonly renderStill: (seconds: number) => void;
  readonly dispose: () => void;
}

// Owns a renderer and its loop: it only runs while the host is on screen and
// the tab is visible, follows the host's size, and releases the GPU on dispose.
// Returns null when WebGL is unavailable, so the page falls back to its CSS.
export function createPlayer(options: PlayerOptions, animate: boolean): Player | null {
  let renderer: WebGLRenderer;
  try {
    renderer = new WebGLRenderer({ canvas: options.canvas, alpha: options.transparent, antialias: true, powerPreference: "high-performance" });
  } catch {
    return null;
  }
  if (!renderer.getContext()) return null;
  if (options.transparent) renderer.setClearColor(0x000000, 0);
  else renderer.setClearColor(options.background ?? 0x000000, 1);

  let ratio = 1;
  let width = 0;
  let height = 0;
  let onScreen = false;
  let frame = 0;
  let previous = 0;
  let clock = 0;
  let disposed = false;

  const fit = (): void => {
    const rect = options.host.getBoundingClientRect();
    const w = Math.max(1, Math.round(rect.width));
    const h = Math.max(1, Math.round(rect.height));
    ratio = Math.min(window.devicePixelRatio || 1, options.maxPixelRatio);
    if (w === width && h === height && renderer.getPixelRatio() === ratio) return;
    width = w;
    height = h;
    renderer.setPixelRatio(ratio);
    renderer.setSize(w, h, false);
    options.onResize(w, h);
    if (!animate) options.onFrame(renderer, clock, 0);
  };

  const tick = (now: number): void => {
    frame = 0;
    if (disposed || !onScreen || document.hidden) return;
    const delta = previous === 0 ? 0 : Math.min((now - previous) / 1000, 0.1);
    previous = now;
    clock += delta;
    options.onFrame(renderer, clock, delta);
    frame = requestAnimationFrame(tick);
  };

  const wake = (): void => {
    if (!animate || frame !== 0 || disposed || !onScreen || document.hidden) return;
    previous = 0;
    frame = requestAnimationFrame(tick);
  };

  const sizeObserver = new ResizeObserver(fit);
  sizeObserver.observe(options.host);
  const visibility = new IntersectionObserver((entries) => {
    onScreen = entries.some((entry) => entry.isIntersecting);
    wake();
  }, { rootMargin: "80px 0px" });
  visibility.observe(options.host);
  document.addEventListener("visibilitychange", wake);
  fit();

  return {
    pixelRatio: () => ratio,
    renderStill: (seconds) => {
      clock = seconds;
      options.onFrame(renderer, seconds, 0);
    },
    dispose: () => {
      disposed = true;
      if (frame !== 0) cancelAnimationFrame(frame);
      sizeObserver.disconnect();
      visibility.disconnect();
      document.removeEventListener("visibilitychange", wake);
      renderer.dispose();
      renderer.forceContextLoss();
    },
  };
}
