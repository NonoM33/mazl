import { useCallback, useState } from "react";
import { api } from "../../shared/api/client";
import { describeError } from "../../shared/api/errors";
import type { OwnPrompt, OwnPromptsResponse, PromptDefinition, PromptsCatalogResponse } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { freePosition } from "./prompt-rules";

// The member's prompts (3 at most) and the catalogue to pick from.
export function usePrompts() {
  const own = useResource<readonly OwnPrompt[]>("own-prompts", async (signal) => (await api.get<OwnPromptsResponse>("/api/profile/prompts", signal)).prompts, null);
  const catalog = useResource<readonly PromptDefinition[]>("prompt-catalog", async (signal) => (await api.get<PromptsCatalogResponse>("/api/prompts", signal)).prompts, null);
  const [message, setMessage] = useState<string | null>(null);
  const prompts = own.state.data ?? [];
  const { reload } = own;

  const run = useCallback(async (action: () => Promise<unknown>) => {
    setMessage(null);
    try {
      await action();
      await reload();
      return true;
    } catch (error) {
      setMessage(describeError(error));
      return false;
    }
  }, [reload]);

  const add = (promptId: string, answer: string) =>
    run(() => api.post("/api/profile/prompts", { prompt_id: promptId, answer: answer.trim(), position: freePosition(prompts.map((prompt) => prompt.position)) }));
  const update = (id: number, answer: string) => run(() => api.put(`/api/profile/prompts/${id}`, { answer: answer.trim() }));
  const remove = (id: number) => run(() => api.delete(`/api/profile/prompts/${id}`));

  return { prompts, catalog: catalog.state.data ?? [], loading: own.state.status === "loading", message, add, update, remove };
}
