import { useRef, useState, type ChangeEvent, type ClipboardEvent, type KeyboardEvent } from "react";
import { ArrowUp, ImagePlus, Mic, X } from "lucide-react";
import type { ReplyTarget } from "./use-thread";
import { MAX_MESSAGE_LENGTH } from "./thread-model";

// Composer: Enter sends, Shift+Enter breaks the line, 4000 characters at most.
// Voice messages cannot be recorded in a browser (AAC/M4A), so the microphone
// says where to do it.

interface ComposerProps {
  readonly reply: { readonly target: ReplyTarget; readonly who: string } | null;
  readonly busy: boolean;
  readonly onSend: (content: string) => void;
  readonly onPhotos: (files: readonly File[], caption: string) => Promise<boolean>;
  readonly onCancelReply: () => void;
  readonly onTyping: () => void;
  readonly textRef: React.RefObject<HTMLTextAreaElement | null>;
}

const MIC_HINT = "Messages vocaux : depuis l'app";

export function Composer({ reply, busy, onSend, onPhotos, onCancelReply, onTyping, textRef }: ComposerProps) {
  const [text, setText] = useState("");
  const [pending, setPending] = useState<readonly File[]>([]);
  const fileInput = useRef<HTMLInputElement>(null);
  const trimmed = text.trim();
  const canSend = !busy && (pending.length > 0 || trimmed.length > 0);

  const submit = () => {
    if (!canSend) return;
    if (pending.length > 0) {
      void onPhotos(pending, trimmed).then((ok) => { if (ok) { setPending([]); setText(""); } });
      return;
    }
    onSend(trimmed);
    setText("");
  };
  const onKeyDown = (event: KeyboardEvent<HTMLTextAreaElement>) => {
    if (event.key === "Enter" && !event.shiftKey && !event.nativeEvent.isComposing) {
      event.preventDefault();
      submit();
    } else if (event.key === "Escape" && reply) {
      event.stopPropagation();
      onCancelReply();
    }
  };
  const onChange = (event: ChangeEvent<HTMLTextAreaElement>) => {
    setText(event.target.value.slice(0, MAX_MESSAGE_LENGTH));
    if (event.target.value.length > 0) onTyping();
    event.target.style.height = "auto";
    event.target.style.height = `${Math.min(event.target.scrollHeight, 120)}px`;
  };
  const pick = (files: FileList | null) => {
    const images = Array.from(files ?? []).filter((file) => file.type.startsWith("image/")).slice(0, 10);
    if (images.length > 0) setPending(images);
  };
  const onPaste = (event: ClipboardEvent<HTMLTextAreaElement>) => {
    if (event.clipboardData.files.length > 0) { event.preventDefault(); pick(event.clipboardData.files); }
  };

  return (
    <div className="composer">
      {reply && (
        <div className="composer-reply">
          <span className="composer-reply-text"><strong>Réponse à {reply.who}</strong><span>{reply.target.preview}</span></span>
          <button type="button" className="icon-btn" onClick={onCancelReply} aria-label="Annuler la réponse"><X size={18} /></button>
        </div>
      )}
      {pending.length > 0 && (
        <div className="composer-pending">
          <span>{pending.length === 1 ? "1 photo prête à partir" : `${pending.length} photos prêtes à partir`}. Ajoutez une légende si vous le souhaitez.</span>
          <button type="button" className="icon-btn" onClick={() => setPending([])} aria-label="Retirer les photos"><X size={18} /></button>
        </div>
      )}
      <div className="composer-row">
        <input ref={fileInput} type="file" accept="image/jpeg,image/png,image/heic,image/heif" multiple hidden onChange={(event) => { pick(event.target.files); event.target.value = ""; }} />
        <button type="button" className="icon-btn" aria-label="Joindre des photos" onClick={() => fileInput.current?.click()}><ImagePlus size={22} /></button>
        <textarea ref={textRef} className="composer-input" rows={1} value={text} placeholder="Écrivez votre message" aria-label="Votre message" maxLength={MAX_MESSAGE_LENGTH}
          onChange={onChange} onKeyDown={onKeyDown} onPaste={onPaste} />
        {text.length > MAX_MESSAGE_LENGTH - 500 && <span className="composer-count" aria-live="polite">{text.length} / {MAX_MESSAGE_LENGTH}</span>}
        <span title={MIC_HINT}>
          <button type="button" className="icon-btn" disabled aria-label={MIC_HINT}><Mic size={22} /></button>
        </span>
        <button type="button" className="composer-send" disabled={!canSend} aria-label="Envoyer" onClick={submit}><ArrowUp size={22} /></button>
      </div>
    </div>
  );
}
