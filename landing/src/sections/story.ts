// The story: on a wide screen the phone stays pinned while the steps scroll by,
// and the step in the middle of the viewport picks the screen it shows. On a
// narrow screen each step gets its own copy of the phone, showing its screen.
export function setupStory(): void {
  const story = document.querySelector<HTMLElement>("[data-story]");
  const device = story?.querySelector<HTMLElement>("[data-story-device]");
  if (story === null || story === undefined || device === null || device === undefined) return;

  const steps = Array.from(story.querySelectorAll<HTMLElement>("[data-step]"));
  const screens = Array.from(device.querySelectorAll<HTMLElement>("[data-screen]"));
  const dots = Array.from(story.querySelectorAll<HTMLElement>(".story__dots li"));

  steps.forEach((step, index) => {
    const slot = step.querySelector<HTMLElement>("[data-step-device]");
    if (slot === null) return;
    const copy = device.cloneNode(true) as HTMLElement;
    copy.removeAttribute("data-story-device");
    copy.querySelectorAll<HTMLElement>("[data-screen]").forEach((screen, at) => {
      if (at === index) screen.classList.add("is-active");
      else screen.remove();
    });
    slot.setAttribute("aria-hidden", "true");
    slot.append(copy);
  });

  const show = (index: number): void => {
    steps.forEach((step, at) => step.classList.toggle("is-active", at === index));
    screens.forEach((screen, at) => screen.classList.toggle("is-active", at === index));
    dots.forEach((dot, at) => dot.classList.toggle("is-on", at === index));
  };
  show(0);
  if (!("IntersectionObserver" in window)) return;
  story.classList.add("is-live");
  const observer = new IntersectionObserver((entries) => {
    for (const entry of entries) {
      if (entry.isIntersecting) show(steps.indexOf(entry.target as HTMLElement));
    }
  }, { rootMargin: "-45% 0px -45% 0px" });
  for (const step of steps) observer.observe(step);
}
