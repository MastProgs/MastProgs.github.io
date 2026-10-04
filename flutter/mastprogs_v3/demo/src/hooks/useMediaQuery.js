import { useSyncExternalStore } from "react";

// 모바일 세로 타임라인 기준. CSS 의 @media (max-width: 600px) 와 같은 값을 써야 한다.
export const MOBILE_QUERY = "(max-width: 600px)";

export function useMediaQuery(query) {
  return useSyncExternalStore(
    (onChange) => {
      if (typeof window === "undefined" || typeof window.matchMedia !== "function") return () => {};
      const list = window.matchMedia(query);
      list.addEventListener("change", onChange);
      return () => list.removeEventListener("change", onChange);
    },
    () => typeof window !== "undefined" && typeof window.matchMedia === "function" && window.matchMedia(query).matches,
    () => false,
  );
}
