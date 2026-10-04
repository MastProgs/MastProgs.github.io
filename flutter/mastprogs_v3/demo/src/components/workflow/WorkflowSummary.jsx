import { ArrowBendUpLeftIcon, ArrowSquareOutIcon, GitMergeIcon, RobotIcon, UserIcon } from "@phosphor-icons/react";
import { SECTION_IDS, STAGE, WORKFLOW_SUMMARY } from "../../content/site.js";
import { DETAIL_ROUTE } from "../../content/workflowDetail.js";
import { CoreItem } from "../core/CoreItem.jsx";

// AI-NOTE: 사용자 요청("메인 이력서에는 워크플로우를 짧게 설명하고, 자세한 내용은 새 페이지/탭으로")에 따라
// 메인에는 전체 WorkflowStage 대신 이 요약만 둔다. 상세는 /workflow 를 새 탭(noopener noreferrer)으로 연다.
// (갱신) 이제 독립 03 섹션이 아니라 03 핵심 구현(CoreSection)의 하위 항목 01 이다. #workflow 앵커와 STAGE.title 은 그대로이고,
// 제목은 CoreItem 의 h3, 크림색 판(.stage)은 흐름·링크 본문에만 쓴다. 등장 애니메이션은 묶음 섹션이 맡는다.
export function WorkflowSummary() {
  return (
    <CoreItem id={SECTION_IDS.workflow} title={STAGE.title}>
      <div className="stage wf-summary">
        <ol className="wf-summary__flow">
          <li className="wf-summary__step">
            <span className="wf-summary__icons" aria-hidden="true">
              <UserIcon size={22} />
              <RobotIcon size={22} />
            </span>
            <span className="wf-summary__label">{WORKFLOW_SUMMARY.steps[0].label}</span>
            <span className="wf-summary__text">{WORKFLOW_SUMMARY.steps[0].text}</span>
          </li>
          <li className="wf-summary__step wf-summary__step--lanes">
            <span className="wf-summary__label">{WORKFLOW_SUMMARY.steps[1].label}</span>
            <span className="wf-summary__text">{WORKFLOW_SUMMARY.steps[1].text}</span>
            <span className="wf-summary__lanes" aria-hidden="true">
              {["A", "B", "C"].map((key) => (
                <span key={key} className="wf-summary__lane">
                  <b>{key}</b>
                  <span>기획 → 검수 → 개발 → 검수 → QA</span>
                </span>
              ))}
            </span>
            <span className="wf-summary__return">
              <ArrowBendUpLeftIcon size={16} aria-hidden="true" />
              {WORKFLOW_SUMMARY.returnNote}
            </span>
          </li>
          <li className="wf-summary__step">
            <span className="wf-summary__icons" aria-hidden="true">
              <GitMergeIcon size={22} />
            </span>
            <span className="wf-summary__label">{WORKFLOW_SUMMARY.steps[2].label}</span>
            <span className="wf-summary__text">{WORKFLOW_SUMMARY.steps[2].text}</span>
          </li>
        </ol>

        <div className="wf-summary__foot">
          <p className="wf-summary__human">{WORKFLOW_SUMMARY.humanNote}</p>
          <a className="btn btn--dark" href={DETAIL_ROUTE} target="_blank" rel="noopener noreferrer">
            {WORKFLOW_SUMMARY.linkLabel}
            <ArrowSquareOutIcon size={18} aria-hidden="true" />
            <span className="sr-only">{WORKFLOW_SUMMARY.linkHint}</span>
          </a>
        </div>
      </div>
    </CoreItem>
  );
}
