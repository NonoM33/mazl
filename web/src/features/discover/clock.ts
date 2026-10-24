// Countdown helpers: pure, so the arithmetic is tested without a clock.

export function remainingMs(target: string | number | Date, now: number): number {
  const end = target instanceof Date ? target.getTime() : typeof target === "number" ? target : Date.parse(target);
  return Number.isFinite(end) ? Math.max(0, end - now) : 0;
}

const pad = (value: number): string => String(value).padStart(2, "0");

// « HH:MM:SS », rounding up so the display never reads 00:00:00 before the end.
export function formatHms(ms: number): string {
  const total = Math.ceil(Math.max(0, ms) / 1000);
  return `${pad(Math.floor(total / 3600))}:${pad(Math.floor((total % 3600) / 60))}:${pad(total % 60)}`;
}

// « mm:ss » (a boost lasts 30 minutes).
export function formatMinutes(ms: number): string {
  const total = Math.ceil(Math.max(0, ms) / 1000);
  return `${pad(Math.floor(total / 60))}:${pad(total % 60)}`;
}
