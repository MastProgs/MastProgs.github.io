import { CORE } from "../../content/site.js";

// AI-NOTE: 03 핵심 구현 하위 항목의 공통 틀(앵커 article + 번호·h3 제목·한 줄 소개). 번호와 순서는 CORE.items 에서만 정한다.
// 각 요약(WorkflowSummary·SpriteBrief·SubtitlesBrief)은 이 틀 안에 자기 본문만 그린다. h2 는 묶음(CoreSection)에 하나만 있다.
export function CoreItem({ id, title, lede, children }) {
  const item = CORE.items.find((entry) => entry.id === id);
  const titleId = `${id}-title`;
  return (
    <article id={id} className="core-item" aria-labelledby={titleId}>
      <div className="core-item__head">
        <span className="core-item__index" aria-hidden="true">
          {CORE.index}.{item.index}
        </span>
        <h3 id={titleId} className="core-item__title">
          {title}
        </h3>
        {lede && <p className="core-item__lede">{lede}</p>}
      </div>
      {children}
    </article>
  );
}
