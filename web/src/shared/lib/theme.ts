// Light or dark like the system, unless the member chose. The choice is a
// comfort setting kept in this browser only.

export type ThemeChoice = "system" | "light" | "dark";
const KEY = "mazl.theme";

export function readThemeChoice(): ThemeChoice {
  const stored = window.localStorage.getItem(KEY);
  return stored === "light" || stored === "dark" ? stored : "system";
}

export function applyTheme(choice: ThemeChoice = readThemeChoice()): void {
  const dark = choice === "dark" || (choice === "system" && window.matchMedia("(prefers-color-scheme: dark)").matches);
  document.documentElement.dataset.theme = dark ? "dark" : "light";
}

export function saveThemeChoice(choice: ThemeChoice): void {
  if (choice === "system") window.localStorage.removeItem(KEY);
  else window.localStorage.setItem(KEY, choice);
  applyTheme(choice);
}

export function watchSystemTheme(): () => void {
  const query = window.matchMedia("(prefers-color-scheme: dark)");
  const onChange = () => applyTheme();
  query.addEventListener("change", onChange);
  return () => query.removeEventListener("change", onChange);
}
