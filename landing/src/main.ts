import { createFlameScene, type FlameScene } from "./scene/flame";
import { createHeroScene, type HeroScene } from "./scene/hero";
import { createOutroScene, type OutroScene } from "./scene/outro";
import { createPhoneScene, type PhoneScene } from "./scene/phone";
import { paintDecorativeCode } from "./sections/qr";
import { setupReveal } from "./sections/reveal";
import { setupScroll } from "./sections/scroll";

// Everything is real HTML first; the scenes are an enhancement. Reduced motion
// freezes each scene into a still image and turns every scroll effect off.
const animate = !window.matchMedia("(prefers-reduced-motion: reduce)").matches;
const lightweight = window.innerWidth < 760 || window.matchMedia("(pointer: coarse)").matches;

setupReveal(animate);
paintDecorativeCode();
const scroll = setupScroll(animate);

const scenes: { dispose: () => void }[] = [];
function mount<T extends { dispose: () => void }>(canvas: HTMLCanvasElement | null, create: (canvas: HTMLCanvasElement) => T | null): void {
  if (canvas === null) return;
  const scene = create(canvas);
  if (scene === null) canvas.hidden = true; // no WebGL: the CSS background stays
  else scenes.push(scene);
}

mount<HeroScene>(document.querySelector<HTMLCanvasElement>("[data-hero-canvas]"), (canvas) =>
  createHeroScene({ canvas, animate, lightweight, progress: scroll.hero }));
mount<PhoneScene>(document.querySelector<HTMLCanvasElement>("[data-phone-canvas]"), (canvas) =>
  createPhoneScene({ canvas, animate, progress: scroll.phone }));
mount<FlameScene>(document.querySelector<HTMLCanvasElement>("[data-flame-canvas]"), (canvas) =>
  createFlameScene({ canvas, animate, lightweight }));

mount<OutroScene>(document.querySelector<HTMLCanvasElement>("[data-outro-canvas]"), (canvas) =>
  createOutroScene({ canvas, animate, lightweight, progress: scroll.outro }));

window.addEventListener("pagehide", () => {
  for (const scene of scenes) scene.dispose();
});
