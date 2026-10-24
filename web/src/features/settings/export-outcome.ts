// Outcome wording of the export.
// The export is a file, not JSON the client reads: fetched same-origin with
// the web header, read as a Blob, handed to the browser through an object URL.

export type ExportOutcome = "done" | "rate_limited" | "unavailable" | "failed";

export function exportOutcome(status: number): ExportOutcome {
  if (status >= 200 && status < 300) return "done";
  if (status === 429) return "rate_limited";
  if (status === 404) return "unavailable";
  return "failed";
}

export const exportMessage = (outcome: Exclude<ExportOutcome, "done">): string => {
  if (outcome === "rate_limited") return "3 exports par jour au plus. Réessayez demain.";
  if (outcome === "unavailable") return "L'export n'est pas disponible pour le moment.";
  return "L'export n'a pas pu être généré. Réessayez dans un instant.";
};
