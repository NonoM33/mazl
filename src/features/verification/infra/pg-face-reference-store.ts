import type { Sql } from "postgres";
import type { FaceReferenceStore } from "../application/ports";

export class PgFaceReferenceStore implements FaceReferenceStore {
  constructor(private readonly sql: Sql) {}

  async save(userId: number, sealed: Uint8Array, model: string): Promise<void> {
    await this.sql`
      INSERT INTO face_references (user_id, embedding_sealed, model)
      VALUES (${userId}, ${Buffer.from(sealed)}, ${model})
      ON CONFLICT (user_id) DO UPDATE
        SET embedding_sealed = EXCLUDED.embedding_sealed, model = EXCLUDED.model, created_at = NOW()
    `;
  }

  async load(userId: number): Promise<Uint8Array | null> {
    const [row] = await this.sql<{ embedding_sealed: Buffer }[]>`
      SELECT embedding_sealed FROM face_references WHERE user_id = ${userId}
    `;
    return row ? new Uint8Array(row.embedding_sealed) : null;
  }

  async remove(userId: number): Promise<void> {
    await this.sql`DELETE FROM face_references WHERE user_id = ${userId}`;
  }
}
