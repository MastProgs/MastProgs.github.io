import { STAGE } from "../../content/site.js";

// 탭 패널. 7단계 타일이 선택되면 그 탭이 이름이 되고, 직접 처리 노드·병합 게이트처럼 탭이 아닌 실행 노드면 제목이 이름이 된다.
export function PhaseDetail({ title, lines, tabId, onFollow }) {
  return (
    <div
      id="phase-panel"
      className="phase-detail"
      role="tabpanel"
      aria-labelledby={tabId ?? "phase-panel-title"}
      tabIndex={0}
    >
      <div className="phase-detail__head">
        <h3 id="phase-panel-title" className="stage-foot__heading">
          {STAGE.detailHeading} · {title}
        </h3>
        {onFollow && (
          <button type="button" className="phase-detail__follow" onClick={onFollow}>
            {STAGE.followCursor}
          </button>
        )}
      </div>
      <ul className="phase-detail__lines">
        {lines.map((line, index) => (
          <li key={`${index}-${line}`}>{line}</li>
        ))}
      </ul>
    </div>
  );
}
