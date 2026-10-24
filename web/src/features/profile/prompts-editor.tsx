import { useState } from "react";
import { Eyebrow } from "../../shared/ui/eyebrow";
import type { OwnPrompt } from "../../shared/api/types";
import { ANSWER_MAX, answerProblem, groupCatalog, MAX_PROMPTS } from "./prompt-rules";
import type { usePrompts } from "./use-prompts";

type Prompts = ReturnType<typeof usePrompts>;

function Counter({ value }: { readonly value: string }) {
  const length = value.trim().length;
  return <span className="field-hint tabular" aria-live="off">{length}/{ANSWER_MAX}</span>;
}

function ExistingPrompt({ prompt, api }: { readonly prompt: OwnPrompt; readonly api: Prompts }) {
  const [answer, setAnswer] = useState(prompt.answer);
  const problem = answerProblem(answer);
  const changed = answer.trim() !== prompt.answer;
  return (
    <li className="card-surface prompt-edit">
      <div className="field">
        <label htmlFor={`prompt-${prompt.id}`} className="title-s">{prompt.prompt_text}</label>
        <textarea id={`prompt-${prompt.id}`} className="textarea" rows={3} value={answer} aria-invalid={changed && problem !== null} onChange={(event) => setAnswer(event.target.value)} />
        <div className="spread"><span className={changed && problem ? "field-error" : "field-hint"}>{changed && problem ? problem : " "}</span><Counter value={answer} /></div>
      </div>
      <div className="inline gap-8" style={{ justifyContent: "flex-end" }}>
        <button type="button" className="btn btn-ghost" onClick={() => void api.remove(prompt.id)} aria-label={`Supprimer la réponse « ${prompt.prompt_text} »`}>Supprimer</button>
        <button type="button" className="btn btn-outline btn-sm" disabled={!changed || problem !== null} onClick={() => void api.update(prompt.id, answer)} aria-label={`Enregistrer la réponse « ${prompt.prompt_text} »`}>Enregistrer</button>
      </div>
    </li>
  );
}

function NewPrompt({ api, onDone }: { readonly api: Prompts; readonly onDone: () => void }) {
  const groups = groupCatalog(api.catalog, api.prompts.map((prompt) => prompt.prompt_id));
  const [promptId, setPromptId] = useState(groups[0]?.prompts[0]?.id ?? "");
  const [answer, setAnswer] = useState("");
  const problem = answerProblem(answer);
  const submit = async () => { if (await api.add(promptId, answer)) onDone(); };
  return (
    <li className="card-surface prompt-edit">
      <div className="field">
        <label htmlFor="new-prompt-question">Question</label>
        <select id="new-prompt-question" className="select" value={promptId} onChange={(event) => setPromptId(event.target.value)}>
          {groups.map((group) => (
            <optgroup key={group.category} label={group.label}>
              {group.prompts.map((prompt) => <option key={prompt.id} value={prompt.id}>{prompt.text}</option>)}
            </optgroup>
          ))}
        </select>
      </div>
      <div className="field">
        <label htmlFor="new-prompt-answer">Votre réponse</label>
        <textarea id="new-prompt-answer" className="textarea" rows={3} value={answer} aria-invalid={answer.length > 0 && problem !== null} onChange={(event) => setAnswer(event.target.value)} />
        <div className="spread"><span className={answer.length > 0 && problem ? "field-error" : "field-hint"}>{answer.length > 0 && problem ? problem : `De 10 à ${ANSWER_MAX} caractères.`}</span><Counter value={answer} /></div>
      </div>
      <div className="inline gap-8" style={{ justifyContent: "flex-end" }}>
        <button type="button" className="btn btn-ghost" onClick={onDone}>Annuler</button>
        <button type="button" className="btn btn-accent btn-sm" disabled={problem !== null || promptId === ""} onClick={() => void submit()}>Ajouter cette réponse</button>
      </div>
    </li>
  );
}

export function PromptsEditor({ prompts: api }: { readonly prompts: Prompts }) {
  const [adding, setAdding] = useState(false);
  const canAdd = api.prompts.length < MAX_PROMPTS && !adding;
  return (
    <section className="stack gap-12" aria-label="Prompts">
      <div className="spread">
        <div className="stack gap-4">
          <Eyebrow as="h2">Prompts · {api.prompts.length}/{MAX_PROMPTS}</Eyebrow>
          <p className="body-s">Trois réponses au plus, pour laisser entrevoir qui vous êtes.</p>
        </div>
        <button type="button" className="btn btn-outline btn-sm" disabled={!canAdd} onClick={() => setAdding(true)}>Ajouter un prompt</button>
      </div>
      {api.message && <p className="banner banner-error" role="alert">{api.message}</p>}
      <ul className="list stack gap-12">
        {api.prompts.map((prompt) => <ExistingPrompt key={`${prompt.id}-${prompt.answer}`} prompt={prompt} api={api} />)}
        {adding && <NewPrompt api={api} onDone={() => setAdding(false)} />}
      </ul>
    </section>
  );
}
