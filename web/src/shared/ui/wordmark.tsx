// "mazl." — the brand is the word itself (MazlWordmark in the app), the dot in accent.
export function Wordmark({ size = 28 }: { readonly size?: number }) {
  return (
    <span className="wordmark" style={{ fontSize: size }} aria-label="mazl" role="img">
      mazl<span className="dot">.</span>
    </span>
  );
}
