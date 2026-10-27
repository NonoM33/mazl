import type { ReactElement } from "react";

export type IconName =
  | "dashboard" | "flag" | "users" | "scale" | "shield" | "building" | "sliders" | "log" | "team" | "chart"
  | "logout" | "close" | "search" | "copy" | "check" | "alert" | "lock" | "eye" | "eye-off" | "message"
  | "clock" | "user" | "refresh" | "arrow-right" | "chevron-right" | "inbox" | "info" | "tag" | "calendar" | "arrow-up" | "arrow-down" | "grip" | "plus" | "wand";

const PATHS: Readonly<Record<IconName, ReactElement>> = {
  dashboard: <><rect x="3.5" y="3.5" width="7" height="8" rx="1.5" /><rect x="13.5" y="3.5" width="7" height="5" rx="1.5" /><rect x="13.5" y="11.5" width="7" height="9" rx="1.5" /><rect x="3.5" y="14.5" width="7" height="6" rx="1.5" /></>,
  flag: <><path d="M5 21V4" /><path d="M5 4.5h11l-2 4 2 4H5" /></>,
  users: <><circle cx="9" cy="8" r="3.5" /><path d="M2.5 20c.6-3.6 3.2-5.5 6.5-5.5s5.9 1.9 6.5 5.5" /><path d="M16 4.7a3.4 3.4 0 0 1 0 6.6" /><path d="M18 14.8c1.9.6 3.1 2.3 3.5 5.2" /></>,
  scale: <><path d="M12 4v16" /><path d="M7 20h10" /><path d="M5 7h14" /><path d="M5 7l-3 7a3.2 3.2 0 0 0 6 0L5 7z" /><path d="M19 7l-3 7a3.2 3.2 0 0 0 6 0l-3-7z" /></>,
  shield: <><path d="M12 3l7.5 3v5.5c0 4.6-3.1 8-7.5 9.5-4.4-1.5-7.5-4.9-7.5-9.5V6L12 3z" /><path d="M8.7 12l2.4 2.4 4.3-4.8" /></>,
  building: <><rect x="5" y="3.5" width="14" height="17" rx="1.5" /><path d="M9 8h2M13 8h2M9 12h2M13 12h2" /><path d="M10 20.5v-4h4v4" /></>,
  sliders: <><path d="M4 7h9M17 7h3M4 17h3M11 17h9" /><circle cx="15" cy="7" r="2" /><circle cx="9" cy="17" r="2" /></>,
  log: <><path d="M6 3.5h9l3.5 3.5v13.5H6z" /><path d="M14.5 3.5V7.5H18.5" /><path d="M9 12h6M9 15.5h6" /></>,
  team: <><circle cx="12" cy="8.5" r="3.5" /><path d="M5 20c.7-3.6 3.5-5.5 7-5.5s6.3 1.9 7 5.5" /></>,
  chart: <><path d="M4 20V4" /><path d="M4 20h16" /><path d="M8 15l3.5-4 3 2.5L19 8" /></>,
  logout: <><path d="M10 4H5.5A1.5 1.5 0 0 0 4 5.5v13A1.5 1.5 0 0 0 5.5 20H10" /><path d="M15 8l4 4-4 4" /><path d="M19 12H9" /></>,
  close: <><path d="M6 6l12 12M18 6L6 18" /></>,
  search: <><circle cx="11" cy="11" r="6.5" /><path d="M16 16l4.5 4.5" /></>,
  copy: <><rect x="8.5" y="8.5" width="11" height="11" rx="2" /><path d="M15.5 8.5V6A1.5 1.5 0 0 0 14 4.5H6A1.5 1.5 0 0 0 4.5 6v8A1.5 1.5 0 0 0 6 15.5h2.5" /></>,
  check: <><path d="M5 12.5l4.5 4.5L19 7.5" /></>,
  alert: <><path d="M12 4l9 16H3L12 4z" /><path d="M12 10v4.5" /><path d="M12 17.4v.1" /></>,
  lock: <><rect x="5" y="10.5" width="14" height="10" rx="2" /><path d="M8 10.5V8a4 4 0 0 1 8 0v2.5" /></>,
  eye: <><path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z" /><circle cx="12" cy="12" r="3" /></>,
  "eye-off": <><path d="M4 4l16 16" /><path d="M9.9 5.8A9 9 0 0 1 12 5.5c6 0 9.5 6.5 9.5 6.5a16 16 0 0 1-3 3.8M6.2 7.6A15.6 15.6 0 0 0 2.5 12S6 18.5 12 18.5c1.3 0 2.5-.3 3.6-.8" /><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2" /></>,
  message: <><path d="M4 5.5h16v10.5H9.5L5 20v-4H4z" /></>,
  clock: <><circle cx="12" cy="12" r="8.5" /><path d="M12 7.5V12l3 2" /></>,
  user: <><circle cx="12" cy="8.5" r="3.5" /><path d="M5 20c.7-3.6 3.5-5.5 7-5.5s6.3 1.9 7 5.5" /></>,
  refresh: <><path d="M20 11a8 8 0 0 0-14.5-3.5L4 9" /><path d="M4 4v5h5" /><path d="M4 13a8 8 0 0 0 14.5 3.5L20 15" /><path d="M20 20v-5h-5" /></>,
  "arrow-right": <><path d="M5 12h14" /><path d="M13 6l6 6-6 6" /></>,
  "chevron-right": <><path d="M9 6l6 6-6 6" /></>,
  inbox: <><path d="M3.5 13l2.5-7.5h12L20.5 13" /><path d="M3.5 13v5.5h17V13h-5l-1 2.5h-5L8.5 13z" /></>,
  tag: <><path d="M3.5 12.2V4.5a1 1 0 0 1 1-1h7.7a1 1 0 0 1 .7.3l7.3 7.3a1 1 0 0 1 0 1.4l-7.7 7.7a1 1 0 0 1-1.4 0L3.8 12.9a1 1 0 0 1-.3-.7z" /><circle cx="8" cy="8" r="1.3" /></>,
  calendar: <><rect x="3.5" y="5" width="17" height="15.5" rx="2" /><path d="M3.5 10h17" /><path d="M8 3v4M16 3v4" /></>,
  "arrow-up": <><path d="M12 19V5" /><path d="M6 11l6-6 6 6" /></>,
  "arrow-down": <><path d="M12 5v14" /><path d="M6 13l6 6 6-6" /></>,
  grip: <><circle cx="9" cy="6.5" r="1.1" /><circle cx="15" cy="6.5" r="1.1" /><circle cx="9" cy="12" r="1.1" /><circle cx="15" cy="12" r="1.1" /><circle cx="9" cy="17.5" r="1.1" /><circle cx="15" cy="17.5" r="1.1" /></>,
  plus: <><path d="M12 5v14M5 12h14" /></>,
  wand: <><path d="M5 19L16 8" /><path d="M14 6l4 4" /><path d="M18 3v3M16.500 4.500h3M6 4v2M5 5h2" /></>,
  info: <><circle cx="12" cy="12" r="8.5" /><path d="M12 11v5" /><path d="M12 8v.1" /></>,
};

export function Icon({ name, size = 18 }: { readonly name: IconName; readonly size?: number }): ReactElement {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.5}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
    >
      {PATHS[name]}
    </svg>
  );
}
