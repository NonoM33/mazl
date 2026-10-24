import { createContext, useCallback, useContext, useEffect, useMemo, useState, type AnchorHTMLAttributes, type MouseEvent, type ReactNode } from "react";

// A small history router: the site lives under /app and has a dozen routes,
// which does not justify a dependency (docs/web/adr/W08-pile-front.md).

export const BASE = "/app";

interface Location { readonly path: string; readonly search: URLSearchParams }
interface RouterValue { readonly location: Location; readonly navigate: (to: string, options?: { replace?: boolean }) => void }

const RouterContext = createContext<RouterValue | null>(null);

function readLocation(): Location {
  const raw = window.location.pathname;
  const path = raw.startsWith(BASE) ? raw.slice(BASE.length) || "/" : "/";
  return { path: path.length > 1 ? path.replace(/\/+$/, "") : path, search: new URLSearchParams(window.location.search) };
}

export function RouterProvider({ children }: { readonly children: ReactNode }) {
  const [location, setLocation] = useState(readLocation);

  useEffect(() => {
    const onPop = () => setLocation(readLocation());
    window.addEventListener("popstate", onPop);
    return () => window.removeEventListener("popstate", onPop);
  }, []);

  const navigate = useCallback((to: string, options?: { replace?: boolean }) => {
    const url = to.startsWith("/") ? `${BASE}${to === "/" ? "" : to}` : to;
    if (options?.replace) window.history.replaceState(null, "", url);
    else window.history.pushState(null, "", url);
    setLocation(readLocation());
    window.scrollTo({ top: 0 });
  }, []);

  const value = useMemo(() => ({ location, navigate }), [location, navigate]);
  return <RouterContext value={value}>{children}</RouterContext>;
}

export function useRouter(): RouterValue {
  const value = useContext(RouterContext);
  if (!value) throw new Error("useRouter outside RouterProvider");
  return value;
}

// Matches "/messages/:id" against "/messages/12" → { id: "12" }.
export function matchPath(pattern: string, path: string): Readonly<Record<string, string>> | null {
  const want = pattern.split("/").filter(Boolean);
  const got = path.split("/").filter(Boolean);
  if (want.length !== got.length) return null;
  const params: Record<string, string> = {};
  for (const [index, segment] of want.entries()) {
    const actual = got[index] ?? "";
    if (segment.startsWith(":")) params[segment.slice(1)] = decodeURIComponent(actual);
    else if (segment !== actual) return null;
  }
  return params;
}

type LinkProps = Omit<AnchorHTMLAttributes<HTMLAnchorElement>, "href"> & { readonly to: string };

export function Link({ to, onClick, children, ...rest }: LinkProps) {
  const { navigate } = useRouter();
  const href = `${BASE}${to === "/" ? "" : to}`;
  const handle = (event: MouseEvent<HTMLAnchorElement>) => {
    onClick?.(event);
    if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
    event.preventDefault();
    navigate(to);
  };
  return <a href={href} onClick={handle} {...rest}>{children}</a>;
}
