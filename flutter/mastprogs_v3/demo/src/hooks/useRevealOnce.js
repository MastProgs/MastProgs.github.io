import { useEffect, useRef } from "react";
import { prefersReducedMotion } from "../lib/motion.js";

// AI-NOTE: 콘텐츠는 기본적으로 보이는 상태로 렌더링한다. IntersectionObserver 가 있고 동작 줄이기 설정이 아닐 때만
// data-reveal="pending" 으로 숨겼다가 한 번 나타나게 하므로, 관찰자가 없거나 스크립트가 실패해도 내용이 사라지지 않는다.
export function useRevealOnce(enabled = true) {
  const ref = useRef(null);

  useEffect(() => {
    const node = ref.current;
    if (!node || !enabled) return undefined;
    if (typeof IntersectionObserver !== "function" || prefersReducedMotion()) return undefined;
    if (node.dataset.reveal === "shown") return undefined;

    node.dataset.reveal = "pending";
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries.some((entry) => entry.isIntersecting)) {
          node.dataset.reveal = "shown";
          observer.disconnect();
        }
      },
      { rootMargin: "0px 0px -8% 0px", threshold: 0 },
    );
    observer.observe(node);
    return () => observer.disconnect();
  }, [enabled]);

  return ref;
}
