import { PARIS, type Place, type RestOptions } from "./rest-windows";

// The Shabbat pause is a comfort setting kept in this browser only
// (docs/web/adr/W10-shabbat-discret.md), with the app's defaults.

export interface ShabbatSettings extends RestOptions { readonly enabled: boolean }
export const DEFAULT_SHABBAT: ShabbatSettings = { enabled: true, includeHolidays: true, bufferMin: 18 };
const KEY = "mazl.shabbat";

export function readShabbatSettings(): ShabbatSettings {
  try {
    const parsed: unknown = JSON.parse(window.localStorage.getItem(KEY) ?? "null");
    if (typeof parsed !== "object" || parsed === null) return DEFAULT_SHABBAT;
    const value = parsed as Record<string, unknown>;
    const buffer = typeof value.bufferMin === "number" && [0, 5, 10, 15, 18, 20, 25, 30].includes(value.bufferMin) ? value.bufferMin : DEFAULT_SHABBAT.bufferMin;
    return {
      enabled: typeof value.enabled === "boolean" ? value.enabled : DEFAULT_SHABBAT.enabled,
      includeHolidays: typeof value.includeHolidays === "boolean" ? value.includeHolidays : DEFAULT_SHABBAT.includeHolidays,
      bufferMin: buffer,
    };
  } catch {
    return DEFAULT_SHABBAT;
  }
}

export function saveShabbatSettings(settings: ShabbatSettings): void {
  window.localStorage.setItem(KEY, JSON.stringify(settings));
  window.dispatchEvent(new Event("mazl:shabbat"));
}

// The last position the phone saved (fuzzed to about 1 km, enough for zmanim),
// in the browser's time zone; Paris otherwise, like the app.
export function placeFromProfile(latitude: string | null | undefined, longitude: string | null | undefined, city: string | null | undefined): Place {
  const lat = Number.parseFloat(latitude ?? "");
  const lng = Number.parseFloat(longitude ?? "");
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return PARIS;
  const name = city?.trim() ?? "";
  return { name: name.length > 0 ? name : "Votre ville", latitude: lat, longitude: lng, timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone };
}
