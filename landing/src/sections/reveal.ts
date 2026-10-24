// Content appears as it enters the viewport. Without IntersectionObserver, or
// with reduced motion, everything is shown at once (the CSS also shows it).
export function setupReveal(animate: boolean): void {
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
}
