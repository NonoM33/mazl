import type { Sql } from "postgres";
import { cityKeyOf, type HourCount } from "../domain/best-time";
import type { ActivityStore } from "../application/ports";

export class PgActivityStore implements ActivityStore {
  constructor(private readonly sql: Sql) {}

  async cityOf(userId: number): Promise<{ readonly key: string; readonly label: string } | null> {
    const [row] = await this.sql<{ location: string | null }[]>`SELECT location FROM profiles WHERE user_id = ${userId}`;
    const key = cityKeyOf(row?.location ?? null);
    if (key === null) return null;
    const label = (row?.location ?? "").split(",")[0]?.trim() ?? key;
    return { key, label };
  }

  async record(userId: number, dow: number, hour: number): Promise<void> {
    const city = await this.cityOf(userId);
    if (city === null) return;
    await this.sql`
      INSERT INTO city_activity (city_key, dow, hour, sessions) VALUES (${city.key}, ${dow}, ${hour}, 1)
      ON CONFLICT (city_key, dow, hour) DO UPDATE SET sessions = city_activity.sessions + 1
    `;
  }

  async counts(cityKey: string): Promise<HourCount[]> {
    return await this.sql<HourCount[]>`SELECT dow::int AS dow, hour::int AS hour, sessions FROM city_activity WHERE city_key = ${cityKey}`;
  }
}
