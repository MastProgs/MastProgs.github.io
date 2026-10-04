import { MoonIcon, SunIcon } from "@phosphor-icons/react";
import { THEME_COPY } from "../theme/theme.js";
import { useTheme } from "../theme/ThemeContext.jsx";

// 메인 헤더·모바일 헤더·고정 바·/workflow 상단이 같은 버튼을 쓴다. 현재 테마 이름을 보이고, 누르면 반대 테마로 바뀐다.
// compact: 아주 좁은 화면에서 글자를 숨기고 아이콘만(접근 이름은 유지, 44px).
export function ThemeToggle({ compact = false }) {
  const { theme, toggle } = useTheme();
  const copy = THEME_COPY[theme];
  const Icon = theme === "dark" ? MoonIcon : SunIcon;
  return (
    <button
      type="button"
      className={`theme-toggle${compact ? " theme-toggle--compact" : ""}`}
      aria-label={copy.switchTo}
      title={copy.switchTo}
      onClick={toggle}
    >
      <Icon size={18} weight="bold" aria-hidden="true" />
      <span className="theme-toggle__label" aria-hidden="true">{copy.label}</span>
    </button>
  );
}
