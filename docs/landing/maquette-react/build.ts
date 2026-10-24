// Construit la maquette : un seul HTML, JS + CSS + polices Geist en ligne, aucune requête réseau.
import { join } from "node:path";

const here = import.meta.dir;
const landing = join(here, "../../../landing");
const result = await Bun.build({
  entrypoints: [join(here, "src/main.tsx")],
  minify: true,
  target: "browser",
  format: "esm",
  define: { "process.env.NODE_ENV": JSON.stringify("production") },
});
if (!result.success) {
  for (const log of result.logs) console.error(log);
  process.exit(1);
}
const js = (await result.outputs[0]?.text() ?? "").replaceAll("</script", "<\\/script");

const FONTS: readonly (readonly [string, string, number])[] = [
  ["Geist", "Geist-400", 400], ["Geist", "Geist-500", 500], ["Geist", "Geist-600", 600], ["Geist", "Geist-700", 700],
  ["Geist Mono", "GeistMono-400", 400], ["Geist Mono", "GeistMono-500", 500],
];
const fontFaces: string[] = [];
for (const [family, file, weight] of FONTS) {
  const base64 = Buffer.from(await Bun.file(join(landing, `assets/fonts/${file}.ttf`)).arrayBuffer()).toString("base64");
  fontFaces.push(`@font-face{font-family:"${family}";src:url(data:font/ttf;base64,${base64}) format("truetype");font-weight:${weight};font-display:swap}`);
}
const read = (name: string): Promise<string> => Bun.file(join(landing, "src/styles", name)).text();
const tokens = (await read("tokens.css")).replace(/@font-face\s*\{[^}]*\}/g, "");
const css = [tokens, await read("base.css"), await read("hero.css"), await read("sections.css"), await Bun.file(join(here, "src/extra.css")).text()].join("\n");

const html = `<!doctype html>
<!-- Maquette MAZL — vitrine React + Three.js, données fictives, 2026-10-24 -->
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>MAZL — Trouvez votre mazal. (maquette)</title>
<style>${fontFaces.join("")}${css}</style>
</head>
<body>
<div id="root"></div>
<script type="module">${js}</script>
</body>
</html>
`;
const out = join(here, "mazl-vitrine-maquette.html");
await Bun.write(out, html);
console.log(`${out}  ${(html.length / 1024).toFixed(0)} kB`);
