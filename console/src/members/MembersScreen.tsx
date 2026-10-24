import { useEffect, useState, type ReactElement } from "react";
import { buildHash } from "../app/router";
import { navigate } from "../app/use-route";
import { useSession } from "../app/session";
import type { MemberSearchPageDto } from "../shared/api/contracts";
import { formatNumber, memberName } from "../shared/format";
import { VERIFICATION_LABELS } from "../shared/labels";
import { BlurredImage } from "../shared/ui/BlurredImage";
import { Badge } from "../shared/ui/Badge";
import { EmptyState, ErrorState, SkeletonRows } from "../shared/ui/Feedback";
import { PageHeader } from "../shared/ui/PageHeader";
import { Icon } from "../shared/ui/Icon";
import { Table, type Column } from "../shared/ui/Table";
import { useAsync } from "../shared/ui/use-async";

type Row = MemberSearchPageDto["members"][number];

const columns: readonly Column<Row>[] = [
  {
    key: "member",
    header: "Membre",
    width: "34%",
    render: (row) => (
      <span className="member-cell">
        <BlurredImage src={row.photoUrl} name={memberName(row)} size={32} round />
        <span className="member-cell-text">
          <span className="member-cell-name">{memberName(row)}</span>
          <span className="member-cell-id">n°&nbsp;{row.id}</span>
        </span>
      </span>
    ),
  },
  { key: "email", header: "Adresse e-mail", width: "34%", render: (row) => row.email },
  { key: "verification", header: "Vérification", width: "16%", render: (row) => <Badge tone={row.verification === "none" ? "neutral" : "success"}>{VERIFICATION_LABELS[row.verification]}</Badge> },
  { key: "active", header: "Compte", width: "16%", render: (row) => (row.active ? "Actif" : <Badge tone="warning">Inactif</Badge>) },
];

export function MembersScreen({ initialQuery }: { readonly initialQuery: string }): ReactElement {
  const { api } = useSession();
  const [text, setText] = useState(initialQuery);
  const [query, setQuery] = useState(initialQuery.trim());

  useEffect(() => {
    const timer = window.setTimeout(() => setQuery(text.trim()), 300);
    return () => window.clearTimeout(timer);
  }, [text]);

  const searchable = query.length >= 2;
  const { state, reload } = useAsync(
    () => (searchable ? api.get<MemberSearchPageDto>("/members", { q: query, limit: 30 }) : Promise.resolve({ ok: true as const, data: { members: [], total: 0 } satisfies MemberSearchPageDto })),
    [api, query, searchable],
  );

  return (
    <>
      <PageHeader eyebrow="Communauté" title="Membres" lead="Recherchez par numéro, nom ou adresse e-mail. Les e-mails ne s'affichent que sur cet écran et la fiche." />
      <div className="page-body">
        <div className="searchbar">
          <Icon name="search" />
          <input
            type="search"
            className="searchbar-input"
            aria-label="Rechercher un membre"
            placeholder="Numéro, nom ou adresse e-mail"
            value={text}
            autoFocus
            onChange={(event) => setText(event.target.value)}
          />
        </div>
        {!searchable ? (
          <EmptyState icon="search" title="Recherchez un membre">
            Saisissez au moins deux caractères : un numéro, une partie du nom ou une adresse e-mail.
          </EmptyState>
        ) : state.status === "loading" ? (
          <SkeletonRows rows={6} label="Recherche en cours" />
        ) : state.status === "error" ? (
          <ErrorState message={state.message} onRetry={reload} />
        ) : state.data.members.length === 0 ? (
          <EmptyState icon="users" title="Aucun résultat">
            Aucun membre ne correspond à «&nbsp;{query}&nbsp;».
          </EmptyState>
        ) : (
          <>
            <p className="result-count" role="status">
              {formatNumber(state.data.total)} résultat{state.data.total > 1 ? "s" : ""}
            </p>
            <Table caption="Résultats de la recherche de membres" columns={columns} rows={state.data.members} rowKey={(row) => row.id} onRowActivate={(row) => navigate(buildHash("membres", row.id))} />
          </>
        )}
      </div>
    </>
  );
}
