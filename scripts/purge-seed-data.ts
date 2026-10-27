// Removes the sample data that releases before the v1 left in a real database:
// the twenty fake members (provider 'seed') with their photos, swipes, matches,
// conversations and messages, the fictitious couple catalogue, and the
// "coming soon" test events of the TestFlight phase.
//
//   DATABASE_URL=... bun scripts/purge-seed-data.ts              dry-run: lists, changes nothing
//   DATABASE_URL=... bun scripts/purge-seed-data.ts --dry-run    same
//   DATABASE_URL=... bun scripts/purge-seed-data.ts --apply      deletes, in ONE transaction
//
// Catalogue rows that a real couple saved, passed or booked are kept (and
// listed): the catalogue is shared, deleting them would erase a member's data.
// Take a backup of the database before --apply.
import postgres from "postgres";
import { applySeedPurge, planSeedPurge, type CatalogueEntry, type SeedPurgePlan } from "../src/features/fixtures/seed-purge";

const usage = "usage: DATABASE_URL=<url> bun scripts/purge-seed-data.ts [--dry-run | --apply]";
const flags = process.argv.slice(2);
const unknown = flags.filter((flag) => flag !== "--apply" && flag !== "--dry-run");
if (unknown.length > 0 || (flags.includes("--apply") && flags.includes("--dry-run"))) {
  console.error(`${unknown.length > 0 ? `unknown option: ${unknown.join(" ")}\n` : ""}${usage}`);
  process.exit(2);
}
const apply = flags.includes("--apply");

const databaseUrl = process.env.DATABASE_URL;
if (databaseUrl === undefined || databaseUrl.trim() === "") {
  console.error(`DATABASE_URL is required (no default: this script deletes data).\n${usage}`);
  process.exit(2);
}

// Where it points, without the password, so the operator sees the target before anything happens.
function target(url: string): string {
  const parsed = new URL(url);
  return `${parsed.hostname}:${parsed.port || "5432"}${parsed.pathname}`;
}

function listCatalogue(label: string, entries: readonly CatalogueEntry[], withReferences: boolean): void {
  console.log(`  ${label}: ${entries.length}`);
  for (const entry of entries) console.log(`    - ${entry.title}${withReferences ? ` (used ${entry.references} time(s) by real couples)` : ""}`);
}

function report(plan: SeedPurgePlan, verb: string): void {
  console.log(`Seed accounts ${verb}: ${plan.accounts.length}`);
  for (const account of plan.accounts) {
    console.log(
      `  #${account.id} ${account.email} (${account.displayName ?? "no name"}): ${account.matches} match(es), ${account.conversations} conversation(s), ${account.messages} message(s), ${account.realMembersAffected} real member(s) concerned`,
    );
  }
  console.log("Fictitious couple catalogue");
  listCatalogue(`activities ${verb}`, plan.activitiesToRemove, false);
  listCatalogue("activities KEPT because real couples use them", plan.activitiesKept, true);
  listCatalogue(`events ${verb}`, plan.eventsToRemove, false);
  listCatalogue("events KEPT because real couples use them", plan.eventsKept, true);
  console.log(`Coming soon test events ${verb}: ${plan.testEvents.length}`);
  for (const event of plan.testEvents) console.log(`  - ${event.key} (${event.title})`);
  console.log(`Test couple outings ${verb}: ${plan.testCoupleOutings.length}`);
  for (const outing of plan.testCoupleOutings) console.log(`  - ${outing.key} (${outing.title})`);
}

const sql = postgres(databaseUrl, { max: 1, onnotice: () => undefined });
let exitCode = 0;
try {
  console.log(`Database: ${target(databaseUrl)}`);
  if (apply) {
    const plan = await applySeedPurge(sql);
    report(plan, "deleted");
    console.log("Done (one transaction, committed).");
  } else {
    report(await planSeedPurge(sql), "to delete");
    console.log("Dry-run: nothing was changed. Run again with --apply to delete.");
  }
} catch (error: unknown) {
  console.error(`Purge failed, nothing was changed: ${error instanceof Error ? error.message : "unknown error"}`);
  exitCode = 1;
} finally {
  await sql.end({ timeout: 2 });
}
process.exit(exitCode);
