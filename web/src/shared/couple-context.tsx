import { createContext, useContext, useEffect, type ReactNode } from "react";
import { api } from "./api/client";
import type { CoupleResponse, CoupleView } from "./api/types";
import { useResource } from "./hooks/use-resource";
import { realtime } from "./realtime/socket";

// The server is the truth for couple mode (docs/couple/CONTRAT.md): read at
// start, on return to the tab, and on the couple:* socket events.

interface CoupleApi { readonly couple: CoupleView | null; readonly ready: boolean; readonly reload: () => Promise<void> }
const CoupleContext = createContext<CoupleApi>({ couple: null, ready: false, reload: () => Promise.resolve() });

export function CoupleProvider({ children }: { readonly children: ReactNode }) {
  const resource = useResource("couple", (signal) => api.get<CoupleResponse>("/api/couple", signal), 5 * 60_000);
  const { reload } = resource;
  useEffect(() => {
    const onVisible = () => { if (document.visibilityState === "visible") void reload(); };
    document.addEventListener("visibilitychange", onVisible);
    const offs = ["couple:accepted", "couple:ended"].map((type) => realtime.on(type, () => void reload()));
    return () => { document.removeEventListener("visibilitychange", onVisible); for (const off of offs) off(); };
  }, [reload]);
  const couple = resource.state.data?.couple ?? null;
  const ready = resource.state.status !== "loading";
  return <CoupleContext value={{ couple, ready, reload }}>{children}</CoupleContext>;
}

export const useCouple = (): CoupleApi => useContext(CoupleContext);
