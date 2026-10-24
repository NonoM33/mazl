// Human label of a browser, shown on the phone before the member approves a
// sign-in ("Chrome sur macOS"). Order matters: Edge and Chrome both say Chrome,
// Chrome says Safari.

function browserOf(ua: string): string | null {
  if (/Edg(e|A|iOS)?\//.test(ua)) return "Edge";
  if (/Firefox\/|FxiOS\//.test(ua)) return "Firefox";
  if (/OPR\/|Opera/.test(ua)) return "Opera";
  if (/Chrome\/|CriOS\//.test(ua)) return "Chrome";
  if (/Safari\//.test(ua) && /Version\//.test(ua)) return "Safari";
  return null;
}

function systemOf(ua: string): string | null {
  if (/Windows/.test(ua)) return "Windows";
  if (/Android/.test(ua)) return "Android";
  if (/iPhone|iPad|iPod/.test(ua)) return "iOS";
  if (/Mac OS X|Macintosh/.test(ua)) return "macOS";
  if (/CrOS/.test(ua)) return "ChromeOS";
  if (/Linux|X11/.test(ua)) return "Linux";
  return null;
}

export const UNKNOWN_BROWSER = "Navigateur inconnu";

export function browserLabel(userAgent: string | null | undefined): string {
  const ua = userAgent ?? "";
  const browser = browserOf(ua);
  if (!browser) return UNKNOWN_BROWSER;
  const system = systemOf(ua);
  return system ? `${browser} sur ${system}` : browser;
}
