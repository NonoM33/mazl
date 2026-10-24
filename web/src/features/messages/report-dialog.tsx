import { useState } from "react";
import type { ReportCategory } from "../../shared/api/types";
import { Dialog } from "../../shared/ui/dialog";

export const REPORT_CATEGORIES: readonly (readonly [ReportCategory, string])[] = [
  ["fake_profile", "Faux profil"],
  ["inappropriate_photos", "Photos inappropriées"],
  ["harassment", "Harcèlement"],
  ["spam", "Spam / Arnaque"],
  ["underage", "Mineur"],
  ["offline_behavior", "Comportement hors app"],
  ["other", "Autre"],
];

export const COMMENT_MAX = 1000;

export interface ReportInput { readonly category: ReportCategory; readonly comment: string; readonly blockUser: boolean }

// `scope` « member » asks for a comment and offers to block too; « message »
// only asks for the reason (POST /api/messages/:id/report {reason}).
export function ReportDialog({ scope, name, busy, error, onSubmit, onClose }: {
  readonly scope: "member" | "message"; readonly name: string; readonly busy: boolean; readonly error: string | null;
  readonly onSubmit: (input: ReportInput) => void; readonly onClose: () => void;
}) {
  const [category, setCategory] = useState<ReportCategory | null>(null);
  const [comment, setComment] = useState("");
  const [blockUser, setBlockUser] = useState(false);
  const title = scope === "member" ? `Signaler ${name}` : "Signaler ce message";
  return (
    <Dialog title={title} onClose={onClose}>
      <p className="body-m muted">Choisissez la raison qui correspond le mieux. Votre signalement reste confidentiel.</p>
      <div className="chips" role="radiogroup" aria-label="Raison du signalement">
        {REPORT_CATEGORIES.map(([value, label]) => (
          <button key={value} type="button" role="radio" aria-checked={category === value} className="chip" onClick={() => setCategory(value)}>{label}</button>
        ))}
      </div>
      {scope === "member" && (
        <>
          <div className="field">
            <label htmlFor="report-comment">Un commentaire (facultatif)</label>
            <textarea id="report-comment" className="textarea" maxLength={COMMENT_MAX} value={comment} onChange={(event) => setComment(event.target.value)} />
            <span className="field-hint">{comment.length} / {COMMENT_MAX}</span>
          </div>
          <label className="checkbox"><input type="checkbox" checked={blockUser} onChange={(event) => setBlockUser(event.target.checked)} /><span className="body-m">Bloquer aussi cette personne</span></label>
        </>
      )}
      {error && <p className="field-error" role="alert">{error}</p>}
      <div className="inline gap-8" style={{ justifyContent: "flex-end" }}>
        <button type="button" className="btn btn-outline btn-sm" onClick={onClose}>Annuler</button>
        <button type="button" className="btn btn-primary btn-sm" disabled={category === null || busy} onClick={() => category && onSubmit({ category, comment: comment.trim(), blockUser })}>Envoyer le signalement</button>
      </div>
    </Dialog>
  );
}
