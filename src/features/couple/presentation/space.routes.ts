import type { Context, Hono, MiddlewareHandler } from "hono";
import { z } from "zod";
import type { AppVariables } from "../../../shared/http/middleware";
import { ConciergeNotFoundError, ConciergeRuleError, type ConciergeService } from "../application/concierge-service";
import type { CoupleContext, PremiumReader } from "../application/space-ports";
import { CheckinAlreadyDoneError, type SpaceService } from "../application/space-service";
import { newRitualFrom } from "../domain/rituals";
import { languageFromAcceptLanguage } from "../domain/question-bank";
import type { RequestKind } from "../domain/concierge";
import type { PgDailyQuestions } from "../infra/pg-daily-questions";
import type { PgRituals } from "../infra/pg-rituals";
import { conciergeListItem, memberMessageDto, memberRequestDto, ritualDto } from "./dto";
import { fail, ok, readBody, routeId } from "./http";
import { honoPath, OPERATIONS, type OperationSpec } from "./operations";
import { checkinBody, chooseBody, conciergeMessageBody, createConciergeBody, createRitualBody, moodBody, outingsQuery, updateRitualBody } from "./schemas";

type Ctx = Context<{ Variables: AppVariables }>;
type Handler = (c: Ctx, couple: CoupleContext) => Promise<Response>;

export interface SpaceRouteDeps {
  readonly authenticate: MiddlewareHandler<{ Variables: AppVariables }>;
  readonly loadCouple: (userId: number) => Promise<CoupleContext | null>;
  readonly space: SpaceService;
  readonly rituals: PgRituals;
  readonly questions: PgDailyQuestions;
  readonly concierge: ConciergeService;
  readonly premium: PremiumReader;
  readonly questionPush: { partnerAnswered(partnerId: number): Promise<void> };
  readonly now: () => Date;
}

const answerBody = z.object({ answer: z.string().trim().min(1).max(2000) }).passthrough();

// The legacy question routes name the couple in the path: only your own.
function ownCouple(c: Ctx, couple: CoupleContext): boolean {
  return routeId(c.req.param("coupleId")) === couple.coupleId;
}

export function registerSpaceRoutes(app: Hono<{ Variables: AppVariables }>, deps: SpaceRouteDeps): void {
  const language = (c: Ctx) => languageFromAcceptLanguage(c.req.header("accept-language"));

  function conciergeFailure(c: Ctx, error: unknown): Response {
    if (error instanceof ConciergeNotFoundError) return fail(c, 404, "concierge_not_found");
    if (error instanceof ConciergeRuleError) return fail(c, error.code === "concierge_rate_limited" ? 429 : 409, error.code);
    throw error;
  }

  const detail = (c: Ctx, couple: CoupleContext, view: { request: Parameters<typeof memberRequestDto>[0]; messages: Parameters<typeof memberMessageDto>[0][] }, status: 200 | 201 = 200): Response =>
    ok(c, { request: memberRequestDto(view.request), messages: view.messages.map((m) => memberMessageDto(m, couple.userId)) }, status);

  const handlers: Record<string, Handler> = {
    coupleToday: async (c, couple) => ok(c, await deps.space.today(couple, language(c), deps.now())),

    coupleMood: async (c, couple) => {
      const body = await readBody(c, moodBody);
      if (!body.ok) return fail(c, 400, "invalid_body", body.message);
      return ok(c, await deps.space.setMood(couple, body.data.mood, deps.now()));
    },

    coupleRitualsList: async (c, couple) => ok(c, { rituals: (await deps.rituals.list(couple.coupleId)).map(ritualDto) }),

    coupleRitualsCreate: async (c, couple) => {
      const body = await readBody(c, createRitualBody);
      if (!body.ok) return fail(c, 400, "invalid_body", body.message);
      return ok(c, { ritual: ritualDto(await deps.rituals.create(couple.coupleId, newRitualFrom(body.data))) }, 201);
    },

    coupleRitualsUpdate: async (c, couple) => {
      const id = routeId(c.req.param("id"));
      if (id === null) return fail(c, 404, "ritual_not_found");
      const body = await readBody(c, updateRitualBody);
      if (!body.ok) return fail(c, 400, "invalid_body", body.message);
      const { remind_minutes: remindMinutes, ...rest } = body.data;
      const updated = await deps.rituals.update(couple.coupleId, id, { ...rest, ...(remindMinutes === undefined ? {} : { remindMinutes }) });
      return updated === null ? fail(c, 404, "ritual_not_found") : ok(c, { ritual: ritualDto(updated) });
    },

    coupleRitualsDelete: async (c, couple) => {
      const id = routeId(c.req.param("id"));
      if (id === null || !(await deps.rituals.remove(couple.coupleId, id))) return fail(c, 404, "ritual_not_found");
      return ok(c, { deleted: true });
    },

    coupleOutings: async (c, couple) => {
      const raw = c.req.query("filter");
      const filter = raw === undefined || raw === "" ? undefined : outingsQuery.safeParse(raw);
      if (filter !== undefined && !filter.success) return fail(c, 400, "invalid_query", "filter: valeur inconnue");
      return ok(c, await deps.space.outings(couple, filter?.data, deps.now()));
    },

    coupleCheckinGet: async (c, couple) => ok(c, await deps.space.checkin(couple, deps.now())),

    coupleCheckinPost: async (c, couple) => {
      const body = await readBody(c, checkinBody);
      if (!body.ok) return fail(c, 400, "invalid_body", body.message);
      try {
        return ok(c, await deps.space.submitCheckin(couple, body.data, deps.now()));
      } catch (error: unknown) {
        if (error instanceof CheckinAlreadyDoneError) return fail(c, 409, "checkin_already_done");
        throw error;
      }
    },

    // `question` repeats `data` for the clients written before the envelope.
    coupleQuestionGet: async (c, couple) => {
      if (!ownCouple(c, couple)) return fail(c, 403, "Forbidden");
      const { id, text, myAnswer, partnerAnswer } = await deps.questions.today(couple.coupleId, couple.userId, language(c));
      const question = { id, text, myAnswer, partnerAnswer };
      return ok(c, question, 200, { question });
    },

    coupleQuestionAnswer: async (c, couple) => {
      if (!ownCouple(c, couple)) return fail(c, 403, "Forbidden");
      const questionId = routeId(c.req.param("questionId"));
      if (questionId === null) return fail(c, 404, "Question not found");
      const body = await readBody(c, answerBody);
      if (!body.ok) return fail(c, 400, "invalid_body", body.message);
      const result = await deps.questions.answer(couple.coupleId, questionId, couple.userId, body.data.answer);
      if (!result.recorded) return fail(c, 404, "Question not found");
      if (result.first) await deps.questionPush.partnerAnswered(couple.partnerId);
      return ok(c, { recorded: true });
    },

    coupleQuestionHistory: async (c, couple) => {
      if (!ownCouple(c, couple)) return fail(c, 403, "Forbidden");
      const questions = await deps.questions.history(couple.coupleId, couple.userId, language(c));
      const shaped = questions.map(({ id, text, myAnswer, partnerAnswer, askedAt }) => ({ id, text, myAnswer, partnerAnswer, askedAt }));
      return ok(c, { questions: shaped }, 200, { questions: shaped });
    },

    conciergeList: async (c, couple) => ok(c, { requests: (await deps.concierge.list(couple.coupleId)).map(conciergeListItem) }),

    conciergeCreate: async (c, couple) => {
      const body = await readBody(c, createConciergeBody);
      if (!body.ok) return fail(c, 400, "invalid_body", body.message);
      const { text, wantedAt, city, kind, kosher, budget } = body.data;
      try {
        const view = await deps.concierge.create(
          couple.coupleId,
          couple.userId,
          { text, wantedAt: wantedAt ?? null, city: city ?? null, kind: (kind ?? "other") as RequestKind, constraints: { ...(kosher === undefined ? {} : { kosher }), ...(budget === undefined ? {} : { budget }) } },
          language(c),
        );
        return detail(c, couple, view, 201);
      } catch (error: unknown) {
        return conciergeFailure(c, error);
      }
    },

    conciergeGet: async (c, couple) => {
      const id = routeId(c.req.param("id"));
      if (id === null) return fail(c, 404, "concierge_not_found");
      try {
        return detail(c, couple, await deps.concierge.get(couple.coupleId, id));
      } catch (error: unknown) {
        return conciergeFailure(c, error);
      }
    },

    conciergeMessage: async (c, couple) => {
      const id = routeId(c.req.param("id"));
      if (id === null) return fail(c, 404, "concierge_not_found");
      const body = await readBody(c, conciergeMessageBody);
      if (!body.ok) return fail(c, 400, "invalid_body", body.message);
      try {
        return detail(c, couple, await deps.concierge.sendMessage(couple.coupleId, couple.userId, id, body.data.text, language(c)), 201);
      } catch (error: unknown) {
        return conciergeFailure(c, error);
      }
    },

    conciergeChoose: async (c, couple) => {
      const id = routeId(c.req.param("id"));
      if (id === null) return fail(c, 404, "concierge_not_found");
      const body = await readBody(c, chooseBody);
      if (!body.ok) return fail(c, 400, "invalid_body", body.message);
      try {
        return detail(c, couple, await deps.concierge.choose(couple.coupleId, id, body.data.index));
      } catch (error: unknown) {
        return conciergeFailure(c, error);
      }
    },

    conciergeCancel: async (c, couple) => {
      const id = routeId(c.req.param("id"));
      if (id === null) return fail(c, 404, "concierge_not_found");
      try {
        return detail(c, couple, await deps.concierge.cancel(couple.coupleId, id));
      } catch (error: unknown) {
        return conciergeFailure(c, error);
      }
    },
  };

  const guarded = (operation: OperationSpec, handler: Handler) => async (c: Ctx): Promise<Response> => {
    try {
      const couple = await deps.loadCouple(c.get("userId"));
      if (couple === null) return fail(c, 400, "Not in a couple");
      if (operation.premium && !(await deps.premium.of(couple.userId, couple.coupleId, deps.now())).active) {
        return fail(c, 402, "couple_subscription_required");
      }
      return await handler(c, couple);
    } catch (error: unknown) {
      console.error(`Couple space ${operation.operationId} failed:`, error instanceof Error ? error.name : "unknown");
      return fail(c, 500, "internal_error");
    }
  };

  for (const operation of OPERATIONS.filter((candidate) => candidate.audience === "member")) {
    const handler = handlers[operation.operationId];
    if (handler === undefined) throw new Error(`no handler for ${operation.operationId}`);
    const route = guarded(operation, handler);
    const path = honoPath(operation.path);
    if (operation.method === "get") app.get(path, deps.authenticate, route);
    else if (operation.method === "post") app.post(path, deps.authenticate, route);
    else if (operation.method === "patch") app.patch(path, deps.authenticate, route);
    else app.delete(path, deps.authenticate, route);
  }
}

