import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import { THEME_STORAGE_KEY, applyTheme, normalizeTheme, readStoredTheme, storageFrom, toggleTheme, writeStoredTheme } from "./theme.js";

const storageOf = () => (typeof window === "undefined" ? null : storageFrom(window));

const ThemeContext = createContext(null);

// AI-NOTE: 테마 상태는 이 Provider 한 곳에만 있다(main.jsx 가 App 전체를 감싸 메인과 /workflow 가 같은 상태를 쓴다).
// 컴포넌트마다 색 상태를 따로 두지 않는다. 다른 탭에서 바꾸면 storage 이벤트로 이 탭도 따라간다(허용 값만 반영).
export function ThemeProvider({ children }) {
  const [theme, setThemeState] = useState(() => readStoredTheme(storageOf()));

  useEffect(() => {
    applyTheme(document.documentElement, theme);
  }, [theme]);

  useEffect(() => {
    const handleStorage = (event) => {
      if (event.key === THEME_STORAGE_KEY) setThemeState(normalizeTheme(event.newValue));
    };
    window.addEventListener("storage", handleStorage);
    return () => window.removeEventListener("storage", handleStorage);
  }, []);

  const setTheme = useCallback((value) => {
    const next = normalizeTheme(value);
    writeStoredTheme(storageOf(), next);
    setThemeState(next);
  }, []);

  const value = useMemo(() => ({ theme, setTheme, toggle: () => setTheme(toggleTheme(theme)) }), [theme, setTheme]);
  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme() {
  const value = useContext(ThemeContext);
  if (!value) throw new Error("useTheme must be used inside ThemeProvider");
  return value;
}
