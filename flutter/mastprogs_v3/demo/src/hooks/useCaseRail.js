import { useCallback, useEffect, useRef, useState } from "react";
import { centeredIndex, scrollLeftToCenter, tiltRatio } from "../lib/rail.js";
import { prefersReducedMotion } from "../lib/motion.js";

// AI-NOTE: 레일은 네이티브 가로 스크롤 + scroll-snap 이 위치를 정하고, 이 훅은 측정만 한다. scroll/resize 마다 rAF 한 번으로
// 카드별 --tilt 를 DOM 에 직접 쓰고(React 렌더 없음), 가운데 카드 인덱스가 바뀔 때만 상태를 갱신한다.
// 휠·터치 스크롤을 막거나 가로채지 않는다. 카드의 offsetLeft 기준이 레일이 되도록 레일은 position: relative 여야 한다.
export function useCaseRail(count) {
  const railRef = useRef(null);
  const itemRefs = useRef([]);
  const [active, setActive] = useState(0);

  const measure = useCallback(() => {
    const rail = railRef.current;
    if (!rail) return null;
    const viewport = { scrollLeft: rail.scrollLeft, clientWidth: rail.clientWidth, scrollWidth: rail.scrollWidth };
    const items = itemRefs.current.slice(0, count).map((node) => (node ? { left: node.offsetLeft, width: node.offsetWidth } : null));
    return { viewport, items };
  }, [count]);

  useEffect(() => {
    const rail = railRef.current;
    if (!rail) return undefined;
    let frame = 0;
    const update = () => {
      frame = 0;
      const snapshot = measure();
      if (!snapshot || snapshot.items.some((item) => item === null)) return;
      snapshot.items.forEach((item, index) => {
        itemRefs.current[index]?.style.setProperty("--tilt", String(tiltRatio(item, snapshot.viewport)));
      });
      const index = centeredIndex(snapshot.viewport, snapshot.items);
      if (index >= 0) setActive(index);
    };
    const schedule = () => {
      if (!frame) frame = window.requestAnimationFrame(update);
    };
    schedule();
    rail.addEventListener("scroll", schedule, { passive: true });
    window.addEventListener("resize", schedule);
    return () => {
      if (frame) window.cancelAnimationFrame(frame);
      rail.removeEventListener("scroll", schedule);
      window.removeEventListener("resize", schedule);
    };
  }, [measure]);

  const scrollToIndex = useCallback(
    (index) => {
      const rail = railRef.current;
      const snapshot = measure();
      const item = snapshot?.items[index];
      if (!rail || !item) return;
      rail.scrollTo({ left: scrollLeftToCenter(item, snapshot.viewport), behavior: prefersReducedMotion() ? "auto" : "smooth" });
    },
    [measure],
  );

  const setItemRef = useCallback(
    (index) => (node) => {
      itemRefs.current[index] = node;
    },
    [],
  );

  return { railRef, setItemRef, active, scrollToIndex };
}
