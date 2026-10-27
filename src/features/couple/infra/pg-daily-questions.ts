import { randomInt } from "node:crypto";
import type { Sql } from "postgres";
import { QUESTION_BANK, questionByKey, questionText, type QuestionLanguage } from "../domain/question-bank";

// The daily question of a couple (section 5): one a day, none repeated until the
// bank is used up, the answer of the other hidden until one has answered.

export interface DailyQuestionView {
  readonly id: number;
  readonly text: string;
  readonly myAnswer: string | null;
  readonly partnerAnswer: string | null;
  // Not a secret: the partner did answer (what makes the member want to).
  readonly partnerAnswered: boolean;
}

export interface HistoryEntry extends DailyQuestionView {
  readonly askedAt: string;
}

interface Row {
  id: number;
  question: string;
  bank_key: string | null;
  user1_answer: string | null;
  user2_answer: string | null;
  asked_day: string;
}

// The couple's calendar day is the Paris one, like everything the couple sees.
const QUESTION_LOCK_CLASS = 7302;

export class PgDailyQuestions {
  constructor(private readonly sql: Sql) {}

  // Today's question, drawn on the first call of the day among the bank questions
  // this couple never had; when all were asked, the one asked longest ago.
  async today(coupleId: number, userId: number, language: QuestionLanguage): Promise<DailyQuestionView> {
    const row = await this.sql.begin(async (transaction) => {
      const tx = transaction as unknown as Sql;
      await tx`SELECT pg_advisory_xact_lock(${QUESTION_LOCK_CLASS}, ${coupleId})`;
      const [existing] = await tx<Row[]>`
        SELECT id, question, bank_key, user1_answer, user2_answer, to_char(asked_at, 'YYYY-MM-DD') AS asked_day
        FROM couple_questions WHERE couple_id = ${coupleId} AND asked_at = (NOW() AT TIME ZONE 'Europe/Paris')::date ORDER BY id LIMIT 1`;
      if (existing !== undefined) return existing;
      const asked = await tx<{ bank_key: string | null; last: string }[]>`
        SELECT bank_key, MAX(asked_at)::text AS last FROM couple_questions WHERE couple_id = ${coupleId} AND bank_key IS NOT NULL GROUP BY bank_key`;
      const lastAsked = new Map(asked.map((entry) => [entry.bank_key, entry.last]));
      const fresh = QUESTION_BANK.filter((question) => !lastAsked.has(question.key));
      const pool = fresh.length > 0 ? fresh : [...QUESTION_BANK].sort((a, b) => (lastAsked.get(a.key) ?? "").localeCompare(lastAsked.get(b.key) ?? "")).slice(0, 10);
      const chosen = pool[randomInt(pool.length)];
      if (chosen === undefined) throw new Error("the question bank is empty");
      const [created] = await tx<Row[]>`
        INSERT INTO couple_questions (couple_id, question, category, bank_key, asked_at)
        VALUES (${coupleId}, ${chosen.text.fr}, ${chosen.category}, ${chosen.key}, (NOW() AT TIME ZONE 'Europe/Paris')::date)
        RETURNING id, question, bank_key, user1_answer, user2_answer, to_char(asked_at, 'YYYY-MM-DD') AS asked_day`;
      if (created === undefined) throw new Error("question not written");
      return created;
    });
    return (await this.viewOf(coupleId, userId, language, [row]))[0] as DailyQuestionView;
  }

  // Records the answer. `first` is true when this member had not answered yet.
  async answer(coupleId: number, questionId: number, userId: number, answer: string): Promise<{ recorded: boolean; first: boolean }> {
    const [couple] = await this.sql<{ user1_id: number; user2_id: number }[]>`SELECT user1_id, user2_id FROM couples WHERE id = ${coupleId}`;
    if (couple === undefined) return { recorded: false, first: false };
    const isFirstMember = couple.user1_id === userId;
    if (!isFirstMember && couple.user2_id !== userId) return { recorded: false, first: false };
    const [before] = await this.sql<{ user1_answer: string | null; user2_answer: string | null }[]>`
      SELECT user1_answer, user2_answer FROM couple_questions WHERE id = ${questionId} AND couple_id = ${coupleId}`;
    if (before === undefined) return { recorded: false, first: false };
    const mine = isFirstMember ? before.user1_answer : before.user2_answer;
    if (isFirstMember) await this.sql`UPDATE couple_questions SET user1_answer = ${answer} WHERE id = ${questionId} AND couple_id = ${coupleId}`;
    else await this.sql`UPDATE couple_questions SET user2_answer = ${answer} WHERE id = ${questionId} AND couple_id = ${coupleId}`;
    return { recorded: true, first: mine === null };
  }

  // The questions this member answered, with both answers; never the others.
  async history(coupleId: number, userId: number, language: QuestionLanguage, limit = 60): Promise<HistoryEntry[]> {
    const rows = await this.sql<Row[]>`
      SELECT id, question, bank_key, user1_answer, user2_answer, to_char(asked_at, 'YYYY-MM-DD') AS asked_day
      FROM couple_questions WHERE couple_id = ${coupleId} ORDER BY asked_at DESC, id DESC LIMIT ${limit}`;
    const views = await this.viewOf(coupleId, userId, language, rows);
    return views.flatMap((view, index) => (view.myAnswer === null ? [] : [{ ...view, askedAt: rows[index]?.asked_day ?? "" }]));
  }

  private async viewOf(coupleId: number, userId: number, language: QuestionLanguage, rows: readonly Row[]): Promise<DailyQuestionView[]> {
    const [couple] = await this.sql<{ user1_id: number }[]>`SELECT user1_id FROM couples WHERE id = ${coupleId}`;
    const isFirstMember = couple?.user1_id === userId;
    return rows.map((row) => {
      const mine = isFirstMember ? row.user1_answer : row.user2_answer;
      const theirs = isFirstMember ? row.user2_answer : row.user1_answer;
      const bank = row.bank_key === null ? undefined : questionByKey(row.bank_key);
      return { id: Number(row.id), text: bank === undefined ? row.question : questionText(bank, language), myAnswer: mine, partnerAnswer: mine === null ? null : theirs, partnerAnswered: theirs !== null };
    });
  }
}
