// Writes docs/api/premium-openapi.json from the operation list of the revenue features.
//   bun scripts/export-premium-openapi.ts
// A test fails when the committed file is out of date, so an API change shows in the diff.
import { buildOpenApi } from "../src/features/premium-docs/openapi";

const target = new URL("../docs/api/premium-openapi.json", import.meta.url);
await Bun.write(target, `${JSON.stringify(buildOpenApi(), null, 2)}\n`);
console.log(`written ${target.pathname}`);
