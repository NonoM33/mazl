// Creates the test members of the TestFlight phase: fake profiles (provider 'seed',
// e-mail @mazl.seed) that new members find in Discover, and, for the administrator's
// account ONLY, five matches and four conversations. Nobody else gets a match or a message.
//
//   DATABASE_URL=... bun scripts/seed-test-profiles.ts              dry-run: lists, changes nothing
//   DATABASE_URL=... bun scripts/seed-test-profiles.ts --dry-run    same
//   DATABASE_URL=... bun scripts/seed-test-profiles.ts --apply      writes, in ONE transaction
//
// Run it again whenever you like: members are matched on their provider_id (the members
// of the old development seed are taken over, not duplicated) and nothing is written twice.
// Needs a database the API has already started on (it does not create tables). ADMIN_EMAIL
// must hold the same value as on the API server: the accounts that count as administrator
// are the ones isAdminEmail accepts, no address is written here.
// Remove everything with scripts/purge-seed-data.ts. Take a backup before --apply.
import postgres from "postgres";
import { applyTestProfiles, planTestProfiles, type TestProfilesPlan } from "../src/features/fixtures/test-profiles";

const usage = "usage: DATABASE_URL=<url> bun scripts/seed-test-profiles.ts [--dry-run | --apply]";
const flags = process.argv.slice(2);
const unknown = flags.filter((flag) => flag !== "--apply" && flag !== "--dry-run");
if (unknown.length > 0 || (flags.includes("--apply") && flags.includes("--dry-run"))) {
  console.error(`${unknown.length > 0 ? `unknown option: ${unknown.join(" ")}\n` : ""}${usage}`);
  process.exit(2);
}
const apply = flags.includes("--apply");

const databaseUrl = process.env.DATABASE_URL;
if (databaseUrl === undefined || databaseUrl.trim() === "") {
  console.error(`DATABASE_URL is required (no default: this script writes data).\n${usage}`);
  process.exit(2);
}

// Where it points, without the password, so the operator sees the target before anything happens.
function target(url: string): string {
  const parsed = new URL(url);
  return `${parsed.hostname}:${parsed.port || "5432"}${parsed.pathname}`;
}

function report(plan: TestProfilesPlan, verb: { create: string; update: string; retire: string; admin: string }): void {
  const created = plan.members.filter((member) => member.action === "create");
  const updated = plan.members.filter((member) => member.action === "update");
  console.log(`Test members ${verb.create}: ${created.length}`);
  for (const member of created) console.log(`  - ${member.providerId} (${member.displayName})`);
  console.log(`Test members ${verb.update} (already there, taken over): ${updated.length}`);
  for (const member of updated) console.log(`  - ${member.providerId} (${member.displayName})`);
  console.log(`Old development seed members ${verb.retire} (not in the roster, kept but switched off): ${plan.retired.length}`);
  for (const providerId of plan.retired) console.log(`  - ${providerId}`);
  console.log(`Administrator accounts ${verb.admin}: ${plan.admins.length}`);
  for (const admin of plan.admins) {
    console.log(`  #${admin.userId} (looking for: ${admin.seeking}): ${admin.matchesToCreate} match(es), ${admin.conversationsToFill} conversation(s) filled with ${admin.messagesToCreate} message(s)`);
  }
  if (plan.admins.length === 0) console.log("  none: no active account passes isAdminEmail, so nobody gets a match or a message.");
}

const sql = postgres(databaseUrl, { max: 1, onnotice: () => undefined });
let exitCode = 0;
try {
  console.log(`Database: ${target(databaseUrl)}`);
  if (apply) {
    const plan = await applyTestProfiles(sql);
    report(plan, { create: "created", update: "updated", retire: "switched off", admin: "given matches" });
    console.log("Done (one transaction, committed).");
  } else {
    report(await planTestProfiles(sql), { create: "to create", update: "to update", retire: "to switch off", admin: "to give matches" });
    console.log("Dry-run: nothing was changed. Run again with --apply to write.");
  }
} catch (error: unknown) {
  console.error(`Seeding failed, nothing was changed: ${error instanceof Error ? error.message : "unknown error"}`);
  exitCode = 1;
} finally {
  await sql.end({ timeout: 2 });
}
process.exit(exitCode);
