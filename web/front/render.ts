// Prints the Caddyfile for the environment of the website container.
//   bun web/front/render.ts > /tmp/Caddyfile
// Exits 1 with the reason on stderr when the settings are wrong, so the
// container stops before serving anything (see entrypoint.sh).
import { renderCaddyfile } from "./caddyfile";
import { FrontConfigError, readFrontConfig } from "./config";

try {
  process.stdout.write(renderCaddyfile(readFrontConfig(process.env)));
} catch (error) {
  if (error instanceof FrontConfigError) {
    console.error(`website container: ${error.message}`);
    process.exit(1);
  }
  throw error;
}
