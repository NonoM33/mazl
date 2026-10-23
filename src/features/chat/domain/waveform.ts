import { z } from "zod";

// The waveform is computed by the app while recording: 48 integers in 0..100
// (CONTRAT.md §1). It reaches the server as a JSON string in a multipart field.

export const WAVEFORM_POINTS = 48;

const waveformSchema = z.array(z.number().int().min(0).max(100)).length(WAVEFORM_POINTS);

export function parseWaveform(raw: string): number[] | null {
  let value: unknown;
  try {
    value = JSON.parse(raw);
  } catch {
    return null;
  }
  const parsed = waveformSchema.safeParse(value);
  return parsed.success ? parsed.data : null;
}
