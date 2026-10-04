import { ArrowSquareOutIcon } from "@phosphor-icons/react";
import { CASES, SECTION_IDS, SRT_BRIEF, SUBTITLES_ROUTE } from "../../content/site.js";
import { CaseDiagram } from "../cases/CaseDiagram.jsx";
import { CoreItem } from "../core/CoreItem.jsx";

// AI-NOTE: 메인 03 핵심 구현의 하위 항목 03 Voice to SRT 요약. 처리 도식은 사례 03 의 diagram(원본 오디오 → … → 사람 승인 → SRT)을
// CaseDiagram 으로 그대로 보여 주고, 시간·AI·사람의 경계만 세 줄로 덧붙인다. 상세(/subtitles)는 새 탭.
// 예시 데이터·단계 모델(content/subtitles.js, subtitles/model.js)과 음성 인식·네트워크·오디오 처리는 메인 번들에 넣지 않는다.
const DIAGRAM = CASES.find((item) => item.id === "case-subtitles").diagram;

export function SubtitlesBrief() {
  return (
    <CoreItem id={SECTION_IDS.subtitles} title={SRT_BRIEF.title} lede={SRT_BRIEF.lede}>
      <div className="srt-brief__body">
        <div className="srt-brief__stage">
          <CaseDiagram diagram={DIAGRAM} />
        </div>
        <div className="srt-brief__side">
          <dl className="sprite-brief__points">
            {SRT_BRIEF.points.map((point) => (
              <div key={point.label} className="sprite-brief__point">
                <dt>{point.label}</dt>
                <dd>{point.text}</dd>
              </div>
            ))}
          </dl>
          <a className="btn btn--primary sprite-brief__link" href={SUBTITLES_ROUTE} target="_blank" rel="noopener noreferrer">
            {SRT_BRIEF.linkLabel}
            <ArrowSquareOutIcon size={18} aria-hidden="true" />
            <span className="sr-only">{SRT_BRIEF.linkHint}</span>
          </a>
        </div>
      </div>
    </CoreItem>
  );
}
