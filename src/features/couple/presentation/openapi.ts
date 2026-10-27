import { z } from "zod";
import { OPERATIONS, type ErrorSpec, type OperationSpec } from "./operations";
import { envelope, errorEnvelope } from "./schemas";

// The OpenAPI 3.1 document of the daily couple space, generated from the list the
// routes are registered from. It documents; it validates nothing at run time.

type Json = Record<string, unknown>;

const jsonSchema = (schema: z.ZodType, io: "input" | "output"): Json => {
  const { $schema: _ignored, ...rest } = z.toJSONSchema(schema, { target: "draft-2020-12", io }) as Json;
  return rest;
};

function errorResponse(errors: readonly ErrorSpec[]): Json {
  const examples: Record<string, Json> = {};
  for (const spec of errors) {
    examples[spec.code] = { summary: spec.description, value: { success: false, error: spec.code, ...(spec.message === undefined ? {} : { message: spec.message }) } };
  }
  return {
    description: errors.map((spec) => `${spec.code} : ${spec.description}`).join(" — "),
    content: { "application/json": { schema: jsonSchema(errorEnvelope, "output"), examples } },
  };
}

function responses(operation: OperationSpec): Json {
  const { success } = operation;
  const result: Record<string, Json> = {
    [String(success.status)]: {
      description: success.description,
      content: { "application/json": { schema: jsonSchema(envelope(success.schema), "output"), example: { success: true, data: success.example } } },
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
    security: [operation.audience === "staff" ? { staffBearer: [] } : { memberBearer: [] }],
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
      title: "MAZL — espace couple quotidien et conciergerie",
      version: "1.0.0",
      description:
        "Aujourd'hui, agenda et rituels, sorties, question du jour, bilan du mois et conciergerie MAZL Couple (docs/couple/ESPACE-COUPLE.md). " +
        "Enveloppe des réponses : { success, data } ou { success: false, error, message? }.",
    },
    tags: [
      { name: "Aujourd'hui", description: "L'écran quotidien du couple et l'humeur du jour." },
      { name: "Agenda", description: "Les rituels du couple et leurs rappels." },
      { name: "Sorties", description: "Activités et événements couples." },
      { name: "Nous deux", description: "Question du jour et bilan du mois." },
      { name: "Conciergerie", description: "Demandes du couple (MAZL Couple)." },
      { name: "Conciergerie (équipe)", description: "Back-office : file, réponses, réservations." },
      { name: "Documentation", description: "Ce document." },
    ],
    paths,
    components: {
      securitySchemes: {
        memberBearer: { type: "http", scheme: "bearer", bearerFormat: "JWT", description: "Jeton de connexion du membre." },
        staffBearer: { type: "http", scheme: "bearer", description: "Session staff du back-office, second facteur passé si exigé." },
      },
    },
  };
}
