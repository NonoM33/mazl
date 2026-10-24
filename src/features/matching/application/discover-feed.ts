import { missingProfileFields, type MissingProfileField, type ProfilePreferences } from "../../profile/domain/profile-completeness";

export interface DiscoverFeedDeps<Candidate> {
  /** The caller's own gender / looking_for, `null` when they have no profile row. */
  loadPreferences(userId: number): Promise<ProfilePreferences | null>;
  loadCandidates(userId: number, limit: number, offset: number): Promise<Candidate[]>;
}

export type DiscoverFeedResult<Candidate> =
  | { readonly ok: true; readonly profiles: Candidate[] }
  | { readonly ok: false; readonly error: "profile_incomplete"; readonly missing: MissingProfileField[] };

/**
 * Candidates for the caller, or the list of what the caller still has to fill.
 * A caller who has not said who they are or who they look for gets NO feed:
 * the candidates query is not even run, so it can never fall back to everyone.
 */
export async function getDiscoverFeed<Candidate>(
  deps: DiscoverFeedDeps<Candidate>,
  userId: number,
  limit: number,
  offset: number,
): Promise<DiscoverFeedResult<Candidate>> {
  const missing = missingProfileFields(await deps.loadPreferences(userId));
  if (missing.length > 0) return { ok: false, error: "profile_incomplete", missing };
  return { ok: true, profiles: await deps.loadCandidates(userId, limit, offset) };
}
