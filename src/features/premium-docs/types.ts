import type { z } from "zod";

// The contract of the member API of the revenue features, declared once: the OpenAPI document
// (docs/api/premium-openapi.json) is generated from this list and a test checks it
// (CLAUDE.md §10bis). It documents; it validates nothing at run time.

export type Auth = "member" | "optionalMember" | "admin" | "signature";

export interface ErrorSpec {
  readonly status: 400 | 401 | 402 | 404 | 409 | 429 | 500;
  readonly code: string;
  readonly description: string;
  // The body when it is not the usual { success: false, error }.
  readonly body?: Readonly<Record<string, unknown>>;
}

export interface ParameterSpec {
  readonly name: string;
  readonly in: "path" | "query";
  readonly description: string;
  readonly required: boolean;
  readonly schema: z.ZodType;
  readonly example: unknown;
}

export interface OperationSpec {
  readonly operationId: string;
  readonly method: "get" | "post" | "put" | "delete";
  // OpenAPI notation, {id}; the router uses :id.
  readonly path: string;
  readonly tag: string;
  readonly summary: string;
  readonly description: string;
  readonly auth: Auth;
  readonly parameters: readonly ParameterSpec[];
  readonly body?: { readonly schema: z.ZodType; readonly examples: Readonly<Record<string, { readonly summary: string; readonly value: unknown }>> };
  readonly success: {
    readonly status: 200 | 201;
    readonly description: string;
    readonly schema: z.ZodType;
    // true: { success: true, data }. false: the body is the schema itself.
    readonly enveloped: boolean;
    readonly example: unknown;
    // An image, not JSON.
    readonly image?: boolean;
  };
  readonly errors: readonly ErrorSpec[];
}
