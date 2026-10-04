import { CORE, SECTION_IDS } from "../../content/site.js";
import { useRevealOnce } from "../../hooks/useRevealOnce.js";
import { SpriteBrief } from "../sprite/SpriteBrief.jsx";
import { SubtitlesBrief } from "../subtitles/SubtitlesBrief.jsx";
import { WorkflowSummary } from "../workflow/WorkflowSummary.jsx";

// AI-NOTE: 사용자 최신 지시("3 4 번이 별도로 있는데, 차라리 3번으로 핵심 구현 … 하위 항목으로 … srt 도 추가")로
// 예전 03 AgentWorkflow·04 스프라이트 섹션을 이 묶음 하나(#core, h2)로 합쳤다. 하위 순서: AgentWorkflow → Sprite → Voice to SRT.
// 세 항목은 탭·아코디언 없이 위에서 아래로 모두 보이고, 각자 #workflow·#sprite·#subtitles 앵커와 h3 를 가진다.
// 하위 목차는 이 섹션 안에만 있다(상위 NAV_LINKS 에는 "핵심 구현" 하나). 상세는 각 요약의 새 탭 링크가 연다.
export function CoreSection({ revealEnabled }) {
  const revealRef = useRevealOnce(revealEnabled);
  return (
    <section id={SECTION_IDS.core} className="core resume-section" aria-labelledby="core-title" ref={revealRef}>
      <div className="resume-section__head">
        <h2 id="core-title" className="section-title">
          <span className="section-title__index">{CORE.index}</span>
          <span>{CORE.title}</span>
        </h2>
        <p className="resume-section__lede">{CORE.lede}</p>
      </div>

      <nav className="core__nav" aria-label={CORE.navLabel}>
        <ol>
          {CORE.items.map((item) => (
            <li key={item.id}>
              <a href={`#${item.id}`}>
                <span className="core__nav-index">{item.index}</span>
                {item.label}
              </a>
            </li>
          ))}
        </ol>
      </nav>

      <div className="core__items">
        <WorkflowSummary />
        <SpriteBrief />
        <SubtitlesBrief />
      </div>
    </section>
  );
}
