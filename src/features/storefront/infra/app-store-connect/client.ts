import { AscApiError, type AscErrorEntry, AscNetworkError, AscResponseError } from "./errors";
import type { AscTokenProvider } from "./jwt";

export const ASC_BASE_URL = "https://api.appstoreconnect.apple.com";

export type FetchLike = (input: string, init: { method: string; headers: Record<string, string>; body?: string }) => Promise<Response>;

// JSON:API resource as App Store Connect returns it. Only what the adapter reads is typed.
export interface Resource {
  readonly type: string;
  readonly id: string;
  readonly attributes?: Readonly<Record<string, unknown>>;
  readonly relationships?: Readonly<Record<string, { readonly data?: { readonly type: string; readonly id: string } | null }>>;
}

export interface Page {
  readonly data: readonly Resource[];
  readonly included: readonly Resource[];
}

interface RawDocument {
  data?: Resource | readonly Resource[];
  included?: readonly Resource[];
  links?: { next?: string };
  errors?: readonly { status?: string; code?: string; title?: string; detail?: string; source?: { pointer?: string; parameter?: string } }[];
}

const MAX_PAGES = 50;

function toEntries(raw: RawDocument["errors"]): AscErrorEntry[] {
  return (raw ?? []).map((e) => ({
    status: e.status,
    code: e.code,
    title: e.title,
    detail: e.detail,
    pointer: e.source?.pointer ?? e.source?.parameter,
  }));
}

export class AscClient {
  constructor(
    private readonly tokens: AscTokenProvider,
    private readonly fetchFn: FetchLike,
    private readonly baseUrl: string = ASC_BASE_URL,
  ) {}

  // One GET, one resource (or one page); `path` starts with /v1 or /v2.
  async getOne(path: string): Promise<{ readonly data: Resource; readonly included: readonly Resource[] }> {
    const doc = await this.request("GET", path);
    if (doc.data === undefined || Array.isArray(doc.data)) throw new AscResponseError(path, "expected a single resource");
    return { data: doc.data as Resource, included: doc.included ?? [] };
  }

  // Follows `links.next` until the end; the next link is absolute and used as is.
  async getAll(path: string): Promise<Page> {
    const data: Resource[] = [];
    const included: Resource[] = [];
    let next: string | undefined = path;
    for (let page = 0; next !== undefined; page += 1) {
      if (page >= MAX_PAGES) throw new AscResponseError(path, `more than ${MAX_PAGES} pages`);
      const doc: RawDocument = await this.request("GET", next);
      if (!Array.isArray(doc.data)) throw new AscResponseError(next, "expected a list of resources");
      data.push(...(doc.data as Resource[]));
      included.push(...(doc.included ?? []));
      next = doc.links?.next;
    }
    return { data, included };
  }

  // Writes. Never retried: a POST that timed out may have succeeded.
  async post(path: string, body: unknown): Promise<Resource> {
    const doc = await this.request("POST", path, body);
    if (doc.data === undefined || Array.isArray(doc.data)) throw new AscResponseError(path, "expected a created resource");
    return doc.data as Resource;
  }

  async patch(path: string, body: unknown): Promise<void> {
    await this.request("PATCH", path, body);
  }

  private async request(method: string, pathOrUrl: string, body?: unknown): Promise<RawDocument> {
    const url = pathOrUrl.startsWith("http") ? pathOrUrl : `${this.baseUrl}${pathOrUrl}`;
    const shown = pathOrUrl.startsWith("http") ? new URL(pathOrUrl).pathname : pathOrUrl.split("?")[0] ?? pathOrUrl;
    const headers: Record<string, string> = { authorization: `Bearer ${await this.tokens.token()}`, accept: "application/json" };
    if (body !== undefined) headers["content-type"] = "application/json";
    let response: Response;
    try {
      response = await this.fetchFn(url, { method, headers, ...(body === undefined ? {} : { body: JSON.stringify(body) }) });
    } catch (cause) {
      throw new AscNetworkError(method, shown, cause);
    }
    const text = await response.text();
    const parsed = parseJson(text);
    if (!response.ok) {
      const retryAfter = Number(response.headers.get("retry-after"));
      throw new AscApiError(response.status, toEntries(parsed?.errors), method, shown, Number.isFinite(retryAfter) && retryAfter > 0 ? retryAfter : undefined);
    }
    if (parsed === undefined) {
      if (text.trim() === "") return {}; // 204 on PATCH/DELETE
      throw new AscResponseError(shown, "response is not JSON");
    }
    return parsed;
  }
}

function parseJson(text: string): RawDocument | undefined {
  if (text.trim() === "") return undefined;
  try {
    return JSON.parse(text) as RawDocument;
  } catch {
    return undefined;
  }
}

export function stringAttr(resource: Resource, name: string): string | undefined {
  const value = resource.attributes?.[name];
  return typeof value === "string" ? value : undefined;
}

export function relatedId(resource: Resource, relation: string): string | undefined {
  return resource.relationships?.[relation]?.data?.id;
}

export function indexById(resources: readonly Resource[], type: string): Map<string, Resource> {
  return new Map(resources.filter((r) => r.type === type).map((r) => [r.id, r]));
}

export const query = (params: Readonly<Record<string, string>>): string =>
  Object.entries(params)
    .map(([k, v]) => `${k}=${encodeURIComponent(v).replace(/%2C/g, ",")}`)
    .join("&");
