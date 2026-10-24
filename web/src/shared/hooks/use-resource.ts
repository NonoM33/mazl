import { useCallback, useEffect, useRef, useState } from "react";

// Loads a resource and keeps it fresh. Photo and media URLs are signed for one
// hour (docs/verification/CONTRAT.md): anything that holds them is reloaded
// before they expire, never cached beyond the page.

export const SIGNED_URL_REFRESH_MS = 45 * 60_000;

export type Resource<T> =
  | { readonly status: "loading"; readonly data: undefined; readonly error: undefined }
  | { readonly status: "ready"; readonly data: T; readonly error: undefined }
  | { readonly status: "error"; readonly data: T | undefined; readonly error: unknown };

export interface ResourceHandle<T> {
  readonly state: Resource<T>;
  readonly reload: () => Promise<void>;
  readonly mutate: (update: (current: T) => T) => void;
}

// `key` names what is loaded ("profile:12"): a new key reloads.
export function useResource<T>(key: string, load: (signal: AbortSignal) => Promise<T>, refreshMs: number | null = SIGNED_URL_REFRESH_MS): ResourceHandle<T> {
  const [state, setState] = useState<Resource<T>>({ status: "loading", data: undefined, error: undefined });
  const loader = useRef(load);
  loader.current = load;
  const controller = useRef<AbortController | null>(null);

  const reload = useCallback(async () => {
    controller.current?.abort();
    const current = new AbortController();
    controller.current = current;
    try {
      const data = await loader.current(current.signal);
      if (!current.signal.aborted) setState({ status: "ready", data, error: undefined });
    } catch (error) {
      if (current.signal.aborted) return;
      setState((previous) => ({ status: "error", data: previous.data, error }));
    }
  }, []);

  useEffect(() => {
    setState({ status: "loading", data: undefined, error: undefined });
    void reload();
    const timer = refreshMs === null ? null : window.setInterval(() => void reload(), refreshMs);
    return () => {
      controller.current?.abort();
      if (timer !== null) window.clearInterval(timer);
    };
  }, [key, reload, refreshMs]);

  const mutate = useCallback((update: (current: T) => T) => {
    setState((previous) => (previous.data === undefined ? previous : { status: "ready", data: update(previous.data), error: undefined }));
  }, []);

  return { state, reload, mutate };
}
