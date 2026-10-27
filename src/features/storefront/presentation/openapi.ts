import { z } from "zod";
import { errorEnvelope, envelope } from "./schemas";
import { OPERATIONS, type ErrorSpec, type OperationSpec } from "./operations";

// The OpenAPI 3.1 document of the storefront API, generated from the operation list the routes
// are registered from. It documents; it validates nothing at run time.

type Json = Record<string, unknown>;

const jsonSchema = (schema: z.ZodType, io: "input" | "output"): Json => {
  const { $schema: _ignored, ...rest } = z.toJSONSchema(schema, { target: "draft-2020-12", io }) as Json;
  return rest;
};

function errorResponse(errors: readonly ErrorSpec[]): Json {
  const examples: Record<string, Json> = {};
  for (const error of errors) {
    examples[error.code] = {
      summary: error.description,
      value: { success: false, error: error.code, ...(error.message === undefined ? {} : { message: error.message }) },
    };
  }
  return {
    description: errors.map((error) => `${error.code} : ${error.description}`).join(" — "),
    content: { "application/json": { schema: jsonSchema(errorEnvelope, "output"), examples } },
  };
}

function responses(operation: OperationSpec): Json {
  const { success } = operation;
  const body = success.enveloped ? envelope(success.schema) : success.schema;
  const value = success.enveloped ? { success: true, data: success.example } : success.example;
  const result: Record<string, Json> = {
    [String(success.status)]: {
      description: success.description,
      content: { "application/json": { schema: jsonSchema(body, "output"), example: value } },
      ...(operation.permission === null ? { headers: { "Cache-Control": { description: "Mise en cache 60 secondes.", schema: { type: "string", example: "public, max-age=60" } } } } : {}),
    },
  };
  const byStatus = new Map<number, ErrorSpec[]>();
  for (const error of operation.errors) byStatus.set(error.status, [...(byStatus.get(error.status) ?? []), error]);
  for (const [status, errors] of byStatus) result[String(status)] = errorResponse(errors);
  return result;
}

function describeOperation(operation: OperationSpec): Json {
  return {
    operationId: operation.operationId,
    tags: [operation.tag],
    summary: operation.summary,
    description: operation.description,
    // security: [] marks a route public on purpose.
    security: operation.permission === null ? [] : [{ staffBearer: [] }],
    ...(operation.parameters.length === 0
      ? {}
      : {
          parameters: operation.parameters.map((parameter) => ({
            name: parameter.name,
            in: parameter.in,
            description: parameter.description,
            required: parameter.required,
            schema: jsonSchema(parameter.schema, "input"),
            example: parameter.example,
          })),
        }),
    ...(operation.body === undefined
      ? {}
      : { requestBody: { required: true, content: { "application/json": { schema: jsonSchema(operation.body.schema, "input"), examples: operation.body.examples } } } }),
    responses: responses(operation),
  };
}

export function buildOpenApi(operations: readonly OperationSpec[] = OPERATIONS): Json {
  const paths: Record<string, Json> = {};
  for (const operation of operations) paths[operation.path] = { ...(paths[operation.path] ?? {}), [operation.method]: describeOperation(operation) };
  return {
    openapi: "3.1.0",
    info: {
      title: "MAZL — vitrine, prix et campagnes",
      version: "1.0.0",
      description:
        "Offres et prix des abonnements, campagnes saisonnières et leur programmation. Le prix affiché sur iPhone vient toujours de StoreKit : " +
        "ce service dit quoi montrer, pas combien. Enveloppe des réponses : { success, data } ou { success: false, error, message? }.",
    },
    tags: [
      { name: "Vitrine publique", description: "Lu par l'app et le site, sans connexion." },
      { name: "Catalogue", description: "Affichage des produits." },
      { name: "Prix", description: "Écritures de prix chez Apple et Stripe (super-administrateur)." },
      { name: "Campagnes", description: "Fêtes, codes d'offre, programmation." },
      { name: "Documentation", description: "Ce document." },
    ],
    paths,
    components: {
      securitySchemes: {
        staffBearer: { type: "http", scheme: "bearer", description: "Session staff du back-office (jeton de /api/backoffice/auth), second facteur passé si exigé." },
      },
    },
  };
}
