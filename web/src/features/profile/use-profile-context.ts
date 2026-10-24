import { api } from "../../shared/api/client";
import { ApiError } from "../../shared/api/errors";
import type { ConsentsResponse, MeResponse, OwnPromptsResponse, VerificationStatus } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import type { PromptAnswer } from "../../shared/ui/profile-panel";
import type { OwnPrompt } from "../../shared/api/types";

// Who I am, whether I gave the article 9 consent (the route may not exist yet:
// a 404 reads as "not given") and how verified I am.

export async function religiousConsentGranted(signal?: AbortSignal): Promise<boolean> {
  try {
    const response = await api.get<ConsentsResponse>("/api/privacy/consents", signal);
    return response.consents.religious_data.granted === true;
  } catch (error) {
    if (error instanceof ApiError && error.isNotFound) return false;
    throw error;
  }
}

export const useMeResource = () => useResource<MeResponse>("me-fresh", (signal) => api.get<MeResponse>("/api/auth/me", signal), null);
export const useConsentResource = () => useResource<boolean>("religious-consent", religiousConsentGranted, null);
export const useVerificationResource = () => useResource<VerificationStatus>("verification", (signal) => api.get<VerificationStatus>("/api/verification/status", signal), null);
export const useOwnPromptsResource = () => useResource<readonly OwnPrompt[]>("own-prompts-view", async (signal) => (await api.get<OwnPromptsResponse>("/api/profile/prompts", signal)).prompts, null);

export const toPromptAnswers = (prompts: readonly OwnPrompt[]): readonly PromptAnswer[] => prompts.map((prompt) => ({ question: prompt.prompt_text, answer: prompt.answer }));
