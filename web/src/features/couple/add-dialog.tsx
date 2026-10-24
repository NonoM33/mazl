import { useState, type SyntheticEvent } from "react";
import { Dialog } from "../../shared/ui/dialog";
import { useAction } from "./use-action";

export interface AddValues { readonly title: string; readonly text: string; readonly date: string }

interface AddDialogProps {
  readonly heading: string;
  readonly titleLabel: string;
  readonly textLabel?: string;
  readonly dateLabel?: string;
  readonly submitLabel: string;
  readonly onSubmit: (values: AddValues) => Promise<unknown>;
  readonly onDone: () => Promise<void>;
  readonly onClose: () => void;
}

// A small form in a dialog: a title, optionally a text and a date. The dialog
// closes once the server accepted it.
export function AddDialog({ heading, titleLabel, textLabel, dateLabel, submitLabel, onSubmit, onDone, onClose }: AddDialogProps) {
  const [values, setValues] = useState<AddValues>({ title: "", text: "", date: "" });
  const { busy, run } = useAction();
  const complete = values.title.trim() !== "" && (dateLabel === undefined || values.date !== "");
  const submit = (event: SyntheticEvent) => {
    event.preventDefault();
    void run(() => onSubmit({ ...values, title: values.title.trim(), text: values.text.trim() }), { after: onDone }).then((ok) => { if (ok) onClose(); });
  };
  return (
    <Dialog title={heading} onClose={onClose}>
      <form className="date-field" onSubmit={submit}>
        <div className="field"><label htmlFor="add-title" className="label-m">{titleLabel}</label><input id="add-title" className="input" maxLength={255} value={values.title} onChange={(event) => setValues({ ...values, title: event.target.value })} /></div>
        {dateLabel && <div className="field"><label htmlFor="add-date" className="label-m">{dateLabel}</label><input id="add-date" type="date" className="input" value={values.date} onChange={(event) => setValues({ ...values, date: event.target.value })} /></div>}
        {textLabel && <div className="field"><label htmlFor="add-text" className="label-m">{textLabel}</label><textarea id="add-text" className="textarea" rows={3} maxLength={2000} value={values.text} onChange={(event) => setValues({ ...values, text: event.target.value })} /></div>}
        <button type="submit" className="btn btn-primary" disabled={busy || !complete}>{submitLabel}</button>
      </form>
    </Dialog>
  );
}
