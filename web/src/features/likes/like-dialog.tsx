import { useState } from "react";
import { api } from "../../shared/api/client";
import { describeError } from "../../shared/api/errors";
import type { MatchesResponse, ProfileResponse, SwipeResponse } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { Dialog } from "../../shared/ui/dialog";
import { Skeleton } from "../../shared/ui/empty-state";
import { ProfilePanel } from "../../shared/ui/profile-panel";
import { Link } from "../../shared/router";

// A liker's profile, with the two answers: Passer or Like. A like on someone
// who already liked us is a match; the conversation is found in /api/matches.

type Outcome = { readonly kind: "idle" } | { readonly kind: "match"; readonly conversationId: number | null };

async function conversationWith(userId: number): Promise<number | null> {
  const { matches } = await api.get<MatchesResponse>("/api/matches");
  return matches.find((item) => item.profile.user_id === userId)?.conversationId ?? null;
}

export function LikeDialog({ userId, onClose, onAnswered }: { readonly userId: number; readonly onClose: () => void; readonly onAnswered: (userId: number) => void }) {
  const profile = useResource(`profile:${userId}`, (signal) => api.get<ProfileResponse>(`/api/profile/${userId}`, signal));
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [outcome, setOutcome] = useState<Outcome>({ kind: "idle" });

  const answer = async (action: "like" | "pass") => {
    setBusy(true);
    setError(null);
    try {
      const result = await api.post<SwipeResponse>("/api/swipes", { target_user_id: userId, action });
      onAnswered(userId);
      if (result.match) setOutcome({ kind: "match", conversationId: await conversationWith(userId).catch(() => null) });
      else onClose();
    } catch (cause) {
      setError(describeError(cause));
    } finally {
      setBusy(false);
    }
  };

  return (
    <Dialog title="Profil" hideTitle wide onClose={onClose}>
      {outcome.kind === "match" ? (
        <div className="stack gap-16" role="status">
          <h3 className="headline-s">C'est un match</h3>
          <p className="body-m">Vous vous êtes plu mutuellement. Écrivez le premier message.</p>
          {outcome.conversationId !== null && <Link className="btn btn-accent" to={`/messages/${outcome.conversationId}`} onClick={onClose}>Envoyer un message</Link>}
        </div>
      ) : (
        <>
          {profile.state.status === "loading" && <Skeleton height={320} />}
          {profile.state.status === "error" && <p className="field-error" role="alert">{describeError(profile.state.error)}</p>}
          {profile.state.data && <ProfilePanel profile={profile.state.data.profile} onExpired={() => void profile.reload()} />}
          {error && <p className="field-error" role="alert">{error}</p>}
          <div className="like-actions">
            <button type="button" className="btn btn-outline" disabled={busy} onClick={() => void answer("pass")}>Passer</button>
            <button type="button" className="btn btn-accent" disabled={busy} onClick={() => void answer("like")}>Like</button>
          </div>
        </>
      )}
    </Dialog>
  );
}
