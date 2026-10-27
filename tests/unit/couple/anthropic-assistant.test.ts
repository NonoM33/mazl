import { describe, expect, test } from "bun:test";
import { assistantFromEnv, createAnthropicAssistant, extractJsonObject, offlineAssistant, type FetchLike } from "../../../src/features/couple/infra/anthropic-concierge-assistant";
import type { AssistantInput } from "../../../src/features/couple/domain/assistant-prompt";

// The request the assistant sends is checked against the Messages API as
// documented (url, x-api-key, anthropic-version, model, max_tokens, messages),
// not against the adapter's own code.

const input: AssistantInput = {
  kind: "table", wantedAt: "2026-11-13", city: "Paris", constraints: { kosher: true },
  turns: [{ role: "member", text: "Un dîner calme. Joignez-moi à jeanne.exemple@gmail.com ou au 06 12 34 56 78." }],
};

interface Call { url: string; headers: Record<string, string>; body: Record<string, unknown> }

function fakeFetch(answer: { ok?: boolean; status?: number; json?: unknown } | Error, calls: Call[] = []): FetchLike {
  return async (url, init) => {
    calls.push({ url, headers: init.headers, body: JSON.parse(init.body) as Record<string, unknown> });
    if (answer instanceof Error) throw answer;
    return { ok: answer.ok ?? true, status: answer.status ?? 200, json: async () => answer.json };
  };
}
const textReply = (text: string) => ({ content: [{ type: "text", text }] });
const VALID = JSON.stringify({ reply: "Voici une idée.", options: [{ title: "Table", details: "Calme", priceHint: "autour de 90 euros" }] });
const config = (fetch: FetchLike, log: string[] = []) => ({ apiKey: "key-example", model: "claude-sonnet-5-5", fetch, log: (line: string) => log.push(line) });

describe("the Anthropic request", () => {
  test("goes to the Messages API with the documented headers, the model and 600 max tokens", async () => {
    const calls: Call[] = [];
    await createAnthropicAssistant(config(fakeFetch({ json: textReply(VALID) }, calls))).respond(input);
    expect(calls).toHaveLength(1);
    expect(calls[0]?.url).toBe("https://api.anthropic.com/v1/messages");
    expect(calls[0]?.headers["x-api-key"]).toBe("key-example");
    expect(calls[0]?.headers["anthropic-version"]).toBe("2023-06-01");
    expect(calls[0]?.body.model).toBe("claude-sonnet-5-5");
    expect(calls[0]?.body.max_tokens).toBe(600);
    expect(typeof calls[0]?.body.system).toBe("string");
  });

  test("carries no name, e-mail or phone number: the request is checked as the wire sees it", async () => {
    const calls: Call[] = [];
    await createAnthropicAssistant(config(fakeFetch({ json: textReply(VALID) }, calls))).respond(input);
    const wire = JSON.stringify(calls[0]?.body);
    expect(wire).not.toContain("jeanne.exemple");
    expect(wire).not.toContain("gmail");
    expect(wire).not.toContain("06 12 34 56 78");
    expect(wire).toContain("Un dîner calme");
    expect(wire).toContain("2026-11-13");
    expect(wire).toContain("Paris");
    // Only these keys can reach the API: no user, member or couple identifier.
    expect(Object.keys(calls[0]?.body ?? {}).sort()).toEqual(["max_tokens", "messages", "model", "system"]);
  });
});

describe("the answer", () => {
  test("a valid JSON answer is returned, even inside a code fence", async () => {
    const answer = await createAnthropicAssistant(config(fakeFetch({ json: textReply(`\`\`\`json\n${VALID}\n\`\`\``) }))).respond(input);
    expect(answer?.options).toHaveLength(1);
    expect(answer?.reply).toBe("Voici une idée.");
  });

  test.each([
    ["prose without JSON", textReply("Voici mes idées.")],
    ["JSON of the wrong shape", textReply(JSON.stringify({ message: "x" }))],
    ["a reply over 600 characters", textReply(JSON.stringify({ reply: "x".repeat(601), options: [] }))],
    ["more than three ideas", textReply(JSON.stringify({ reply: "ok", options: Array.from({ length: 4 }, () => ({ title: "t", details: "d", priceHint: "p" })) }))],
    ["no content", { content: [] }],
    ["not an object", "oops"],
  ])("%s falls back to the team (null)", async (_label, json) => {
    expect(await createAnthropicAssistant(config(fakeFetch({ json }))).respond(input)).toBeNull();
  });

  test("an HTTP error or a network failure falls back to the team, logging no body", async () => {
    const log: string[] = [];
    expect(await createAnthropicAssistant(config(fakeFetch({ ok: false, status: 529, json: { error: "overloaded" } }), log)).respond(input)).toBeNull();
    expect(await createAnthropicAssistant(config(fakeFetch(new Error("boom")), log)).respond(input)).toBeNull();
    expect(log.join(" ")).toContain("529");
    expect(log.join(" ")).not.toContain("overloaded");
  });

  test("extractJsonObject tolerates text around the object", () => {
    expect(extractJsonObject('Voilà : {"a":1} merci')).toEqual({ a: 1 });
    expect(extractJsonObject("rien")).toBeNull();
    expect(extractJsonObject("{pas du json}")).toBeNull();
  });
});

describe("configuration", () => {
  test("without ANTHROPIC_API_KEY the assistant is offline and never calls anything", async () => {
    const calls: Call[] = [];
    const assistant = assistantFromEnv({}, fakeFetch({ json: textReply(VALID) }, calls), () => undefined);
    expect(assistant).toBe(offlineAssistant);
    expect(await assistant.respond(input)).toBeNull();
    expect(assistantFromEnv({ ANTHROPIC_API_KEY: "  " }, fakeFetch({}), () => undefined)).toBe(offlineAssistant);
    expect(calls).toHaveLength(0);
  });

  test("CONCIERGE_MODEL changes the model; the default is claude-sonnet-5-5", async () => {
    const calls: Call[] = [];
    await assistantFromEnv({ ANTHROPIC_API_KEY: "k", CONCIERGE_MODEL: "claude-test-model" }, fakeFetch({ json: textReply(VALID) }, calls), () => undefined).respond(input);
    await assistantFromEnv({ ANTHROPIC_API_KEY: "k" }, fakeFetch({ json: textReply(VALID) }, calls), () => undefined).respond(input);
    expect(calls.map((c) => c.body.model)).toEqual(["claude-test-model", "claude-sonnet-5-5"]);
  });

  test("ANTHROPIC_API_URL redirects the tests, and is ignored in production", async () => {
    const calls: Call[] = [];
    await assistantFromEnv({ ANTHROPIC_API_KEY: "k", ANTHROPIC_API_URL: "http://127.0.0.1:9/v1/messages" }, fakeFetch({ json: textReply(VALID) }, calls), () => undefined).respond(input);
    await assistantFromEnv({ ANTHROPIC_API_KEY: "k", ANTHROPIC_API_URL: "http://127.0.0.1:9/v1/messages", NODE_ENV: "production" }, fakeFetch({ json: textReply(VALID) }, calls), () => undefined).respond(input);
    expect(calls.map((c) => c.url)).toEqual(["http://127.0.0.1:9/v1/messages", "https://api.anthropic.com/v1/messages"]);
  });
});
