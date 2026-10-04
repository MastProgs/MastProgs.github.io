import React from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App.jsx";
import { ThemeProvider } from "./theme/ThemeContext.jsx";
import { applyTheme, readStoredTheme } from "./theme/theme.js";
import "./styles.css";

// AI-NOTE: 첫 그림 전에 저장된 테마(허용 값만)를 적용해 깜빡임을 막는다. 메인과 /workflow 모두 이 Provider 아래에서 그려진다.
let storage = null;
try {
  storage = window.localStorage;
} catch {
  storage = null;
}
applyTheme(document.documentElement, readStoredTheme(storage));

createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <ThemeProvider>
      <App />
    </ThemeProvider>
  </React.StrictMode>,
);
