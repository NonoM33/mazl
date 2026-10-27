// Corps des requêtes d'écriture de la conciergerie, construits à un seul endroit : l'écran et le test de contrat les prennent ici.
// Ils ont la forme du contrat docs/couple/ESPACE-COUPLE.md §7 : `PATCH { status?, staffNote?, assignedTo? }` et `POST messages { text }`.
import type { RequestPatch, StaffMessageBody } from "./types";

export const markBookedRequest = (): RequestPatch => ({ status: "booked" });

export const closeRequest = (): RequestPatch => ({ status: "closed" });

export const staffNoteRequest = (note: string): RequestPatch => ({ staffNote: note.trim() });

/** `null` retire l'assignation. */
export const assignRequest = (assignee: string | null): RequestPatch => ({ assignedTo: assignee });

export const staffMessageRequest = (text: string): StaffMessageBody => ({ text: text.trim() });
