import type { Sql } from "postgres";
import type { ApnsEnvironment, PushDevice, PushDeviceStore } from "../application/ports";

// The APNs tokens of each member. A token belongs to one member at a time (the
// phone changed hands, or another account signed in on it). The oldest devices
// beyond MAX_DEVICES are dropped: a member does not own ten phones, a loop does.
const MAX_DEVICES = 10;

export async function ensurePushSchema(sql: Sql): Promise<void> {
  await sql`
    CREATE TABLE IF NOT EXISTS push_devices (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      token TEXT NOT NULL UNIQUE,
      environment TEXT NOT NULL CHECK (environment IN ('production', 'sandbox')),
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `;
  await sql`CREATE INDEX IF NOT EXISTS idx_push_devices_user ON push_devices (user_id)`;
}

export class PgPushDevices implements PushDeviceStore {
  constructor(private readonly sql: Sql) {}

  async register(userId: number, token: string, environment: ApnsEnvironment): Promise<void> {
    await this.sql.begin(async (transaction) => {
      // postgres.js types TransactionSql without its call signature; it is one.
      const tx = transaction as unknown as Sql;
      await tx`
        INSERT INTO push_devices (user_id, token, environment) VALUES (${userId}, ${token}, ${environment})
        ON CONFLICT (token) DO UPDATE SET user_id = EXCLUDED.user_id, environment = EXCLUDED.environment, last_seen_at = now()`;
      await tx`
        DELETE FROM push_devices WHERE user_id = ${userId} AND id NOT IN (
          SELECT id FROM push_devices WHERE user_id = ${userId} ORDER BY last_seen_at DESC, id DESC LIMIT ${MAX_DEVICES}
        )`;
    });
  }

  async unregister(userId: number, token: string): Promise<void> {
    await this.sql`DELETE FROM push_devices WHERE user_id = ${userId} AND token = ${token}`;
  }

  async devicesOf(userId: number): Promise<PushDevice[]> {
    return this.sql<PushDevice[]>`SELECT id, token, environment FROM push_devices WHERE user_id = ${userId} ORDER BY id`;
  }

  async forget(deviceIds: readonly number[]): Promise<void> {
    if (deviceIds.length === 0) return;
    await this.sql`DELETE FROM push_devices WHERE id IN ${this.sql([...deviceIds])}`;
  }
}
