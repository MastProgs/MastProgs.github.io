import { useEffect, useRef } from "react";
import { STAGE } from "../../content/site.js";

const TONE_LABEL = { ok: "정상", fault: "결함", repair: "재작업" };

export function RunHistory({ items }) {
  const listRef = useRef(null);

  // 최신 항목이 아래에 쌓이므로, 내부 스크롤 영역만 맨 아래로 맞춘다(페이지 스크롤은 건드리지 않음).
  useEffect(() => {
    const list = listRef.current;
    if (list) list.scrollTop = list.scrollHeight;
  }, [items.length]);

  return (
    <div className="history">
      <h3 id="history-heading" className="stage-foot__heading">{STAGE.historyHeading}</h3>
      {items.length === 0 ? (
        <p className="history__empty">{STAGE.historyEmpty}</p>
      ) : (
        <ol ref={listRef} className="history__list" aria-labelledby="history-heading" tabIndex={0}>
          {items.map((item) => (
            <li key={item.id} className={`history__item history__item--${item.tone}`}>
              <span className="history__num" aria-hidden="true">{item.number}.</span>
              <span className="history__dot" aria-hidden="true" />
              <span className="history__text">
                {item.text}
                {item.tone !== "ok" && <span className="sr-only"> ({TONE_LABEL[item.tone]})</span>}
              </span>
            </li>
          ))}
        </ol>
      )}
    </div>
  );
}
