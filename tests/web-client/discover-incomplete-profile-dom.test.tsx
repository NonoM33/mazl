import { afterEach, describe, expect, test } from "bun:test";
import { renderToStaticMarkup } from "react-dom/server";
import { api } from "../../web/src/shared/api/client";
import { classifyLoadFailure } from "../../web/src/shared/api/errors";
import { DeckError, IncompleteProfile } from "../../web/src/features/discover/deck-states";
import { RouterProvider } from "../../web/src/shared/router";

// DOM-typed (the web tsconfig has the DOM lib, the root one does not): excluded from the root typecheck.
const realFetch = globalThis.fetch;
afterEach(() => { globalThis.fetch = realFetch; });

function answer(status: number, body: unknown): void {
  globalThis.fetch = (async () => new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } })) as unknown as typeof fetch;
}

async function failureOf(path: string) {
  try {
    await api.get(path, new AbortController().signal);
  } catch (error) {
    return classifyLoadFailure(error);
  }
  throw new Error("expected a failure");
}

describe("409 profile_incomplete through the HTTP client", () => {
  test.each(["/api/discover?limit=20", "/api/daily-picks"])("%s is recognised with its missing fields, not a generic error", async (path) => {
    answer(409, { success: false, error: "profile_incomplete", missing: ["gender", "looking_for"] });
    expect(await failureOf(path)).toEqual({ kind: "profile_incomplete", missing: ["gender", "looking_for"] });
  });
});

describe("incomplete profile state", () => {
  function render(node: React.ReactNode): string {
    Object.assign(globalThis, { window: { location: { pathname: "/app", search: "" }, addEventListener() {}, removeEventListener() {} } });
    return renderToStaticMarkup(<RouterProvider>{node}</RouterProvider>);
  }

  test("title, missing list and a link to the profile edit screen, no retry", () => {
    const html = render(<IncompleteProfile missing={["gender", "looking_for"]} />);
    expect(html).toContain("Complétez votre profil pour découvrir des profils");
    expect(html).toContain("Votre genre");
    expect(html).toContain("Qui vous recherchez");
    expect(html).toContain('href="/app/profil/modifier"');
    expect(html).not.toContain("Réessayer");
    expect(html).not.toContain("n&#x27;a pas abouti");
  });

  test("the generic error keeps its retry button", () => {
    expect(render(<DeckError message="x" onRetry={() => {}} />)).toContain("Réessayer");
  });
});
