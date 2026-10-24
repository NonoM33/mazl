// Routeur par hash : « #/signalements/42?statut=pending ».
import { SECTIONS, type SectionId } from "./permissions";

export interface Route {
  readonly section: SectionId | null;
  readonly id: number | null;
  readonly params: Readonly<Record<string, string>>;
}

const DEFAULT_SECTION: SectionId = "tableau-de-bord";

export function parseHash(hash: string): Route {
  const raw = hash.startsWith("#") ? hash.slice(1) : hash;
  const [pathPart = "", queryPart = ""] = raw.split("?", 2);
  const segments = pathPart.split("/").filter((segment) => segment !== "");
  const params: Record<string, string> = {};
  for (const [key, value] of new URLSearchParams(queryPart)) params[key] = value;
  const first = segments[0];
  if (first === undefined) return { section: DEFAULT_SECTION, id: null, params };
  const section = SECTIONS.find((candidate) => candidate.id === first)?.id ?? null;
  const second = segments[1];
  const id = second !== undefined && /^\d+$/.test(second) ? Number(second) : null;
  return { section, id, params };
}

export function buildHash(section: SectionId, id?: number | null, params?: Readonly<Record<string, string>>): string {
  const idPart = id === undefined || id === null ? "" : `/${id}`;
  const query = new URLSearchParams(params ?? {}).toString();
  return `#/${section}${idPart}${query === "" ? "" : `?${query}`}`;
}
