import { useState, type SyntheticEvent } from "react";
import { api } from "../../shared/api/client";
import type { CoupleView } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { useSession } from "../../shared/session";
import { CoupleCard } from "./card";
import type { DailyQuestion, QuestionResponse } from "./couple-api";
import { answersOf } from "./couple-format";
import { Loaded } from "./loaded";
import { useAction } from "./use-action";

function Answer({ label, text, mine = false }: { readonly label: string; readonly text: string; readonly mine?: boolean }) {
  return <div className={mine ? "couple-answer mine" : "couple-answer"}><span className="label-m">{label}</span><p className="body-m">{text}</p></div>;
}

function AnswerForm({ couple, question, onSaved }: { readonly couple: CoupleView; readonly question: DailyQuestion; readonly onSaved: () => Promise<void> }) {
  const [text, setText] = useState("");
  const { busy, run } = useAction();
  const submit = (event: SyntheticEvent) => {
    event.preventDefault();
    void run(() => api.post(`/api/couple/${couple.id}/question/${question.id}/answer`, { answer: text.trim() }), { after: onSaved });
  };
  return (
    <form className="stack gap-12" onSubmit={submit}>
      <div className="field">
        <label htmlFor="couple-answer" className="label-m">Votre réponse</label>
        <textarea id="couple-answer" className="textarea" rows={3} maxLength={2000} value={text} onChange={(event) => setText(event.target.value)} />
      </div>
      <button type="submit" className="btn btn-primary btn-sm" style={{ alignSelf: "flex-start" }} disabled={busy || text.trim() === ""}>Répondre</button>
    </form>
  );
}

function QuestionBody({ couple, question, myId, onSaved }: { readonly couple: CoupleView; readonly question: DailyQuestion; readonly myId: number; readonly onSaved: () => Promise<void> }) {
  const answers = answersOf(question, myId, couple.partner_id);
  const partner = couple.partner_name ?? "Votre partenaire";
  return (
    <>
      <p className="title-l">{question.question}</p>
      {answers.mine === null ? <AnswerForm couple={couple} question={question} onSaved={onSaved} /> : <Answer label="Votre réponse" text={answers.mine} mine />}
      {answers.mine !== null && !answers.both && <p className="body-s">En attente de la réponse de {partner}. Elle s'affichera quand vous aurez tous les deux répondu.</p>}
      {answers.partner !== null && <Answer label={`Réponse de ${partner}`} text={answers.partner} />}
    </>
  );
}

export function DailyQuestionCard({ couple }: { readonly couple: CoupleView }) {
  const session = useSession();
  const resource = useResource(`couple-question:${couple.id}`, (signal) => api.get<QuestionResponse>(`/api/couple/${couple.id}/question`, signal), 60_000);
  const myId = session.state.status === "signed-in" ? session.state.me.user.id : null;
  return (
    <CoupleCard title="Question du jour">
      <Loaded resource={resource} height={120}>
        {({ question }) => (myId === null ? null : <QuestionBody couple={couple} question={question} myId={myId} onSaved={resource.reload} />)}
      </Loaded>
    </CoupleCard>
  );
}
