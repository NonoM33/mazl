import { exportOutcome, type ExportOutcome } from "./export-outcome";

// The export is a file, not JSON the client reads: fetched same-origin with
// the web header, read as a Blob, handed to the browser through an object URL.

export async function downloadExport(): Promise<ExportOutcome> {
  const response = await fetch("/api/users/me/export", { headers: { "X-Mazl-Web": "1" }, credentials: "same-origin", cache: "no-store" });
  const outcome = exportOutcome(response.status);
  if (outcome !== "done") return outcome;
  const url = URL.createObjectURL(await response.blob());
  const link = document.createElement("a");
  link.href = url;
  link.download = "mazl-export.json";
  document.body.append(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(url);
  return "done";
}
