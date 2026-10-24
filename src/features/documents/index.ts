// Public surface of the documents feature.
export { createDocumentsModule, createMigrationDeps, type DocumentsModule } from "./composition";
export { registerDocumentsRoutes } from "./presentation/documents.routes";
export { registerDocumentsDevRoutes } from "./presentation/documents.dev-routes";
export { ensureDocumentsSchema } from "./infra/schema";
export { startPurgeScheduler } from "./infra/purge-scheduler";
export { findMissingRequired } from "./domain/required-documents";
