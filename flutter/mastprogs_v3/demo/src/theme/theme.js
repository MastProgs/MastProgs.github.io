// 화면 테마(어두운/밝은)의 순수 도우미. node:test 가 직접 import 하므로 브라우저 전역을 직접 만지지 않고 인자로 받는다.
// AI-NOTE: 개인정보 보장의 유일한 예외(사용자 요청): 고른 테마만 이 브라우저의 localStorage 에 "dark" | "light" 문자열 하나로 남긴다.
// 다른 값(연락처·워크플로우 진행·재생 위치·방문 정보)은 저장하지 않고, 서버로 보내지 않으며 수집 도구도 없다.
// 같은 키를 메인 이력서와 /workflow(새 탭)가 함께 읽으므로 상세 페이지도 같은 테마로 열린다.

export const THEMES = Object.freeze(["dark", "light"]);
export const DEFAULT_THEME = "dark";
export const THEME_STORAGE_KEY = "mastprogs-theme";

export const isTheme = (value) => THEMES.includes(value);
export const normalizeTheme = (value) => (isTheme(value) ? value : DEFAULT_THEME);
export const toggleTheme = (theme) => (normalizeTheme(theme) === "dark" ? "light" : "dark");

// window.localStorage 게터 자체가 던질 수 있다(쿠키 차단 등). 그때는 저장소 없음(null)으로 다룬다.
export function storageFrom(win) {
  try {
    return win?.localStorage ?? null;
  } catch {
    return null;
  }
}

// 저장소 접근은 막혀 있을 수 있다(사생활 모드 등). 실패하면 기본 테마로 조용히 돌아간다.
export function readStoredTheme(storage) {
  try {
    return normalizeTheme(storage?.getItem(THEME_STORAGE_KEY));
  } catch {
    return DEFAULT_THEME;
  }
}

// 허용 목록 밖의 값은 쓰지 않는다. 키도 이 하나만 쓴다.
export function writeStoredTheme(storage, theme) {
  if (!isTheme(theme)) return false;
  try {
    storage?.setItem(THEME_STORAGE_KEY, theme);
    return true;
  } catch {
    return false;
  }
}

// <html data-theme> 하나로 CSS 토큰(theme.css)이 바뀐다. 어두운 기본은 속성 없이도 같은 값이다.
export function applyTheme(root, theme) {
  if (!root) return;
  const value = normalizeTheme(theme);
  root.dataset.theme = value;
  root.style.colorScheme = value;
}

export const THEME_COPY = Object.freeze({
  dark: { label: "어두운 테마", switchTo: "밝은 테마로 전환" },
  light: { label: "밝은 테마", switchTo: "어두운 테마로 전환" },
});
