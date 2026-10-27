import { SYSTEM_PROMPT, toAnthropicMessages, type AssistantInput } from "../domain/assistant-prompt";
import { assistantOutputSchema, MAX_REPLY_LENGTH, type AssistantOutput } from "../domain/concierge";
import type { ConciergeAssistant } from "../application/concierge-ports";

// The concierge assistant, over the Anthropic Messages API. Whatever goes wrong
// (network, status, empty or invalid output) answers null and the request goes
// to the team. Nothing identifying the members is ever put in the request: the
// input type has no such field, and the texts are masked (domain/redact).

export const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
export const ANTHROPIC_VERSION = "2023-06-01";
export const DEFAULT_CONCIERGE_MODEL = "claude-sonnet-5-5";
const MAX_TOKENS = 600;
const TIMEOUT_MS = 25_000;

export type FetchLike = (url: string, init: { method: string; headers: Record<string, string>; body: string; signal: AbortSignal }) => Promise<{ ok: boolean; status: number; json(): Promise<unknown> }>;

export interface AnthropicAssistantConfig {
  readonly url?: string;
  readonly apiKey: string;
  readonly model: string;
  readonly fetch: FetchLike;
  readonly log: (line: string) => void;
}

// The first JSON object of the text, tolerating a code fence around it.
export function extractJsonObject(text: string): unknown {
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start === -1 || end <= start) return null;
  try {
    return JSON.parse(text.slice(start, end + 1));
  } catch {
    return null;
  }
}

function textOf(body: unknown): string | null {
  if (typeof body !== "object" || body === null) return null;
  const content = (body as { content?: unknown }).content;
  if (!Array.isArray(content)) return null;
  for (const block of content) {
    if (typeof block === "object" && block !== null && (block as { type?: unknown }).type === "text") {
      const text = (block as { text?: unknown }).text;
      if (typeof text === "string") return text;
    }
  }
  return null;
}

export function createAnthropicAssistant(config: AnthropicAssistantConfig): ConciergeAssistant {
  return {
    async respond(input: AssistantInput): Promise<AssistantOutput | null> {
      try {
        const response = await config.fetch(config.url ?? ANTHROPIC_URL, {
          method: "POST",
          headers: { "content-type": "application/json", "x-api-key": config.apiKey, "anthropic-version": ANTHROPIC_VERSION },
          body: JSON.stringify({ model: config.model, max_tokens: MAX_TOKENS, system: SYSTEM_PROMPT, messages: toAnthropicMessages(input) }),
          signal: AbortSignal.timeout(TIMEOUT_MS),
        });
        if (!response.ok) {
          config.log(`Concierge assistant refused: status ${String(response.status)}`);
          return null;
        }
        const text = textOf(await response.json());
        const parsed = assistantOutputSchema.safeParse(text === null ? null : extractJsonObject(text));
        if (!parsed.success) {
          config.log("Concierge assistant answered something invalid");
          return null;
        }
        return parsed.data.reply.length <= MAX_REPLY_LENGTH ? parsed.data : null;
      } catch (error: unknown) {
        config.log(`Concierge assistant failed: ${error instanceof Error ? error.name : "unknown"}`);
        return null;
      }
    },
  };
}

// No ANTHROPIC_API_KEY: the assistant is absent, every request goes to the team.
export const offlineAssistant: ConciergeAssistant = { respond: async () => null };

export function assistantFromEnv(env: Readonly<Record<string, string | undefined>>, fetchImpl: FetchLike, log: (line: string) => void): ConciergeAssistant {
  const apiKey = env.ANTHROPIC_API_KEY?.trim();
  if (apiKey === undefined || apiKey === "") return offlineAssistant;
  // ANTHROPIC_API_URL points the tests at a fake server; production ignores it.
  const override = env.NODE_ENV === "production" ? undefined : env.ANTHROPIC_API_URL?.trim();
  return createAnthropicAssistant({ apiKey, model: env.CONCIERGE_MODEL?.trim() || DEFAULT_CONCIERGE_MODEL, fetch: fetchImpl, log, ...(override ? { url: override } : {}) });
}
