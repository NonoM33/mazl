import { sql } from "../../../db";

// CONTRAT.md §1-§2 storage. Idempotent: runs at every boot, after initDb()
// (which creates `messages`, `conversations` and `reports`).
export async function ensureChatSchema(): Promise<void> {
  await sql`ALTER TABLE messages ADD COLUMN IF NOT EXISTS client_id TEXT`;
  await sql`ALTER TABLE messages ADD COLUMN IF NOT EXISTS type TEXT NOT NULL DEFAULT 'text' CHECK (type IN ('text', 'photo', 'voice'))`;
  await sql`ALTER TABLE messages ADD COLUMN IF NOT EXISTS reply_to_id INTEGER REFERENCES messages(id) ON DELETE SET NULL`;
  await sql`ALTER TABLE messages ADD COLUMN IF NOT EXISTS link_preview JSONB`;
  await sql`ALTER TABLE messages ADD COLUMN IF NOT EXISTS unsent_at TIMESTAMPTZ`;
  await sql`ALTER TABLE messages ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ`;
  // One row per (conversation, sender, client_id); NULL client ids never collide.
  await sql`CREATE UNIQUE INDEX IF NOT EXISTS idx_messages_client_id ON messages (conversation_id, sender_id, client_id)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_messages_conversation_cursor ON messages (conversation_id, id DESC)`;
  // Existing rows became type 'text' through the column default; read state moves to read_at.
  await sql`UPDATE messages SET read_at = created_at WHERE is_read = true AND read_at IS NULL`;

  await sql`
    CREATE TABLE IF NOT EXISTS message_media (
      id SERIAL PRIMARY KEY,
      conversation_id INTEGER NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
      uploader_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      kind TEXT NOT NULL CHECK (kind IN ('photo', 'voice')),
      storage_key TEXT NOT NULL,
      width INTEGER,
      height INTEGER,
      duration_ms INTEGER,
      waveform JSONB,
      message_id INTEGER REFERENCES messages(id) ON DELETE CASCADE,
      -- 'preview' = the downloaded og:image of a link preview, never an attachment
      role TEXT NOT NULL DEFAULT 'attachment' CHECK (role IN ('attachment', 'preview')),
      position INTEGER NOT NULL DEFAULT 0,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `;
  await sql`CREATE INDEX IF NOT EXISTS idx_message_media_message ON message_media (message_id)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_message_media_orphans ON message_media (created_at) WHERE message_id IS NULL`;
  await sql`CREATE INDEX IF NOT EXISTS idx_message_media_uploader_pending ON message_media (uploader_id) WHERE message_id IS NULL`;

  await sql`
    CREATE TABLE IF NOT EXISTS message_reactions (
      message_id INTEGER NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      emoji TEXT NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      PRIMARY KEY (message_id, user_id)
    )
  `;

  // data NULL = the page was fetched and gave nothing usable (cached too).
  await sql`
    CREATE TABLE IF NOT EXISTS link_preview_cache (
      url TEXT PRIMARY KEY,
      data JSONB,
      fetched_at TIMESTAMPTZ NOT NULL
    )
  `;

  // A report may point at the message it is about (moderation reads it back).
  await sql`ALTER TABLE reports ADD COLUMN IF NOT EXISTS message_id INTEGER REFERENCES messages(id) ON DELETE SET NULL`;
  await sql`CREATE UNIQUE INDEX IF NOT EXISTS idx_reports_reporter_message ON reports (reporter_id, message_id) WHERE message_id IS NOT NULL`;
}
