import { useLayoutEffect, useRef, useState } from "react";
import { MODES } from "../../workflow/constants.js";
import { nextRovingIndex } from "../../lib/roving.js";

// 실행 경로 선택. 라디오 그룹 규칙: 선택된 항목만 Tab 으로 들어가고, 화살표/Home/End 로 이동과 동시에 선택한다.
// AI-NOTE: 선택 표시는 항목 배경 대신 하나의 표시기(.segmented__indicator)가 translateX 로 미끄러진다. 위치는 선택 항목의
// offsetLeft/offsetWidth 를 측정해 정하고, 그룹 크기가 바뀌면(모바일 전체 폭 등) ResizeObserver 로 다시 잰다.
// 측정 전(첫 페인트 전, 측정 실패)에는 is-sliding 이 없으므로 선택 항목이 자기 배경으로 표시되어 상태가 사라지지 않는다.
export function ModeSwitch({ value, onChange }) {
  const groupRef = useRef(null);
  const itemRefs = useRef([]);
  const [indicator, setIndicator] = useState(null);
  const checkedIndex = MODES.findIndex((mode) => mode.id === value);

  useLayoutEffect(() => {
    const group = groupRef.current;
    if (!group) return undefined;
    const measure = () => {
      const item = itemRefs.current[checkedIndex];
      if (!item) return;
      const next = { x: item.offsetLeft, y: item.offsetTop, w: item.offsetWidth, h: item.offsetHeight };
      setIndicator((prev) =>
        prev && prev.x === next.x && prev.y === next.y && prev.w === next.w && prev.h === next.h ? prev : next,
      );
    };
    measure();
    if (typeof ResizeObserver !== "function") return undefined;
    const observer = new ResizeObserver(measure);
    observer.observe(group);
    return () => observer.disconnect();
  }, [checkedIndex]);

  const handleKeyDown = (event, index) => {
    const target = nextRovingIndex(event.key, index, MODES.length, { orientation: "both" });
    if (target === null) return;
    event.preventDefault();
    onChange(MODES[target].id);
    itemRefs.current[target]?.focus();
  };

  return (
    <div ref={groupRef} className={`segmented${indicator ? " is-sliding" : ""}`} role="radiogroup" aria-label="실행 경로">
      {indicator && (
        <span
          className="segmented__indicator"
          aria-hidden="true"
          style={{ top: indicator.y, width: indicator.w, height: indicator.h, transform: `translateX(${indicator.x}px)` }}
        />
      )}
      {MODES.map((mode, index) => {
        const checked = mode.id === value;
        return (
          <button
            key={mode.id}
            ref={(node) => {
              itemRefs.current[index] = node;
            }}
            type="button"
            role="radio"
            aria-checked={checked}
            tabIndex={checked ? 0 : -1}
            title={mode.hint}
            className={`segmented__item${checked ? " is-checked" : ""}`}
            onClick={() => onChange(mode.id)}
            onKeyDown={(event) => handleKeyDown(event, index)}
          >
            {mode.label}
          </button>
        );
      })}
    </div>
  );
}
