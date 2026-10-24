import { createContext, useCallback, useContext, useMemo, useRef, useState, type ReactNode } from "react";

// Floating ink snackbar (app_theme.dart). A toast may carry one action
// (« Annuler ») and its keyboard hint.

export interface ToastOptions { readonly action?: { readonly label: string; readonly run: () => void; readonly key?: string }; readonly durationMs?: number }
interface ToastItem extends ToastOptions { readonly id: number; readonly message: string }
interface ToastApi { readonly show: (message: string, options?: ToastOptions) => number; readonly dismiss: (id: number) => void }

const ToastContext = createContext<ToastApi | null>(null);

export function ToastProvider({ children }: { readonly children: ReactNode }) {
  const [items, setItems] = useState<readonly ToastItem[]>([]);
  const next = useRef(1);

  const dismiss = useCallback((id: number) => setItems((current) => current.filter((item) => item.id !== id)), []);
  const show = useCallback((message: string, options: ToastOptions = {}) => {
    const id = next.current++;
    setItems((current) => [...current.slice(-2), { id, message, ...options }]);
    window.setTimeout(() => dismiss(id), options.durationMs ?? 4000);
    return id;
  }, [dismiss]);

  const value = useMemo(() => ({ show, dismiss }), [show, dismiss]);
  return (
    <ToastContext value={value}>
      {children}
      <div className="toasts" role="status" aria-live="polite">
        {items.map((item) => (
          <div key={item.id} className="toast">
            <span>{item.message}</span>
            {item.action && (
              <button type="button" onClick={() => { item.action?.run(); dismiss(item.id); }}>
                {item.action.label} {item.action.key && <kbd>{item.action.key}</kbd>}
              </button>
            )}
          </div>
        ))}
      </div>
    </ToastContext>
  );
}

export function useToast(): ToastApi {
  const value = useContext(ToastContext);
  if (!value) throw new Error("useToast outside ToastProvider");
  return value;
}
