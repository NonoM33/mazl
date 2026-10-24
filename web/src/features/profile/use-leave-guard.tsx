import { useEffect, useState } from "react";
import { BASE, useRouter } from "../../shared/router";

// While `dirty`, leaving the screen asks first: in-app links (captured before
// the router sees them), closing or reloading the tab. Returns the path
// waiting for an answer, and its two outcomes.
export function useLeaveGuard(dirty: boolean) {
  const { navigate, location } = useRouter();
  const [waiting, setWaiting] = useState<string | null>(null);

  useEffect(() => {
    if (!dirty) return undefined;
    const onClick = (event: MouseEvent) => {
      const anchor = event.target instanceof Element ? event.target.closest("a[href]") : null;
      const href = anchor?.getAttribute("href") ?? "";
      if (!href.startsWith(`${BASE}/`) && href !== BASE) return;
      const path = href.slice(BASE.length) || "/";
      if (path === location.path || event.button !== 0 || event.metaKey || event.ctrlKey) return;
      event.preventDefault();
      event.stopPropagation();
      setWaiting(path);
    };
    const onUnload = (event: BeforeUnloadEvent) => { event.preventDefault(); };
    document.addEventListener("click", onClick, true);
    window.addEventListener("beforeunload", onUnload);
    return () => {
      document.removeEventListener("click", onClick, true);
      window.removeEventListener("beforeunload", onUnload);
    };
  }, [dirty, location.path]);

  return {
    waiting,
    stay: () => setWaiting(null),
    leave: () => { const to = waiting; setWaiting(null); if (to) navigate(to); },
    ask: (to: string) => (dirty ? setWaiting(to) : navigate(to)),
  };
}
