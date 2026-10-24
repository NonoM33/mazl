// The e2e server: started by tests/e2e/run.ts on its own port and database.
export const E2E_PORT = Number(process.env.E2E_PORT ?? 3480);
export const BASE_URL = process.env.TEST_API_URL ?? `http://localhost:${E2E_PORT}`;
export const DATABASE_URL = process.env.TEST_DATABASE_URL ?? "postgres://postgres:postgres@127.0.0.1:55471/mazl_web_e2e";
export const CAPTURES_DIR = new URL("../../../docs/web/captures/", import.meta.url).pathname;
