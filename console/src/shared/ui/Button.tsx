import type { ButtonHTMLAttributes, ReactElement, ReactNode } from "react";
import { Icon, type IconName } from "./Icon";

export type ButtonVariant = "primary" | "secondary" | "ghost" | "danger";

interface ButtonProps extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, "className"> {
  readonly variant?: ButtonVariant;
  readonly size?: "m" | "s";
  readonly icon?: IconName;
  readonly loading?: boolean;
  readonly children?: ReactNode;
}

export function Button({ variant = "secondary", size = "m", icon, loading = false, children, disabled, type = "button", ...rest }: ButtonProps): ReactElement {
  return (
    <button {...rest} type={type} disabled={disabled === true || loading} aria-busy={loading || undefined} className={`btn btn-${variant} btn-${size}`}>
      {loading ? <span className="spinner" aria-hidden="true" /> : icon !== undefined ? <Icon name={icon} size={size === "s" ? 15 : 16} /> : null}
      {children}
    </button>
  );
}
