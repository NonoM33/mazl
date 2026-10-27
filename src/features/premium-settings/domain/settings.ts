import { z } from "zod";

// What a member decides about their own mazl+ features (docs/premium/MONETISATION.md
// sections 2, 3 and 4). The server decides what is in force: a setting that needs
// mazl+ is reported and applied only while the subscription is active.

export const PLUS_REQUIRED = "mazl_plus_required";

export interface Passport {
  readonly city: string;
  readonly latitude: number;
  readonly longitude: number;
}

// What is stored, whatever the subscription says.
export interface StoredSettings {
  readonly passport: Passport | null;
  readonly incognito: boolean;
  readonly sendReadReceipts: boolean;
}

// What is in force for the member right now.
export interface EffectiveSettings extends StoredSettings {
  readonly isPlus: boolean;
}

export const DEFAULT_SETTINGS: StoredSettings = { passport: null, incognito: false, sendReadReceipts: true };

const CITY_MAX = 80;
// eslint-disable-next-line no-control-regex -- the point is to refuse control characters
const CONTROL_CHARACTERS = /[\u0000-\u001f\u007f]/;

const cityName = z
  .string()
  .trim()
  .min(1)
  .max(CITY_MAX)
  .refine((city) => !CONTROL_CHARACTERS.test(city), "city: control characters");

export const passportSchema = z.object({
  city: cityName,
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
});

// A passport to switch on, or null to come back home.
export const passportBodySchema = passportSchema.nullable();
export const incognitoBodySchema = z.object({ enabled: z.boolean() });
export const readReceiptsBodySchema = z.object({ enabled: z.boolean() });

// The settings as the app reads them.
export function settingsView(settings: EffectiveSettings) {
  return {
    is_plus: settings.isPlus,
    passport: settings.passport,
    incognito: settings.incognito,
    send_read_receipts: settings.sendReadReceipts,
  };
}
