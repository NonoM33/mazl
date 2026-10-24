import { useCallback, useEffect, useRef, useState } from "react";
import type { ApiResult } from "../api/client";

export type AsyncState<T> =
  | { readonly status: "loading" }
  | { readonly status: "ok"; readonly data: T }
  | { readonly status: "error"; readonly code: string; readonly message: string };

/** Charge une ressource ; ignore les réponses périmées quand les dépendances changent. */
export function useAsync<T>(load: () => Promise<ApiResult<T>>, deps: readonly unknown[]): { readonly state: AsyncState<T>; readonly reload: () => void } {
  const [state, setState] = useState<AsyncState<T>>({ status: "loading" });
  const [tick, setTick] = useState(0);
  const latest = useRef(0);
  const loader = useRef(load);
  loader.current = load;
  useEffect(() => {
    latest.current += 1;
    const mine = latest.current;
    setState((current) => (current.status === "ok" ? current : { status: "loading" }));
    void loader.current().then((result) => {
      if (mine !== latest.current) return;
      setState(result.ok ? { status: "ok", data: result.data } : { status: "error", code: result.code, message: result.message });
    });
    return () => {
      latest.current += 1;
    };
  }, [...deps, tick]);
  const reload = useCallback(() => {
    setState((current) => (current.status === "error" ? { status: "loading" } : current));
    setTick((value) => value + 1);
  }, []);
  return { state, reload };
}
