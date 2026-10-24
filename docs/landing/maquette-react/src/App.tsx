import { Footer, Nav } from "./Chrome";
import { Hero } from "./Hero";
import { isLightweight, prefersMotion, useReveal, useScrollProgress } from "./hooks";
import { Compatibility, Desktop, FinalCta, Journey, Security, Shabbat, Verification } from "./Sections";

const animate = prefersMotion();
const lightweight = isLightweight();

export function App() {
  const scroll = useScrollProgress(animate);
  useReveal(animate);
  return (
    <>
      <a className="skip" href="#contenu">Aller au contenu</a>
      <Nav />
      <main id="contenu">
        <Hero animate={animate} lightweight={lightweight} scroll={scroll} />
        <Verification animate={animate} scroll={scroll} />
        <Compatibility />
        <Shabbat animate={animate} lightweight={lightweight} />
        <Journey />
        <Desktop />
        <Security />
        <FinalCta />
      </main>
      <Footer />
    </>
  );
}
