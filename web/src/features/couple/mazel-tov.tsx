import { useEffect } from "react";
import { Heart } from "lucide-react";

const SHOWN_MS = 2600;

// Brief celebration when a couple is formed; `onDone` fires once it has been
// seen (the shell then switches to the couple navigation).
export function MazelTov({ partner, onDone }: { readonly partner: string | null; readonly onDone: () => void }) {
  useEffect(() => {
    const timer = window.setTimeout(onDone, SHOWN_MS);
    return () => window.clearTimeout(timer);
  }, [onDone]);
  return (
    <div className="mazel-tov" role="status" aria-live="polite">
      <Heart size={40} aria-hidden="true" />
      <h2 className="display-s">Mazel Tov</h2>
      <p className="body-l muted">{partner ? `Vous et ${partner} êtes désormais en couple sur MAZL.` : "Vous êtes désormais en couple sur MAZL."}</p>
    </div>
  );
}
