import { useMemo, useState, type ReactElement } from "react";
import { useMe, useSession } from "../app/session";
import { Badge } from "../shared/ui/Badge";
import { Button } from "../shared/ui/Button";
import { Drawer } from "../shared/ui/Drawer";
import { Field } from "../shared/ui/Field";
import { Icon } from "../shared/ui/Icon";
import { Select } from "../shared/ui/Select";
import { Tabs, tabButtonId, tabPanelId } from "../shared/ui/Tabs";
import { useToast } from "../shared/ui/Toast";
import { canWriteStorefront, SUPER_ADMIN_ONLY } from "./access";
import { AppIconPreview } from "./AppIconPreview";
import { storefrontApi } from "./api";
import { CancelDialog, PublishDialog } from "./CampaignDialogs";
import { CTA_MAX, DISCOUNT_MAX, DISCOUNT_MIN, NAME_MAX, SUBTITLE_MAX, TITLE_MAX, defaultTargets, discountedAmount, errorMessages, formFromCampaign, hasErrors, parseDiscount, validateForm, type CampaignForm, type FormErrors } from "./campaign-form";
import { STATE_LABELS, STATE_TONES, campaignState, countdown, editability } from "./campaign-state";
import { storefrontErrorMessage } from "./errors";
import { Glyph } from "./Glyph";
import { LangField } from "./LangFields";
import { formatLastDay, formatParis, parisLocalToIso } from "./paris-time";
import { PaywallPreview } from "./PaywallPreview";
import { applePrice, formatMoney } from "./price-change";
import { findOverlaps } from "./timeline";
import { defaultTexts, LANG_LABELS } from "./theme-texts";
import { THEMES, themeById } from "./themes";
import { LANGS, type CampaignDto, type Lang, type ProductDto, type ThemeId } from "./types";

interface Props {
  /** Campagne existante, ou null pour une nouvelle. */
  readonly campaign: CampaignDto | null;
  /** Valeurs de départ d'une nouvelle campagne. */
  readonly initial: CampaignForm | null;
  readonly products: readonly ProductDto[];
  readonly others: readonly CampaignDto[];
  readonly onClose: () => void;
  /** Appelé après toute écriture ; `openId` : campagne à ouvrir ensuite. */
  readonly onChanged: (openId: number | null) => void;
}

const PREFIX = "ctxt";

export function CampaignEditor({ campaign, initial, products, others, onClose, onChanged }: Props): ReactElement {
  const { api } = useSession();
  const me = useMe();
  const toast = useToast();
  const store = storefrontApi(api);
  const canWrite = canWriteStorefront(me);
  const now = new Date();
  const mode = campaign === null ? "full" : editability(campaign, now);
  const start = useMemo<CampaignForm | null>(() => (campaign === null ? initial : formFromCampaign(campaign, products)), [campaign, initial, products]);
  const [form, setForm] = useState<CampaignForm | null>(start);
  const [errors, setErrors] = useState<FormErrors>({});
  const [failure, setFailure] = useState<string | null>(null);
  const [textLang, setTextLang] = useState<Lang>("fr");
  const [previewLang, setPreviewLang] = useState<Lang>("fr");
  const [busy, setBusy] = useState(false);
  const [dialog, setDialog] = useState<"publish" | "cancel" | null>(null);

  if (form === null || start === null) return <Drawer title="Campagne" onClose={onClose}>{null}</Drawer>;

  const dirty = JSON.stringify(form) !== JSON.stringify(start);
  const state = campaign === null ? "draft" : campaignState(campaign, now);
  const theme = themeById(form.themeId);
  const set = (changes: Partial<CampaignForm>): void => setForm((current) => (current === null ? current : { ...current, ...changes }));
  const readOnly = mode !== "full";
  const contentLocked = mode === "end-only" || mode === "locked";

  const startsAt = parisLocalToIso(form.startsLocal);
  const endsAt = parisLocalToIso(form.endsLocal);
  const clash = startsAt !== null && endsAt !== null ? others.filter((other) => other.id !== campaign?.id && other.status === "scheduled" && findOverlaps([{ key: "this", startsAt, endsAt }, { key: other.id, startsAt: other.startsAt, endsAt: other.endsAt }]).size > 0) : [];

  const changeTheme = (next: ThemeId | ""): void => {
    if (next === "" || readOnly) return;
    const unchangedTexts = JSON.stringify(form.texts) === JSON.stringify(defaultTexts(form.themeId));
    set({ themeId: next, texts: unchangedTexts ? defaultTexts(next) : form.texts, targets: defaultTargets(products, next, form.targets.filter((t) => t.enabled).map((t) => ({ productId: t.productId, discountPercent: parseDiscount(t.discountText) ?? 0 })).filter((t) => t.discountPercent > 0)) });
  };

  const fail = (message: string): void => {
    setFailure(message);
    toast.notify(message, "error");
  };

  const save = async (): Promise<void> => {
    setFailure(null);
    if (mode === "end-only" && campaign !== null) {
      if (endsAt === null) return setErrors({ endsLocal: "Choisissez la nouvelle date de fin." });
      if (Date.parse(endsAt) <= now.getTime()) return setErrors({ endsLocal: "La nouvelle fin doit être dans le futur ; pour arrêter tout de suite, annulez la campagne." });
      if (Date.parse(endsAt) >= Date.parse(campaign.endsAt)) return setErrors({ endsLocal: "Une campagne en cours ne peut qu'être raccourcie." });
      setErrors({});
      setBusy(true);
      const result = await store.updateCampaign(campaign.id, { endsAt });
      setBusy(false);
      if (!result.ok) return fail(storefrontErrorMessage(result));
      toast.notify("Fin de campagne avancée.", "success");
      return onChanged(campaign.id);
    }
    const checked = validateForm(form);
    if (!checked.ok) {
      setErrors(checked.errors);
      return;
    }
    setErrors({});
    setBusy(true);
    const body = mode === "partial" ? { name: checked.input.name, texts: checked.input.texts, changeAppIcon: checked.input.changeAppIcon } : checked.input;
    const result = campaign === null ? await store.createCampaign(checked.input) : await store.updateCampaign(campaign.id, body);
    setBusy(false);
    if (!result.ok) return fail(storefrontErrorMessage(result));
    toast.notify(campaign === null ? "Brouillon enregistré." : "Campagne enregistrée.", "success");
    onChanged(result.data.id);
  };

  const publish = async (): Promise<string | null> => {
    if (campaign === null) return null;
    const result = await store.publish(campaign.id);
    if (!result.ok) return storefrontErrorMessage(result);
    toast.notify("Campagne programmée.", "success");
    setDialog(null);
    onChanged(campaign.id);
    return null;
  };

  const cancel = async (): Promise<string | null> => {
    if (campaign === null) return null;
    const result = await store.cancel(campaign.id);
    if (!result.ok) return storefrontErrorMessage(result);
    toast.notify("Campagne annulée.", "success");
    setDialog(null);
    onChanged(campaign.id);
    return null;
  };

  const previewTexts = ((): CampaignForm["texts"][Lang] => {
    const t = form.texts[previewLang];
    return t.title.trim() === "" && t.subtitle.trim() === "" && t.cta.trim() === "" ? form.texts.fr : t;
  })();
  const previewTargets = form.targets.filter((t) => t.enabled).flatMap((t) => {
    const discount = parseDiscount(t.discountText);
    return discount === null ? [] : [{ productId: t.productId, discountPercent: discount }];
  });
  const textErrorLangs = new Set(Object.keys(errors.texts ?? {}));
  const summaryErrors = errorMessages(errors);

  return (
    <Drawer title={campaign === null ? "Nouvelle campagne" : campaign.name} eyebrow={campaign === null ? "Brouillon" : `${theme.label} · campagne n°${campaign.id}`} onClose={onClose} extraWide>
      <div className="editor">
        <div className="editor-form stack">
          <div className="editor-state">
            <Badge tone={STATE_TONES[state]}>{STATE_LABELS[state]}</Badge>
            {campaign !== null && countdown(campaign, now) !== null ? <span className="muted">{countdown(campaign, now)}</span> : null}
          </div>
          {mode === "locked" && campaign !== null ? <p className="notice notice-info">Cette campagne est {state === "cancelled" ? "annulée" : "terminée"} : elle ne se modifie plus.</p> : null}
          {mode === "partial" ? <p className="notice notice-info">Cette campagne est programmée : vous pouvez changer son nom, ses textes et l'icône. Les dates et les produits en remise sont verrouillés (codes déjà créés chez Apple et Stripe) : pour les changer, annulez la campagne puis créez-en une autre.</p> : null}
          {mode === "end-only" ? <p className="notice notice-info">Cette campagne est en cours : vous pouvez seulement avancer sa fin, ou l'annuler.</p> : null}
          {campaign?.apple?.error !== undefined && campaign.apple.error !== null ? (
            <p className="notice notice-error" role="alert">
              Dernière tentative chez Apple : {campaign.apple.error}
            </p>
          ) : null}
          {campaign?.apple !== null && campaign?.apple !== undefined && campaign.apple.offerCodes.length > 0 ? (
            <p className="notice notice-info">
              Codes d'offre Apple : <span className="mono">{campaign.apple.offerCodes.join(", ")}</span>
              {campaign.stripe !== null ? (
                <>
                  {" "}
                  · code promo Stripe : <span className="mono">{campaign.stripe.promotionCode}</span>
                </>
              ) : null}
            </p>
          ) : null}
          {clash.length > 0 ? (
            <p className="notice notice-warning" role="alert">
              Ces dates chevauchent {clash.map((other) => `« ${other.name} »`).join(", ")}, déjà programmée. Deux campagnes programmées ne peuvent pas se chevaucher.
            </p>
          ) : null}

          <section className="card" aria-labelledby="ed-general">
            <h2 id="ed-general">Thème et dates</h2>
            <div className="stack editor-block">
              <Select label="Thème" value={form.themeId} options={THEMES.map((t) => ({ value: t.id, label: t.label }))} onChange={changeTheme} hint={readOnly ? undefined : "Le thème donne le glyphe, la couleur, l'icône de l'app et les textes de départ."} />
              <Field label="Nom interne" hint="Pour s'y retrouver dans la console ; les membres ne le voient pas." error={errors.name} counter={<span className={form.name.length > NAME_MAX ? "is-over" : undefined}>{form.name.length}&nbsp;/&nbsp;{NAME_MAX}</span>}>
                {({ id, describedBy, invalid }) => <input id={id} className="input" value={form.name} disabled={contentLocked} aria-describedby={describedBy} aria-invalid={invalid || undefined} onChange={(event) => set({ name: event.target.value })} />}
              </Field>
              <div className="grid-2 editor-dates">
                <Field label="Début" error={errors.startsLocal} hint="Heure de Paris">
                  {({ id, describedBy, invalid }) => <input id={id} type="datetime-local" className="input" value={form.startsLocal} disabled={readOnly} aria-describedby={describedBy} aria-invalid={invalid || undefined} onChange={(event) => set({ startsLocal: event.target.value })} />}
                </Field>
                <Field label="Fin" error={errors.endsLocal ?? errors.range} hint={endsAt === null ? "Heure de Paris" : `Affichée « jusqu'au ${formatLastDay(endsAt)} » · heure de Paris`}>
                  {({ id, describedBy, invalid }) => <input id={id} type="datetime-local" className="input" value={form.endsLocal} disabled={mode !== "full" && mode !== "end-only"} aria-describedby={describedBy} aria-invalid={invalid || undefined} onChange={(event) => set({ endsLocal: event.target.value })} />}
                </Field>
              </div>
              {startsAt !== null && endsAt !== null ? (
                <p className="field-hint">
                  Du {formatParis(startsAt)} au {formatParis(endsAt)}.
                </p>
              ) : null}
              <label className="check check-accent">
                <input type="checkbox" checked={form.changeAppIcon} disabled={contentLocked} onChange={(event) => set({ changeAppIcon: event.target.checked })} />
                <span>
                  Changer l'icône de l'app pendant la campagne
                  <span className="field-hint check-hint">iOS prévient chaque membre par une alerte système, et le changement n'a lieu que quand l'app est au premier plan.</span>
                </span>
              </label>
            </div>
          </section>

          <section className="card" aria-labelledby="ed-texts">
            <div className="card-head">
              <h2 id="ed-texts">Textes de l'écran mazl+</h2>
              {!contentLocked ? (
                <Button size="s" variant="ghost" icon="wand" onClick={() => set({ texts: defaultTexts(form.themeId) })}>
                  Remettre ceux du thème
                </Button>
              ) : null}
            </div>
            <Tabs label="Langue des textes" prefix={PREFIX} tabs={LANGS.map((lang) => ({ id: lang, label: `${LANG_LABELS[lang]}${textErrorLangs.has(lang) ? " •" : ""}` }))} active={textLang} onSelect={(lang) => { setTextLang(lang); setPreviewLang(lang); }} />
            <div role="tabpanel" id={tabPanelId(PREFIX)} aria-labelledby={tabButtonId(PREFIX, textLang)} className="tabpanel stack editor-block">
              <LangField label="Titre" lang={textLang} max={TITLE_MAX} value={form.texts[textLang].title} disabled={contentLocked} onChange={(title) => set({ texts: { ...form.texts, [textLang]: { ...form.texts[textLang], title } } })} error={errors.texts?.[textLang]} />
              <LangField label="Sous-titre" lang={textLang} max={SUBTITLE_MAX} multiline value={form.texts[textLang].subtitle} disabled={contentLocked} onChange={(subtitle) => set({ texts: { ...form.texts, [textLang]: { ...form.texts[textLang], subtitle } } })} />
              <LangField label="Bouton" lang={textLang} max={CTA_MAX} value={form.texts[textLang].cta} disabled={contentLocked} onChange={(cta) => set({ texts: { ...form.texts, [textLang]: { ...form.texts[textLang], cta } } })} hint={textLang === "fr" ? "Le français est obligatoire. Une langue laissée vide reprend le français." : undefined} />
            </div>
          </section>

          <section className="card" aria-labelledby="ed-targets">
            <h2 id="ed-targets">Produits en remise</h2>
            <p className="card-lead">Une remise d'abonnement passe par un code d'offre Apple (le prix de base ne change pas) ; sur le site, par un coupon Stripe.</p>
            <ul className="target-list">
              {form.targets.map((target) => {
                const product = products.find((p) => p.productId === target.productId);
                if (product === undefined) return null;
                const france = applePrice(product, "FRA");
                const discount = parseDiscount(target.discountText);
                const error = errors.targets?.[target.productId];
                return (
                  <li key={target.productId} className="target-row">
                    <label className="check check-plain target-name">
                      <input type="checkbox" checked={target.enabled} disabled={readOnly} onChange={(event) => set({ targets: form.targets.map((t) => (t.productId === target.productId ? { ...t, enabled: event.target.checked } : t)) })} />
                      <span className="cell-stack">
                        <strong>{product.label}</strong>
                        <span className="cell-sub">
                          {france !== undefined ? formatMoney(france.amount, france.currency) : "prix indisponible"}
                          {target.enabled && discount !== null && france !== undefined ? ` → ${formatMoney(discountedAmount(Number(france.amount), discount), france.currency)}` : ""}
                        </span>
                      </span>
                    </label>
                    <span className="target-discount">
                      <input
                        className="input input-narrow"
                        inputMode="numeric"
                        aria-label={`Remise sur ${product.label}, en pourcent`}
                        aria-invalid={error !== undefined || undefined}
                        value={target.discountText}
                        disabled={readOnly || !target.enabled}
                        onChange={(event) => set({ targets: form.targets.map((t) => (t.productId === target.productId ? { ...t, discountText: event.target.value } : t)) })}
                      />
                      <span aria-hidden="true">%</span>
                    </span>
                    {error !== undefined ? (
                      <p className="field-error target-error" role="alert">
                        {error}
                      </p>
                    ) : null}
                  </li>
                );
              })}
            </ul>
            <p className="field-hint">Remise entre {DISCOUNT_MIN} et {DISCOUNT_MAX} %.</p>
          </section>

          {summaryErrors.length > 0 && hasErrors(errors) ? (
            <p className="notice notice-error" role="alert">
              {summaryErrors.length === 1 ? summaryErrors[0] : `${summaryErrors.length} points à corriger avant d'enregistrer.`}
            </p>
          ) : null}
          {failure !== null ? (
            <p className="notice notice-error" role="alert">
              {failure}
            </p>
          ) : null}

          <div className="editor-actions">
            {campaign !== null && state !== "cancelled" && state !== "ended" ? (
              <Button variant="danger" icon="close" disabled={!canWrite} title={canWrite ? undefined : SUPER_ADMIN_ONLY} onClick={() => setDialog("cancel")}>
                Annuler la campagne
              </Button>
            ) : null}
            <span className="editor-spacer" />
            {mode !== "locked" ? (
              <Button variant="secondary" loading={busy} disabled={campaign !== null && !dirty} onClick={() => void save()}>
                {mode === "end-only" ? "Avancer la fin" : campaign === null ? "Enregistrer le brouillon" : "Enregistrer"}
              </Button>
            ) : null}
            {campaign !== null && state === "draft" ? (
              <Button variant="primary" icon="check" disabled={!canWrite || dirty} title={!canWrite ? SUPER_ADMIN_ONLY : dirty ? "Enregistrez d'abord vos modifications." : undefined} onClick={() => setDialog("publish")}>
                Programmer
              </Button>
            ) : null}
          </div>
          {!canWrite && campaign !== null && state !== "cancelled" && state !== "ended" ? (
            <p className="field-hint">
              <Icon name="lock" size={13} /> Programmer et annuler une campagne est réservé aux super-administrateurs.
            </p>
          ) : null}
        </div>

        <aside className="editor-preview" aria-label="Aperçu">
          <div className="card preview-card">
            <h2>Aperçu</h2>
            <div className="preview-icons">
              <figure className="preview-icon">
                <span style={{ opacity: form.changeAppIcon ? 1 : 0.45 }}>
                  <AppIconPreview themeId={form.themeId} size={88} />
                </span>
                <figcaption>{form.changeAppIcon ? `Icône « ${theme.label} »` : "L'icône ne changera pas"}</figcaption>
              </figure>
              <figure className="preview-icon">
                <AppIconPreview themeId={null} size={56} />
                <figcaption>Icône habituelle</figcaption>
              </figure>
              <div className="preview-theme">
                <Glyph glyph={theme.glyph} size={28} />
                <span className="swatch" style={{ background: theme.accent }} aria-hidden="true" />
                <span className="mono">{theme.accent}</span>
              </div>
            </div>
            <PaywallPreview themeId={form.themeId} texts={previewTexts} lang={previewLang} onLang={(lang) => { setPreviewLang(lang); setTextLang(lang); }} endsAt={endsAt ?? campaign?.endsAt ?? ""} products={products} targets={previewTargets} />
          </div>
        </aside>
      </div>
      {dialog === "publish" && campaign !== null ? <PublishDialog campaign={campaign} products={products} onClose={() => setDialog(null)} onConfirm={publish} /> : null}
      {dialog === "cancel" && campaign !== null ? <CancelDialog campaign={campaign} onClose={() => setDialog(null)} onConfirm={cancel} /> : null}
    </Drawer>
  );
}
