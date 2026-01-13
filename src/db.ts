import postgres from "postgres";

const connectionString = process.env.DATABASE_URL || "postgres://postgres:postgres@localhost:5432/mazl";

export const sql = postgres(connectionString);

export async function initDb() {
  await sql`
    CREATE TABLE IF NOT EXISTS waitlist (
      id SERIAL PRIMARY KEY,
      email VARCHAR(255) UNIQUE NOT NULL,
      token VARCHAR(64) NOT NULL,
      status VARCHAR(20) DEFAULT 'pending',
      created_at TIMESTAMP DEFAULT NOW(),
      confirmed_at TIMESTAMP
    )
  `;
  console.log("Database initialized");
}

export async function addToWaitlist(email: string) {
  try {
    const result = await sql`
      INSERT INTO waitlist (email, token, status, confirmed_at)
      VALUES (${email}, ${crypto.randomUUID()}, 'confirmed', NOW())
      RETURNING id, email
    `;
    return { success: true, data: result[0] };
  } catch (error: any) {
    if (error.code === "23505") {
      return { success: false, error: "Tu es déjà inscrit(e) !" };
    }
    throw error;
  }
}

export async function confirmEmail(token: string) {
  const result = await sql`
    UPDATE waitlist
    SET status = 'confirmed', confirmed_at = NOW()
    WHERE token = ${token} AND status = 'pending'
    RETURNING email
  `;
  return result.length > 0 ? result[0] : null;
}

export async function getConfirmedCount() {
  const result = await sql`
    SELECT COUNT(*) as count FROM waitlist WHERE status = 'confirmed'
  `;
  return parseInt(result[0].count);
}

export async function getTotalCount() {
  const result = await sql`
    SELECT COUNT(*) as count FROM waitlist WHERE status = 'confirmed'
  `;
  return parseInt(result[0].count);
}
