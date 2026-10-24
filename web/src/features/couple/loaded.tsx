import type { ReactNode } from "react";
import { describeError } from "../../shared/api/errors";
import type { ResourceHandle } from "../../shared/hooks/use-resource";
import { Skeleton } from "../../shared/ui/empty-state";

// Loading, failure (with a retry) or the loaded content of a resource.
export function Loaded<T>({ resource, children, height = 80 }: { readonly resource: ResourceHandle<T>; readonly children: (data: T) => ReactNode; readonly height?: number }) {
  const { state, reload } = resource;
  if (state.data !== undefined) return <>{children(state.data)}</>;
  if (state.status === "error") {
    return (
      <div className="stack gap-8" role="alert">
        <p className="body-s">{describeError(state.error)}</p>
        <button type="button" className="btn btn-outline btn-sm" style={{ alignSelf: "flex-start" }} onClick={() => void reload()}>Réessayer</button>
      </div>
    );
  }
  return <Skeleton height={height} radius={16} />;
}
