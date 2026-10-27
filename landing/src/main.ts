import { paintDecorativeCode } from "./sections/qr";
import { setupReveal } from "./sections/reveal";
import { setupScroll } from "./sections/scroll";
import { setupStory } from "./sections/story";
import { setupWords } from "./sections/words";

// Everything is real HTML first; the motion is an enhancement. Reduced motion
// shows every element at once and turns the scroll-linked effects off.
const animate = !window.matchMedia("(prefers-reduced-motion: reduce)").matches;

setupReveal(animate);
paintDecorativeCode();
setupStory();
const onScroll = [setupWords(animate)];
setupScroll(animate, onScroll);
