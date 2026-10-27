import { z } from "zod";
import { OPERATIONS } from "./operations";
import { envelope, errorEnvelope } from "./schemas";
import type { Auth, ErrorSpec, OperationSpec } from "./types";

type Json = Record<string, unknown>;

const jsonSchema = (schema: z.ZodType, io: "input" | "output"): Json => {
  const { $schema: _ignored, ...rest } = z.toJSONSchema(schema, { target: "draft-2020-12", io, unrepresentable: "any" }) as Json;
  return rest;
};

const SECURITY: Readonly<Record<Auth, readonly Record<string, string[]>[]>> = {
  member: [{ memberBearer: [] }],
  optionalMember: [{}, { memberBearer: [] }],
  admin: [{ adminBearer: [] }],
  signature: [],
};

function errorResponse(errors: readonly ErrorSpec[]): Json {
  const examples: Record<string, Json> = {};
  for (const error of errors) {
    examples[error.code] = { summary: error.description, value: error.body ?? { success: false, error: error.code } };
  }
  const legacy = errors.some((error) => error.body !== undefined);
  return {
    description: errors.map((error) => `${error.code} : ${error.description}`).join(" — "),
    content: { "application/json": { schema: legacy ? { type: "object", properties: { error: { type: "string" } }, required: ["error"] } : jsonSchema(errorEnvelope, "output"), examples } },
  };
}

function responses(operation: OperationSpec): Json {
  const { success } = operation;
  const content: Json = success.image
    ? { "image/jpeg": { schema: { type: "string", format: "binary", description: "JPEG de 48 px de large, flou." } } }
    : {
        "application/json": {
          schema: jsonSchema(success.enveloped ? envelope(success.schema) : success.schema, "output"),
          example: success.enveloped ? { success: true, data: success.example } : success.example,
        },
      };
  const result: Record<string, Json> = { [String(success.status)]: { description: success.description, content } };
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
    // security: [] marks a route open on purpose (here: the signature in the URL is the credential).
    security: SECURITY[operation.auth],
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
      title: "MAZL — fonctionnalités mazl+ (likes floutés, passeport, discret, lecture, retour arrière, Boost, tarif membre)",
      version: "1.0.0",
      description:
        "Routes ajoutées ou modifiées par le lot « fonctionnalités qui rapportent » (docs/premium/MONETISATION.md). Le serveur décide toujours : une donnée réservée aux abonnés " +
        "n'est jamais envoyée en clair à un non-abonné. Enveloppe des nouvelles routes : { success: true, data } ou { success: false, error } avec un code stable ; " +
        "les routes existantes gardent leur forme. Ce document n'est servi à personne en production.",
    },
    tags: [
      { name: "Réglages mazl+", description: "Passeport, mode discret, confirmations de lecture." },
      { name: "Découverte", description: "Pile, choix, retour arrière." },
      { name: "Likes", description: "Likes reçus, flous pour les non-abonnés." },
      { name: "Boost", description: "Meilleur moment et programmation." },
      { name: "Chat", description: "Lecture des messages et « Lu à »." },
      { name: "Événements", description: "Tarif membre." },
      { name: "Administration des événements", description: "Saisie du tarif membre." },
      { name: "Médias", description: "Variante floue d'une photo." },
    ],
    paths,
    components: {
      securitySchemes: {
        memberBearer: { type: "http", scheme: "bearer", bearerFormat: "JWT", description: "Jeton de connexion du membre (POST /api/auth/google, /apple)." },
        adminBearer: { type: "http", scheme: "bearer", description: "Jeton de l'administration (POST /api/admin/login)." },
      },
    },
  };
}
