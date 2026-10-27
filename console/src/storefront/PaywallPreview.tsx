import type { CSSProperties, ReactElement } from "react";
import { Glyph } from "./Glyph";
import { paywallLines, readableOn, untilLabel } from "./preview-model";
import { isRtl, LANG_LABELS } from "./theme-texts";
import { accentForConsole, themeById } from "./themes";
import { LANGS, type CampaignTarget, type CampaignTexts, type Lang, type ProductDto, type ThemeId } from "./types";

interface Props {
  readonly themeId: ThemeId;
  readonly texts: CampaignTexts;
  readonly lang: Lang;
  readonly onLang: (lang: Lang) => void;
  readonly endsAt: string;
  readonly products: readonly ProductDto[];
  readonly targets: readonly CampaignTarget[];
}

/** Gabarit de l'écran mazl+ tel que l'app le montrera pendant la campagne : glyphe, accent, titre, sous-titre, fin, remises, bouton. */
export function PaywallPreview({ themeId, texts, lang, onLang, endsAt, products, targets }: Props): ReactElement {
  const theme = themeById(themeId);
  const lines = paywallLines(products, targets, lang);
  const style = { "--c": accentForConsole(theme), "--on-c": theme.accent.toUpperCase() === "#0B0B0F" ? "var(--bg)" : readableOn(theme.accent) } as CSSProperties;
  return (
    <figure className="paywall-wrap">
      <div className="paywall-lang" role="group" aria-label="Langue de l'aperçu">
        {LANGS.map((code) => (
          <button key={code} type="button" className={`lang-chip${code === lang ? " is-active" : ""}`} aria-pressed={code === lang} lang={code} onClick={() => onLang(code)}>
            {LANG_LABELS[code]}
          </button>
        ))}
      </div>
      <div className="paywall" style={style} dir={isRtl(lang) ? "rtl" : "ltr"} lang={lang}>
        <div className="paywall-glyph">
          <Glyph glyph={theme.glyph} size={30} />
        </div>
        <h3 className="paywall-title">{texts.title}</h3>
        <p className="paywall-sub">{texts.subtitle}</p>
        <p className="paywall-until">{untilLabel(endsAt, lang)}</p>
        <ul className="paywall-offers">
          {lines.map((line) => (
            <li key={line.productId} className={`paywall-offer${line.badge !== null ? " is-promo" : ""}`}>
              <span className="paywall-offer-name">
                {line.name}
                {line.highlight !== null ? <span className="paywall-highlight">{line.highlight}</span> : null}
              </span>
              <span className="paywall-offer-price">
                {line.badge !== null ? <span className="paywall-badge">{line.badge}</span> : null}
                {line.oldPrice !== null ? <s>{line.oldPrice}</s> : null}
                <strong>{line.price}</strong>
              </span>
            </li>
          ))}
        </ul>
        <span className="paywall-cta" aria-hidden="true">
          {texts.cta}
        </span>
      </div>
      <figcaption className="paywall-caption">Écran mazl+ pendant la campagne. Le prix vient d'Apple ; la remise s'applique par code d'offre, ici en aperçu.</figcaption>
    </figure>
  );
}
