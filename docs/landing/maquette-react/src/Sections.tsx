import { useRef, type CSSProperties, type ReactNode } from "react";
import { createFlameScene } from "../../../../landing/src/scene/flame";
import { createOutroScene } from "../../../../landing/src/scene/outro";
import { createPhoneScene } from "../../../../landing/src/scene/phone";
import { seeded } from "../../../../landing/src/scene/random";
import { useScene, type ScrollProgress } from "./hooks";
import { APP_STORE_URL, WEB_APP_URL } from "./links";

const delay = (ms: number): CSSProperties => ({ "--d": `${ms}ms` } as CSSProperties);
const Dot = ({ gold = false }: { readonly gold?: boolean }) => <span className={gold ? "dot dot--gold" : "dot"}>.</span>;

interface StepProps {
  readonly n: number;
  readonly title: string;
  readonly delayMs: number;
  readonly children: ReactNode;
}
const Step = ({ n, title, delayMs, children }: StepProps) => (
  <li className="step" data-reveal style={delay(delayMs)}>
    <span className="step__n" aria-hidden="true">{n}</span>
    <div><h3>{title}</h3><p>{children}</p></div>
  </li>
);

export function Verification({ animate, scroll }: { readonly animate: boolean; readonly scroll: ScrollProgress }) {
  const canvas = useRef<HTMLCanvasElement>(null);
  const { failed } = useScene(canvas, (element) => createPhoneScene({ canvas: element, animate, progress: scroll.phone }));
  return (
    <section className="section section--paper" id="verification" aria-labelledby="t-verification">
      <div className="wrap split">
        <div className="split__text">
          <p className="eyebrow" data-reveal>01 — Vérification</p>
          <h2 className="display" id="t-verification" data-reveal style={delay(60)}>Chaque profil est vérifié. Vraiment<Dot /></h2>
          <p className="lead" data-reveal style={delay(120)}>Ici, la personne qui vous écrit est celle des photos. Pas son cousin. Pas une photo de&nbsp;2014.</p>
          <p className="note" data-reveal style={delay(150)}>Nous avons vérifié des passeports pour que vous n’ayez pas à mener l’enquête.</p>
          <ol className="steps">
            <Step n={1} title="Un selfie en direct" delayMs={140}>La vérification faciale confirme que le visage devant l’écran est bien celui du profil.</Step>
            <Step n={2} title="La puce NFC de votre pièce d’identité" delayMs={220}>Votre téléphone lit la puce de votre passeport ou de votre carte d’identité&nbsp;: l’identité est établie, pas seulement déclarée.</Step>
          </ol>
        </div>
        <div className="split__visual phone-stage" data-phone-stage>
          <canvas className="phone-stage__canvas" ref={canvas} hidden={failed} role="img" aria-label="Un téléphone affichant un profil marqué « Vérifié »" />
        </div>
      </div>
    </section>
  );
}

const STREAMS = ["Laïque", "Libéral", "Traditionaliste", "Massorti", "Orthodoxe moderne", "Orthodoxe", "Habad"];

function ChipGroup({ label, chips, accent = false }: { readonly label: string; readonly chips: readonly string[]; readonly accent?: boolean }) {
  return (
    <div className="chip-group" data-chips>
      <p className="mono-label">{label}</p>
      <ul className="chips">
        {chips.map((chip) => <li key={chip} className={accent ? "chip chip--accent" : "chip"}>{chip}</li>)}
      </ul>
    </div>
  );
}

export function Compatibility() {
  return (
    <section className="section section--mist" id="compatibilite" aria-labelledby="t-compat">
      <div className="wrap">
        <div className="center">
          <p className="eyebrow" data-reveal>02 — Compatibilité</p>
          <h2 className="display" id="t-compat" data-reveal style={delay(60)}>Une compatibilité qui comprend votre pratique<Dot /></h2>
          <p className="lead lead--center" data-reveal style={delay(120)}>Courant, cashrout, chabbat, intention&nbsp;: ce qui compte vraiment pour vous entre dans la balance, pas seulement l’âge et la ville.</p>
          <p className="note note--center" data-reveal style={delay(160)}>Laïque ou Habad, on ne juge pas. On rapproche.</p>
        </div>
        <div className="chip-groups">
          <ChipGroup label="Courant" chips={STREAMS} />
          <ChipGroup label="Cashrout & chabbat" chips={["Cashrout", "Chabbat"]} />
          <ChipGroup label="Intention" chips={["Mariage", "Relation sérieuse"]} accent />
        </div>
        <p className="note note--center note--below" data-reveal>Notre algorithme ne connaît pas votre tante. Mais il sait si vous préférez une table cacher à la maison ou pas.</p>
        <div className="cards cards--two">
          <article className="card" data-reveal>
            <h3>Réciproque</h3>
            <p>Une personne ne vous est proposée que si l’intérêt est probable des deux côtés. Moins de profils sans suite, plus de rencontres qui ont une chance d’aboutir.</p>
          </article>
          <article className="card" data-reveal style={delay(100)}>
            <h3>Explicable</h3>
            <p>Vous voyez pourquoi une personne vous est proposée. Pas de boîte noire&nbsp;: la compatibilité se lit, se comprend et se discute.</p>
          </article>
        </div>
      </div>
    </section>
  );
}

export function Shabbat({ animate, lightweight }: { readonly animate: boolean; readonly lightweight: boolean }) {
  const canvas = useRef<HTMLCanvasElement>(null);
  const { failed } = useScene(canvas, (element) => createFlameScene({ canvas: element, animate, lightweight }));
  return (
    <section className="section section--shabbat" id="chabbat" aria-labelledby="t-chabbat" data-shabbat>
      <canvas className="shabbat__canvas" ref={canvas} hidden={failed} aria-hidden="true" />
      <div className="wrap shabbat__inner">
        <p className="eyebrow eyebrow--gold" data-reveal>03 — Mode chabbat</p>
        <h2 className="display display--shabbat" id="t-chabbat" data-reveal style={delay(60)}>Chabbat chalom<Dot gold /></h2>
        <p className="lead lead--shabbat" data-reveal style={delay(120)}>Du vendredi soir à la sortie de chabbat, MAZL se met en pause et prend les couleurs de la bougie. Vous retrouvez la table, vos proches et le repos. Les rencontres vous attendront.</p>
        <p className="note note--shabbat" data-reveal style={delay(180)}>Pendant chabbat, MAZL se repose aussi. C’est dans les CGU. Enfin, presque.</p>
      </div>
    </section>
  );
}

export function Journey() {
  return (
    <section className="section section--paper" id="couple" aria-labelledby="t-couple">
      <div className="wrap">
        <div className="center">
          <p className="eyebrow" data-reveal>04 — Du premier message au couple</p>
          <h2 className="display" id="t-couple" data-reveal style={delay(60)}>Votre histoire ne s’arrête pas au premier échange<Dot /></h2>
        </div>
        <ol className="journey" data-progress>
          <li className="journey__item" data-reveal>
            <span className="journey__node" aria-hidden="true" />
            <h3>Premier message</h3>
            <p>Une conversation sincère avec quelqu’un dont l’identité est vérifiée.</p>
          </li>
          <li className="journey__item" data-reveal style={delay(120)}>
            <span className="journey__node" aria-hidden="true" />
            <h3>Premier café</h3>
            <p>Les événements de la communauté vous offrent l’occasion de vous retrouver autour de la même table.</p>
          </li>
          <li className="journey__item" data-reveal style={delay(240)}>
            <span className="journey__node" aria-hidden="true" />
            <h3>Premier dîner chez les parents (courage)</h3>
            <p>Puis, mazal tov.</p>
          </li>
        </ol>
        <p className="note note--center note--below" data-reveal>Ensuite, MAZL passe en mode couple. On ne vous lâche pas comme ça.</p>
      </div>
    </section>
  );
}

const QR_SIZE = 15;

function QrGrid() {
  const random = seeded(613);
  const inFinder = (x: number, y: number): boolean => (x < 5 && y < 5) || (x > QR_SIZE - 6 && y < 5) || (x < 5 && y > QR_SIZE - 6);
  const finderOn = (x: number, y: number): boolean => {
    const fx = x < 5 ? x : x - (QR_SIZE - 5);
    const fy = y < 5 ? y : y - (QR_SIZE - 5);
    return fx === 0 || fx === 4 || fy === 0 || fy === 4 || (fx === 2 && fy === 2);
  };
  const cells: ReactNode[] = [];
  for (let y = 0; y < QR_SIZE; y++) {
    for (let x = 0; x < QR_SIZE; x++) {
      const on = inFinder(x, y) ? finderOn(x, y) : random() > 0.52;
      cells.push(<i key={`${x}-${y}`} className={on ? undefined : "off"} />);
    }
  }
  return <div className="qr__grid">{cells}</div>;
}

export function Desktop() {
  return (
    <section className="section section--mist" id="ordinateur" aria-labelledby="t-ordi">
      <div className="wrap split split--reverse">
        <div className="split__text">
          <p className="eyebrow" data-reveal>05 — MAZL sur ordinateur</p>
          <h2 className="display" id="t-ordi" data-reveal style={delay(60)}>Aussi sur grand écran<Dot /></h2>
          <p className="lead" data-reveal style={delay(120)}>Vos conversations sur grand écran. Pour quand le téléphone est trop petit pour tout ce que vous avez à vous dire.</p>
          <p className="lead lead--small" data-reveal style={delay(180)}>Pour vous connecter, ouvrez MAZL sur votre téléphone et scannez le QR code affiché à l’écran.</p>
          <a className="btn btn--ink" href={WEB_APP_URL} data-reveal style={delay(240)}>Ouvrir MAZL sur ordinateur</a>
        </div>
        <div className="split__visual" data-reveal style={delay(100)}>
          <div className="browser" aria-hidden="true">
            <div className="browser__bar"><i /><i /><i /><span>mazl.app/app</span></div>
            <div className="browser__body">
              <div className="browser__rail"><b /><b /><b /><b /></div>
              <div className="browser__list"><u /><u /><u /><u /><u /></div>
              <div className="browser__chat">
                <div className="bubble bubble--in" />
                <div className="bubble bubble--out" />
                <div className="bubble bubble--in bubble--short" />
                <div className="qr"><QrGrid /><p>Scannez depuis l’app</p></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

const SECURITY: readonly (readonly [string, string])[] = [
  ["Une modération humaine", "Des personnes examinent chaque signalement."],
  ["Signaler et bloquer", "En un geste, vous signalez un comportement ou vous bloquez un profil. Vous gardez la main."],
  ["Votre pratique reste privée", "Vos données de pratique religieuse sont protégées et ne sont utilisées qu’avec votre consentement explicite."],
];

export function Security() {
  return (
    <section className="section section--paper" id="securite" aria-labelledby="t-securite">
      <div className="wrap">
        <div className="center">
          <p className="eyebrow" data-reveal>06 — Sécurité & vie privée</p>
          <h2 className="display" id="t-securite" data-reveal style={delay(60)}>Le respect, d’abord<Dot /></h2>
          <p className="lead lead--center" data-reveal style={delay(120)}>Une communauté se construit sur la confiance. Chaque détail de MAZL est pensé pour la protéger.</p>
        </div>
        <div className="cards cards--three">
          {SECURITY.map(([title, text], index) => (
            <article key={title} className="card card--outline" data-reveal style={delay(index * 100)}>
              <h3>{title}</h3>
              <p>{text}</p>
            </article>
          ))}
        </div>
        <p className="note note--center note--below" data-reveal>Les seules surprises qu’on aime, ce sont les bonnes.</p>
      </div>
    </section>
  );
}

export function FinalCta({ animate, lightweight, scroll }: { readonly animate: boolean; readonly lightweight: boolean; readonly scroll: ScrollProgress }) {
  const canvas = useRef<HTMLCanvasElement>(null);
  const { failed } = useScene(canvas, (element) => createOutroScene({ canvas: element, animate, lightweight, progress: scroll.outro }));
  return (
    <section className="outro" id="telecharger" aria-labelledby="t-final" data-outro>
      <div className="outro__stage">
        <canvas className="outro__canvas" ref={canvas} hidden={failed} aria-hidden="true" />
        <div className="outro__line">
          <h2 className="display display--xl" id="t-final">Votre mazal vous attend<Dot /></h2>
          <p className="outro__sub">Il se demande peut-être déjà pourquoi vous n’êtes pas encore là.</p>
        </div>
        <p className="outro__word" aria-hidden="true">mazl<span>.</span></p>
        <div className="outro__actions">
          <div className="hero__actions hero__actions--center">
            <a className="btn btn--accent" href={APP_STORE_URL} rel="noopener">Télécharger sur l’App&nbsp;Store</a>
            <a className="btn btn--ghost-ink" href={WEB_APP_URL}>Se connecter</a>
          </div>
          <p className="outro__note">Gratuit. Votre tante a vérifié.</p>
        </div>
      </div>
    </section>
  );
}
