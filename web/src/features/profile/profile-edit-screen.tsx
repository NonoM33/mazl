import { useState } from "react";
import { ScreenHeader } from "../../app/shell";
import { api } from "../../shared/api/client";
import { ApiError, describeError } from "../../shared/api/errors";
import type { MeResponse, VerificationLevel } from "../../shared/api/types";
import { Dialog } from "../../shared/ui/dialog";
import { EmptyState, Skeleton } from "../../shared/ui/empty-state";
import { Eyebrow } from "../../shared/ui/eyebrow";
import { ProfilePanel } from "../../shared/ui/profile-panel";
import { useToast } from "../../shared/ui/toast";
import { InfoFields } from "./info-fields";
import { PhotoManager } from "./photo-manager";
import { PracticeFields } from "./practice-fields";
import { previewCard } from "./preview-card";
import { changedFields, draftFromRow, fieldOfServerError, validateChanges, type DraftErrors, type DraftField, type ProfileDraft } from "./profile-draft";
import { PromptsEditor } from "./prompts-editor";
import { toPromptAnswers, useConsentResource, useMeResource, useVerificationResource } from "./use-profile-context";
import { useLeaveGuard } from "./use-leave-guard";
import { usePhotos } from "./use-photos";
import { usePrompts } from "./use-prompts";
import "./profile.css";

interface EditorProps { readonly me: MeResponse; readonly granted: boolean; readonly level: VerificationLevel; readonly onSaved: () => Promise<void> }

function Editor({ me, granted, level, onSaved }: EditorProps) {
  const toast = useToast();
  const [saved, setSaved] = useState<ProfileDraft>(() => draftFromRow(me.profile));
  const [draft, setDraft] = useState<ProfileDraft>(saved);
  const [errors, setErrors] = useState<DraftErrors>({});
  const [failure, setFailure] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const photos = usePhotos();
  const prompts = usePrompts();
  const locked = me.profile?.birthdate_locked === true;
  const changes = changedFields(saved, draft, { birthdateLocked: locked, practiceAllowed: granted });
  const dirty = Object.keys(changes).length > 0;
  const guard = useLeaveGuard(dirty);

  const edit = (field: DraftField, value: string) => {
    setDraft((current) => ({ ...current, [field]: value }));
    setErrors((current) => ({ ...current, [field]: undefined }));
  };

  const save = async () => {
    const problems = validateChanges(changes);
    setErrors(problems);
    setFailure(null);
    if (Object.keys(problems).length > 0) return;
    setSaving(true);
    try {
      await api.put("/api/profile", changes);
      setSaved(draft);
      await onSaved();
      toast.show("Profil enregistré.");
    } catch (error) {
      const field = error instanceof ApiError && error.status === 400 ? fieldOfServerError(error.body.error) : null;
      if (field) setErrors({ [field]: "Cette valeur n'est pas acceptée." });
      else setFailure(describeError(error));
    } finally {
      setSaving(false);
    }
  };

  const card = previewCard(me.user.id, draft, photos.photos.map((photo) => photo.url), level);
  return (
    <div className="page cols-edit">
      <form className="stack gap-32" onSubmit={(event) => { event.preventDefault(); void save(); }} aria-label="Modifier le profil">
        <PhotoManager photos={photos} userId={me.user.id} />
        <PromptsEditor prompts={prompts} />
        <InfoFields draft={draft} errors={errors} birthdateLocked={locked} onChange={edit} />
        <PracticeFields draft={draft} granted={granted} onChange={edit} />
        {failure && <p className="banner banner-error" role="alert">{failure}</p>}
        <div className="edit-bar">
          <span className="body-s" role="status">{dirty ? "Modifications non enregistrées." : "Tout est enregistré."}</span>
          <button type="button" className="btn btn-outline btn-sm" onClick={() => guard.ask("/profil")}>Retour au profil</button>
          <button type="submit" className="btn btn-accent btn-sm" disabled={!dirty || saving}>{saving ? "Enregistrement…" : "Enregistrer"}</button>
        </div>
      </form>
      <aside className="stack gap-16 edit-preview" aria-label="Aperçu du profil">
        <Eyebrow>Aperçu · tel que vu par les autres</Eyebrow>
        <ProfilePanel profile={card} prompts={toPromptAnswers(prompts.prompts)} onExpired={() => void photos.reload()} />
      </aside>
      {guard.waiting !== null && (
        <Dialog title="Quitter sans enregistrer ?" onClose={guard.stay}>
          <p className="body-m">Vos modifications du formulaire seront perdues.</p>
          <div className="inline gap-8" style={{ justifyContent: "flex-end" }}>
            <button type="button" className="btn btn-outline btn-sm" onClick={guard.stay}>Continuer à modifier</button>
            <button type="button" className="btn btn-danger btn-sm" onClick={() => { guard.leave(); }}>Quitter</button>
          </div>
        </Dialog>
      )}
    </div>
  );
}

export function ProfileEditScreen() {
  const me = useMeResource();
  const consent = useConsentResource();
  const verification = useVerificationResource();
  const profile = me.state.data;
  const ready = profile !== undefined && consent.state.status !== "loading";
  return (
    <>
      <ScreenHeader eyebrow="Mon profil" title="Modifier le profil" />
      <div className="screen-body">
        {ready ? (
          <Editor me={profile} granted={consent.state.data === true} level={verification.state.data?.level ?? profile.profile?.verification_level ?? "none"} onSaved={me.reload} />
        ) : me.state.status === "error" ? (
          <EmptyState title="Profil indisponible" action={<button type="button" className="btn btn-outline btn-sm" onClick={() => void me.reload()}>Réessayer</button>}>{describeError(me.state.error)}</EmptyState>
        ) : (
          <div className="page stack gap-16"><Skeleton height={48} /><Skeleton height={320} radius={24} /></div>
        )}
      </div>
    </>
  );
}
