import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { App } from "./app/app";
import { applyTheme, watchSystemTheme } from "./shared/lib/theme";
import "./styles/tokens.css";
import "./styles/base.css";
import "./styles/shell.css";

applyTheme();
watchSystemTheme();

const root = document.getElementById("root");
if (root) createRoot(root).render(<StrictMode><App /></StrictMode>);
