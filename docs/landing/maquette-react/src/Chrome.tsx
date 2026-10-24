import { APP_STORE_URL, WEB_APP_URL } from "./links";

export function Wordmark({ small = false }: { readonly small?: boolean }) {
  return (
    <a className={small ? "wordmark wordmark--small" : "wordmark"} href="#accueil" aria-label="MAZL, accueil">
      mazl
      <span className="tip" title="Ce point, c’est vous deux." data-tip="Ce point, c’est vous deux.">.</span>
    </a>
  );
}

const NAV_LINKS: readonly (readonly [string, string])[] = [
  ["#verification", "Vérification"],
  ["#compatibilite", "Compatibilité"],
  ["#chabbat", "Chabbat"],
  ["#couple", "Couple"],
  ["#ordinateur", "Ordinateur"],
  ["#securite", "Sécurité"],
];

export function Nav() {
  return (
    <header className="nav" id="nav">
      <div className="nav__inner">
        <Wordmark />
        <nav className="nav__links" aria-label="Sections">
          {NAV_LINKS.map(([href, label]) => <a key={href} href={href}>{label}</a>)}
        </nav>
        <div className="nav__actions">
          <a className="nav__login" href={WEB_APP_URL}>Se connecter</a>
          <a className="btn btn--small btn--accent" href={APP_STORE_URL} rel="noopener">Télécharger</a>
        </div>
      </div>
    </header>
  );
}

export function Footer() {
  return (
    <footer className="footer">
      <div className="wrap footer__inner">
        <Wordmark small />
        <nav className="footer__links" aria-label="Informations légales">
          <a href="#cgu">CGU</a>
          <a href="#cgv">CGV</a>
          <a href="#confidentialite">Confidentialité</a>
          <a href="mailto:hello@mazl.app">Contact</a>
        </nav>
        <p className="footer__copy">© MAZL</p>
      </div>
      <div className="wrap footer__humour">
        <p>Vous êtes tout en bas. Votre mazal, lui, est plutôt en haut, sur l’App&nbsp;Store.</p>
        <p>Fait avec amour, un peu de houmous et beaucoup de café à Paris.</p>
        <p>Une question, une idée, une histoire qui finit bien&nbsp;? <a href="mailto:hello@mazl.app">hello@mazl.app</a>. On lit tout, même les longs messages.</p>
      </div>
    </footer>
  );
}
