import { useEffect, useRef, useState } from "react";
import { Eye, Pause, Play } from "lucide-react";
import type { MessageView } from "../../shared/api/types";
import { PhotoViewer } from "../../shared/ui/photo-viewer";
import { Photo } from "../../shared/ui/photo";

// Media inside a bubble: photos (received ones stay blurred until the first
// tap, docs/chat/CONTRAT.md §4), voice playback, link preview card.

export function PhotoGrid({ media, mine, name, seed, onExpired }: { readonly media: MessageView["media"]; readonly mine: boolean; readonly name: string; readonly seed: number; readonly onExpired: () => void }) {
  const [revealed, setRevealed] = useState(mine);
  const [viewer, setViewer] = useState<number | null>(null);
  const shown = media.slice(0, 4);
  const extra = media.length - shown.length;
  const urls = media.map((item) => item.url);
  const single = shown.length === 1;
  const onTap = (index: number) => { if (revealed) setViewer(index); else setRevealed(true); };
  return (
    <div className="chat-photos" data-single={single} data-blurred={!revealed}>
      {shown.map((item, index) => (
        <button key={item.id} type="button" className="chat-photo" onClick={() => onTap(index)} aria-label={revealed ? `Agrandir la photo ${index + 1}` : "Afficher la photo"}>
          <Photo src={item.url} alt={revealed ? `Photo ${index + 1}` : ""} seed={seed + index} radius={0} onExpired={onExpired}
            style={single ? { width: 220, aspectRatio: item.width && item.height ? `${item.width} / ${item.height}` : "3 / 4", maxHeight: 300, minHeight: 160 } : { width: "100%", aspectRatio: "1 / 1" }} />
          {!revealed && <span className="chat-photo-veil"><Eye size={16} aria-hidden="true" />Voir la photo</span>}
          {revealed && extra > 0 && index === shown.length - 1 && <span className="chat-photo-more">+{extra}</span>}
        </button>
      ))}
      {viewer !== null && <PhotoViewer photos={urls} start={viewer} name={name} seed={seed} onClose={() => setViewer(null)} />}
    </div>
  );
}

const SPEEDS = [1, 1.5, 2] as const;
const BARS = 32;

export function bars(waveform: readonly number[] | null): number[] {
  const source = waveform && waveform.length > 0 ? waveform : Array.from({ length: BARS }, () => 30);
  return Array.from({ length: BARS }, (_, index) => source[Math.floor((index * source.length) / BARS)] ?? 0);
}

export const clock = (seconds: number): string => `${Math.floor(seconds / 60)}:${String(Math.floor(seconds % 60)).padStart(2, "0")}`;
const speedLabel = (speed: number): string => `${String(speed).replace(".", ",")}×`;

export function VoicePlayer({ voice }: { readonly voice: NonNullable<MessageView["voice"]> }) {
  const audio = useRef<HTMLAudioElement>(null);
  const [playing, setPlaying] = useState(false);
  const [progress, setProgress] = useState(0);
  const [speed, setSpeed] = useState<(typeof SPEEDS)[number]>(1);
  const total = (voice.duration_ms ?? 0) / 1000;
  useEffect(() => { if (audio.current) audio.current.playbackRate = speed; }, [speed]);
  const toggle = () => {
    const element = audio.current;
    if (!element) return;
    if (element.paused) element.play().catch(() => setPlaying(false));
    else element.pause();
  };
  const heights = bars(voice.waveform);
  return (
    <div className="chat-voice">
      <audio ref={audio} src={voice.url} preload="none" onPlay={() => setPlaying(true)} onPause={() => setPlaying(false)} onEnded={() => { setPlaying(false); setProgress(0); }}
        onTimeUpdate={(event) => { const duration = event.currentTarget.duration; setProgress(Number.isFinite(duration) && duration > 0 ? event.currentTarget.currentTime / duration : 0); }} />
      <button type="button" className="chat-voice-play" onClick={toggle} aria-label={playing ? "Mettre en pause" : "Écouter le message vocal"}>
        {playing ? <Pause size={16} aria-hidden="true" /> : <Play size={16} aria-hidden="true" />}
      </button>
      <div className="chat-voice-wave" aria-hidden="true">
        {heights.map((value, index) => <span key={index} data-played={index / BARS < progress} style={{ height: 4 + (Math.min(100, value) / 100) * 20 }} />)}
      </div>
      <span className="chat-voice-time">{clock(total)}</span>
      <button type="button" className="chat-voice-speed" aria-label={`Vitesse de lecture ${speedLabel(speed)}`} onClick={() => setSpeed((current) => SPEEDS[(SPEEDS.indexOf(current) + 1) % SPEEDS.length] ?? 1)}>{speedLabel(speed)}</button>
    </div>
  );
}

function safeHref(url: string): string | null {
  try {
    const parsed = new URL(url);
    return parsed.protocol === "https:" || parsed.protocol === "http:" ? parsed.href : null;
  } catch {
    return null;
  }
}

export function LinkPreviewCard({ preview, seed }: { readonly preview: NonNullable<MessageView["link_preview"]>; readonly seed: number }) {
  const href = safeHref(preview.url);
  const [imageFailed, setImageFailed] = useState(false);
  if (href === null) return null;
  const domain = preview.site_name ?? new URL(href).hostname;
  return (
    <a className="chat-link" href={href} target="_blank" rel="noopener noreferrer">
      {preview.image_url && !imageFailed
        ? <img className="chat-link-image" src={preview.image_url} alt="" referrerPolicy="no-referrer" onError={() => setImageFailed(true)} />
        : <Photo src={null} alt="" seed={seed} radius={0} className="chat-link-image" />}
      {preview.title && <span className="chat-link-title">{preview.title}</span>}
      <span className="chat-link-domain">{domain}</span>
    </a>
  );
}
