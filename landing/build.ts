// Builds the showcase into landing/dist, served by the API process at "/" (index.html)
// and under /l/ (everything else). Hashed file names, minified, no source maps in
// production builds, fonts and photos copied as plain files, gzip copies of code.
import { cp, rm } from "node:fs/promises";
import { APP_STORE_URL } from "./config";

const outdir = new URL("./dist", import.meta.url).pathname;
const production = process.env.NODE_ENV !== "development";

await rm(outdir, { recursive: true, force: true });
const result = await Bun.build({
  entrypoints: [new URL("./index.html", import.meta.url).pathname],
  outdir,
  publicPath: "/l/",
  // Fonts and photos are copied as plain files: the CSS bundler would inline the photos.
  external: ["/l/fonts/*", "/l/photos/*"],
  minify: production,
  sourcemap: production ? "none" : "linked",
  naming: { entry: "[name].[ext]", chunk: "[name]-[hash].[ext]", asset: "[name]-[hash].[ext]" },
  define: { "process.env.NODE_ENV": JSON.stringify(production ? "production" : "development") },
});

if (!result.success) {
  for (const log of result.logs) console.error(log);
  process.exit(1);
}
await cp(new URL("./assets/fonts", import.meta.url).pathname, `${outdir}/fonts`, { recursive: true });
await cp(new URL("./assets/photos", import.meta.url).pathname, `${outdir}/photos`, { recursive: true, filter: (source) => !source.endsWith(".md") });
const indexPath = `${outdir}/index.html`;
await Bun.write(indexPath, (await Bun.file(indexPath).text()).replaceAll("{{APP_STORE_URL}}", APP_STORE_URL));
for (const output of result.outputs) {
  if (/\.(js|css)$/.test(output.path)) await Bun.write(`${output.path}.gz`, Bun.gzipSync(await Bun.file(output.path).bytes(), { level: 9 }));
}
for (const output of result.outputs) {
  const gz = /\.(js|css)$/.test(output.path) ? `  (${(Bun.file(`${output.path}.gz`).size / 1024).toFixed(1)} kB gzip)` : "";
  console.log(`${output.path.replace(outdir, "landing/dist")}  ${(output.size / 1024).toFixed(1)} kB${gz}`);
}
