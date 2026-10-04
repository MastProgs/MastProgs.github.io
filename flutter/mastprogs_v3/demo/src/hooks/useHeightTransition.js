import { useLayoutEffect, useRef } from "react";
import { debugWarn } from "../lib/debug.js";
import { prefersReducedMotion } from "../lib/motion.js";

const EASE = "cubic-bezier(0.2, 0.8, 0.2, 1)";

// AI-NOTE: 경로(직접/순차/병렬)나 실패 토글이 바뀌면 타임라인 영역의 이전 높이에서 새 높이로 FLIP 식 전환을 한다.
// 매 렌더 직후(useLayoutEffect) 실제 높이를 기록해 두고, key 가 바뀐 렌더에서만 기록된 이전 높이 → 현재 높이로
// Web Animations API 를 돌린다. 높이가 같으면 짧은 페이드만 한다. 전환 중에는 다음 측정을 건너뛰어 중간 높이를 기록하지 않는다.
// 동작 줄이기, animate 미지원, 첫 렌더(?state=target 포함)에서는 아무것도 하지 않는다.
export function useHeightTransition(key, { resizeMs, fadeMs }) {
  const ref = useRef(null);
  const lastHeight = useRef(null);
  const lastKey = useRef(key);
  const animation = useRef(null);

  useLayoutEffect(() => {
    const node = ref.current;
    if (!node) return;
    const changed = lastKey.current !== key;
    lastKey.current = key;
    if (!changed && animation.current?.playState === "running") return;
    if (changed && animation.current) {
      animation.current.cancel();
      animation.current = null;
    }

    const next = node.getBoundingClientRect().height;
    const prev = lastHeight.current;
    lastHeight.current = next;
    if (!changed || prev === null || prefersReducedMotion() || typeof node.animate !== "function") return;

    const resize = Math.abs(prev - next) > 1;
    const frames = resize
      ? [{ height: `${prev}px`, opacity: 0.4 }, { height: `${next}px`, opacity: 1 }]
      : [{ opacity: 0.4 }, { opacity: 1 }];
    try {
      if (resize) node.style.overflow = "hidden";
      const running = node.animate(frames, { duration: resize ? resizeMs : fadeMs, easing: EASE });
      animation.current = running;
      running.finished
        .catch(() => {})
        .finally(() => {
          // 취소된 이전 전환의 마무리가 새 전환의 overflow 를 풀지 않도록, 자기 자신이 마지막 전환일 때만 정리한다.
          if (animation.current !== running && animation.current !== null) return;
          animation.current = null;
          node.style.overflow = "";
        });
    } catch (error) {
      node.style.overflow = "";
      debugWarn("timeline height transition failed", error);
    }
  });

  return ref;
}
