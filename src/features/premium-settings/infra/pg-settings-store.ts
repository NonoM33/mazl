import type { Sql } from "postgres";
import type { SettingsStore } from "../application/ports";
import { DEFAULT_SETTINGS, type Passport, type StoredSettings } from "../domain/settings";

interface Row {
  readonly passport_city: string | null;
  readonly passport_latitude: number | null;
  readonly passport_longitude: number | null;
  readonly incognito: boolean;
  readonly send_read_receipts: boolean;
}

export class PgSettingsStore implements SettingsStore {
  constructor(private readonly sql: Sql) {}

  async read(userId: number): Promise<StoredSettings> {
    const [row] = await this.sql<Row[]>`
      SELECT passport_city, passport_latitude, passport_longitude, incognito, send_read_receipts
      FROM member_premium_settings WHERE user_id = ${userId}
    `;
    if (row === undefined) return DEFAULT_SETTINGS;
    const located = row.passport_city !== null && row.passport_latitude !== null && row.passport_longitude !== null;
    return {
      passport: located ? { city: row.passport_city ?? "", latitude: row.passport_latitude ?? 0, longitude: row.passport_longitude ?? 0 } : null,
      incognito: row.incognito,
      sendReadReceipts: row.send_read_receipts,
    };
  }

  async setPassport(userId: number, passport: Passport | null): Promise<void> {
    await this.sql`
      INSERT INTO member_premium_settings (user_id, passport_city, passport_latitude, passport_longitude)
      VALUES (${userId}, ${passport?.city ?? null}, ${passport?.latitude ?? null}, ${passport?.longitude ?? null})
      ON CONFLICT (user_id) DO UPDATE SET
        passport_city = EXCLUDED.passport_city, passport_latitude = EXCLUDED.passport_latitude,
        passport_longitude = EXCLUDED.passport_longitude, updated_at = now()
    `;
  }

  async setIncognito(userId: number, enabled: boolean): Promise<void> {
    await this.sql`
      INSERT INTO member_premium_settings (user_id, incognito) VALUES (${userId}, ${enabled})
      ON CONFLICT (user_id) DO UPDATE SET incognito = EXCLUDED.incognito, updated_at = now()
    `;
  }

  async setReadReceipts(userId: number, enabled: boolean): Promise<void> {
    await this.sql`
      INSERT INTO member_premium_settings (user_id, send_read_receipts) VALUES (${userId}, ${enabled})
      ON CONFLICT (user_id) DO UPDATE SET send_read_receipts = EXCLUDED.send_read_receipts, updated_at = now()
    `;
  }
}
