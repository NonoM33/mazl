// Writes docs/api/storefront-openapi.json from the routes' operation list.
//   bun scripts/export-storefront-openapi.ts
// A test fails when the committed file is out of date, so an API change shows in the diff.
import { buildOpenApi } from "../src/features/storefront/presentation/openapi";

const target = new URL("../docs/api/storefront-openapi.json", import.meta.url);
await Bun.write(target, `${JSON.stringify(buildOpenApi(), null, 2)}\n`);
console.log(`written ${target.pathname}`);
