// Writes docs/api/couple-openapi.json from the routes' operation list.
//   bun scripts/export-couple-openapi.ts
// A test fails when the committed file is out of date, so an API change shows in the diff.
import { buildOpenApi } from "../src/features/couple/presentation/openapi";

const target = new URL("../docs/api/couple-openapi.json", import.meta.url);
await Bun.write(target, `${JSON.stringify(buildOpenApi(), null, 2)}\n`);
console.log(`written ${target.pathname}`);
