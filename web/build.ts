// Builds the web client into web/dist, served under /app by the API process
// (docs/web/adr/W01-hebergement.md). Hashed file names, minified, no source
// maps in production builds.
import { cp, rm } from "node:fs/promises";

const outdir = new URL("./dist", import.meta.url).pathname;
const production = process.env.NODE_ENV !== "development";

await rm(outdir, { recursive: true, force: true });
const result = await Bun.build({
  entrypoints: [new URL("./index.html", import.meta.url).pathname],
  outdir,
  publicPath: "/app/",
  external: ["/app/fonts/*"],
  minify: production,
  sourcemap: production ? "none" : "linked",
  naming: { entry: "[name].[ext]", chunk: "[name]-[hash].[ext]", asset: "[name]-[hash].[ext]" },
  define: { "process.env.NODE_ENV": JSON.stringify(production ? "production" : "development") },
});

if (!result.success) {
  for (const log of result.logs) console.error(log);
  process.exit(1);
}
// Fonts are plain files (cached a year), not inlined into the stylesheet.
await cp(new URL("./assets/fonts", import.meta.url).pathname, `${outdir}/fonts`, { recursive: true });
for (const output of result.outputs) console.log(`${output.path.replace(outdir, "web/dist")}  ${(output.size / 1024).toFixed(1)} kB`);
