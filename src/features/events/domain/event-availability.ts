// Whether members may register for an event. A "coming soon" event is shown
// with its date, place and price, but every registration is refused until an
// administrator opens it; members may ask to be told when that happens.
export const EVENT_AVAILABILITIES = ["open", "coming_soon"] as const;

export type EventAvailability = (typeof EVENT_AVAILABILITIES)[number];

export function isEventAvailability(value: unknown): value is EventAvailability {
  return typeof value === "string" && (EVENT_AVAILABILITIES as readonly string[]).includes(value);
}

// Code of the refusal of a registration on a "coming soon" event: the app and
// the web client read it to show « Bientôt disponible ».
export const EVENT_COMING_SOON_CODE = "event_coming_soon";
// Code of an alert asked for an event that is already open.
export const EVENT_ALREADY_OPEN_CODE = "event_already_open";
