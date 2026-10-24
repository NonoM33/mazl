import { useRef } from "react";
import { createHeroScene } from "../../../../landing/src/scene/hero";
import { useScene, type ScrollProgress } from "./hooks";
import { APP_STORE_URL, WEB_APP_URL } from "./links";

interface SceneProps {
  readonly animate: boolean;
  readonly lightweight: boolean;
  readonly scroll: ScrollProgress;
}

export function Hero({ animate, lightweight, scroll }: SceneProps) {
  const canvas = useRef<HTMLCanvasElement>(null);
  const { ready, failed } = useScene(canvas, (element) =>
    createHeroScene({ canvas: element, animate, lightweight, progress: scroll.hero }));
  return (
    <section className="hero" id="accueil" data-hero>
      <div className="hero__stage">
        <canvas className="hero__canvas" ref={canvas} hidden={failed} aria-hidden="true" />
        <div className="hero__shade" aria-hidden="true" />
        <div className="hero__copy">
          <p className="eyebrow eyebrow--on-ink" data-reveal>L’application de rencontre de la communauté juive</p>
          <h1 className="hero__title" data-reveal style={{ "--d": "80ms" } as React.CSSProperties}>
            Trouvez votre&nbsp;mazal<span className="dot">.</span>
          </h1>
          <p className="hero__lead" data-reveal style={{ "--d": "180ms" } as React.CSSProperties}>
            Pour des relations sérieuses.<br />Votre mère sera ravie. Vous aussi, promis.
          </p>
          <div className="hero__actions" data-reveal style={{ "--d": "280ms" } as React.CSSProperties}>
            <a className="btn btn--accent" href={APP_STORE_URL} rel="noopener">Télécharger sur l’App&nbsp;Store</a>
            <a className="btn btn--ghost-ink" href={WEB_APP_URL}>Ouvrir MAZL sur ordinateur</a>
          </div>
        </div>
        {!ready && !failed && <p className="hero__loading">Les deux étoiles se cherchent…</p>}
        <p className="hero__caption">Deux parcours. <em>Un seul fil.</em></p>
        <p className="hero__scroll eyebrow eyebrow--on-ink" aria-hidden="true">
          Défiler
          <small>(oui, on fait durer le suspense)</small>
        </p>
      </div>
    </section>
  );
}
