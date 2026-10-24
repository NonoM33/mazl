import { readdir } from "node:fs/promises";
import { join } from "node:path";

// Bundle de la console staff (docs/backoffice/adr/0001-console-react-bun.md) : Bun.build sur
// console/index.html, résultat gardé EN MÉMOIRE et servi par Hono sous /console/.

export const CONSOLE_MOUNT = "/console";
const ASSET_PREFIX = `${CONSOLE_MOUNT}/assets/`;
const FONT_PREFIX = `${CONSOLE_MOUNT}/fonts/`;

export interface ConsoleAsset {
  readonly bytes: Uint8Array<ArrayBuffer>;
  readonly type: string;
  /** Nom contenant l'empreinte du contenu : cachable à vie. */
  readonly hashed: boolean;
}

export interface ConsoleBuild {
  readonly index: ConsoleAsset;
  /** Chemin relatif à /console/assets/ (« chunk-x.js ») ou /console/ (« fonts/Geist-400.ttf »). */
  readonly files: ReadonlyMap<string, ConsoleAsset>;
}

export interface ConsoleBuildOptions {
  /** Développement : pas de minification, React en mode développement. */
  readonly development?: boolean;
  /** Dossier de la console (par défaut `<dépôt>/console`). */
  readonly root?: string;
}

const DEFAULT_ROOT = join(import.meta.dir, "..", "..", "..", "console");
const FONT_TYPES: Readonly<Record<string, string>> = { ".ttf": "font/ttf", ".txt": "text/plain; charset=utf-8" };

function relativeName(path: string): string {
  return path.replace(/^\.\//, "");
}

async function readFonts(root: string): Promise<Map<string, ConsoleAsset>> {
  const fonts = new Map<string, ConsoleAsset>();
  const dir = join(root, "fonts");
  for (const name of await readdir(dir)) {
    const extension = name.slice(name.lastIndexOf("."));
    const type = FONT_TYPES[extension];
    if (type === undefined || name.startsWith(".")) continue;
    fonts.set(`fonts/${name}`, { bytes: new Uint8Array(await Bun.file(join(dir, name)).arrayBuffer()), type, hashed: false });
  }
  return fonts;
}

/**
 * Construit la console. Les polices (CSP `font-src 'self'`, donc pas de `data:`) restent des fichiers :
 * le CSS les référence sous /console/fonts/, servies depuis console/fonts/.
 */
export async function buildConsole(options: ConsoleBuildOptions = {}): Promise<ConsoleBuild> {
  const root = options.root ?? DEFAULT_ROOT;
  const development = options.development ?? false;
  const result = await Bun.build({
    entrypoints: [join(root, "index.html")],
    target: "browser",
    minify: !development,
    sourcemap: "none",
    publicPath: ASSET_PREFIX,
    external: [`${FONT_PREFIX}*`],
    define: { "process.env.NODE_ENV": JSON.stringify(development ? "development" : "production") },
  });
  if (!result.success) {
    throw new Error(`Construction de la console impossible : ${result.logs.map(String).join(" | ")}`);
  }

  const files = new Map<string, ConsoleAsset>();
  let index: ConsoleAsset | null = null;
  for (const output of result.outputs) {
    const asset: ConsoleAsset = {
      bytes: new Uint8Array(await output.arrayBuffer()),
      type: output.type,
      hashed: output.hash !== null,
    };
    if (output.kind === "entry-point" && output.path.endsWith(".html")) index = asset;
    else files.set(relativeName(output.path), asset);
  }
  if (index === null) throw new Error("Construction de la console : index.html absent du résultat.");
  for (const [name, asset] of await readFonts(root)) files.set(name, asset);
  return { index, files };
}
