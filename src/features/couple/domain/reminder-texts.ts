import { localParts } from "./local-time";
import type { ReminderPlan } from "./reminders";

// Push texts of the reminders: never a name, never the title of a date or of a
// custom ritual (it may be intimate).

const TITLE = "Rappel de couple";

export function reminderText(plan: ReminderPlan, timeZone: string): { title: string; message: string } {
  if (plan.source === "date") {
    return {
      title: TITLE,
      message: plan.daysAway === 1 ? "C'est demain : une date importante pour vous deux." : `Une date importante pour vous deux approche, dans ${String(plan.daysAway)} jours.`,
    };
  }
  if (plan.kind === "shabbat") {
    const at = localParts(plan.startsAt, timeZone);
    const time = `${String(at.hour).padStart(2, "0")}:${String(at.minute).padStart(2, "0")}`;
    return { title: TITLE, message: `Shabbat approche : allumage des bougies à ${time}.` };
  }
  return { title: TITLE, message: "Un de vos rituels à deux commence bientôt." };
}
