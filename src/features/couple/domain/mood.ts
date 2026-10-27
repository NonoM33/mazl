import { z } from "zod";

export const MOODS = ["great", "good", "meh", "talk"] as const;
export type Mood = (typeof MOODS)[number];
export const moodBody = z.object({ mood: z.enum(MOODS) }).strict();
