import { useState } from "react";
import { Eye, Heart } from "lucide-react";
import { ScreenHeader } from "../../app/shell";
import { api } from "../../shared/api/client";
import { describeError } from "../../shared/api/errors";
import type { BillingStatus, LikesReceivedResponse, SubscriptionResponse } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { Link } from "../../shared/router";
import { EmptyState, Skeleton } from "../../shared/ui/empty-state";
import { LikeDialog } from "./like-dialog";
import { LikesGrid } from "./likes-grid";
import { hasPlus, tabLabel } from "./likes-model";
import "./likes.css";

type Tab = "likes" | "visitors";

async function loadPlus(signal: AbortSignal): Promise<boolean> {
  const billing = await api.get<BillingStatus>("/api/billing/status", signal).catch(() => null);
  if (billing !== null) return hasPlus(billing, null);
  const subscription = await api.get<SubscriptionResponse>("/api/subscription", signal).catch(() => null);
  return hasPlus(null, subscription?.subscription ?? null);
}

function UpsellBanner({ count }: { readonly count: number }) {
  return (
    <div className="banner banner-accent" style={{ marginBottom: 20 }}>
      <div className="stack gap-8 grow">
        <p className="title-m">{count} {count > 1 ? "personnes vous ont aimé" : "personne vous a aimé"}</p>
        <p className="body-s">Avec mazl+, vous voyez qui, et vous pouvez répondre tout de suite.</p>
      </div>
      <Link to="/premium" className="btn btn-accent btn-sm">Voir qui vous a aimé</Link>
    </div>
  );
}

function VisitorsTab() {
  return (
    <EmptyState title="Visiteurs" icon={<Eye size={32} aria-hidden="true" />}>
      Les visites de profil ne sont pas encore mesurées.
    </EmptyState>
  );
}

export function LikesScreen() {
  const [tab, setTab] = useState<Tab>("likes");
  const [opened, setOpened] = useState<number | null>(null);
  const likes = useResource("likes:received", (signal) => api.get<LikesReceivedResponse>("/api/likes/received", signal));
  const plus = useResource("likes:plus", loadPlus, null);
  const isPlus = plus.state.data === true;
  const count = likes.state.data?.count ?? 0;
  const answered = (userId: number) => likes.mutate((current) => ({ ...current, count: current.count - 1, likes: current.likes.filter((like) => like.user_id !== userId) }));

  return (
    <>
      <ScreenHeader eyebrow="Likes" title="Likes et visiteurs" />
      <div className="screen-body"><div className="page">
        <div className="likes-tabs" role="tablist" aria-label="Likes et visiteurs">
          <button type="button" role="tab" className="chip" aria-selected={tab === "likes"} aria-pressed={tab === "likes"} onClick={() => setTab("likes")}>{tabLabel(count)}</button>
          <button type="button" role="tab" className="chip" aria-selected={tab === "visitors"} aria-pressed={tab === "visitors"} onClick={() => setTab("visitors")}>Visiteurs</button>
        </div>
        {tab === "visitors" ? <VisitorsTab /> : (
          <>
            {likes.state.status === "loading" && <Skeleton height={320} />}
            {likes.state.status === "error" && !likes.state.data && <p className="field-error" role="alert">{describeError(likes.state.error)}</p>}
            {likes.state.data && count > 0 && plus.state.status !== "loading" && !isPlus && <UpsellBanner count={count} />}
            {likes.state.data && count === 0 && <EmptyState title="Pas encore de like" icon={<Heart size={32} aria-hidden="true" />}>Vos prochains likes apparaîtront ici.</EmptyState>}
            {likes.state.data && count > 0 && <LikesGrid likes={likes.state.data.likes} plus={isPlus} onOpen={setOpened} onExpired={() => void likes.reload()} />}
          </>
        )}
      </div></div>
      {opened !== null && <LikeDialog userId={opened} onClose={() => setOpened(null)} onAnswered={answered} />}
    </>
  );
}
