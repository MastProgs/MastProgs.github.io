import { flushSync } from "react-dom";
import { debugWarn } from "./debug.js";

export function prefersReducedMotion() {
  if (typeof window === "undefined" || typeof window.matchMedia !== "function") return false;
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

// AI-NOTE: View Transitions API 는 기능 감지 후에만 사용한다. 미지원 브라우저나 동작 줄이기 설정에서는
// 상태만 바로 바꾸며, 기능 자체는 동일하게 동작한다. ready 가 건너뛰기로 거부되는 경우를 삼켜 미처리 거부를 막는다.
export function runViewTransition(update, { onBefore, onDuring, onFinish } = {}) {
  const supported = typeof document !== "undefined" && typeof document.startViewTransition === "function";
  if (!supported || prefersReducedMotion()) {
    onDuring?.();
    update();
    onFinish?.();
    return;
  }
  try {
    onBefore?.();
    const transition = document.startViewTransition(() => {
      onDuring?.();
      flushSync(update);
    });
    transition.ready.catch(() => {});
    transition.finished
      .catch((error) => debugWarn("view transition update failed", error))
      .finally(() => onFinish?.());
  } catch (error) {
    debugWarn("view transition failed, applying update directly", error);
    onDuring?.();
    update();
    onFinish?.();
  }
}
