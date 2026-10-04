import { CAREER, PRESENT_LABEL, isCurrentEntry } from "../../content/resume.js";
import { SECTION_IDS } from "../../content/site.js";
import { useRevealOnce } from "../../hooks/useRevealOnce.js";

const toDateTime = (period) => period.replace(".", "-");

// 05 회사 경력: 최신순 세로 색인. 회사·기간·역할·업무를 모두 펼쳐 둔다(접기 없음).
// 왼쪽 세로선과 점은 순서를 나타내는 UI 연결선이며, 진행 중인 항목만 주황 점으로 표시한다.
export function CareerSection({ revealEnabled }) {
  const revealRef = useRevealOnce(revealEnabled);
  return (
    <section id={SECTION_IDS.career} className="career resume-section" aria-labelledby="career-title" ref={revealRef}>
      <div className="resume-section__head">
        <h2 id="career-title" className="section-title">
          <span className="section-title__index">{CAREER.index}</span>
          <span>{CAREER.heading}</span>
        </h2>
        <p className="resume-section__lede">{CAREER.lede}</p>
      </div>
      <ol className="career-list">
        {CAREER.entries.map((entry, index) => {
          const current = isCurrentEntry(entry);
          return (
            <li key={entry.id} className={`career-item${current ? " is-current" : ""}`} style={{ "--i": index }}>
              <p className="career-item__period">
                <time dateTime={toDateTime(entry.start)}>{entry.start}</time>
                <span aria-hidden="true"> – </span>
                <span className="sr-only"> 부터 </span>
                {current ? <span>{PRESENT_LABEL}</span> : <time dateTime={toDateTime(entry.end)}>{entry.end}</time>}
                {current && <span className="career-item__badge">{CAREER.currentBadge}</span>}
              </p>
              <div className="career-item__head">
                <h3 className="career-item__company">{entry.company}</h3>
                <p className="career-item__role">{entry.role}</p>
                {entry.note && <p className="career-item__note">{entry.note}</p>}
              </div>
              <div className="career-item__body">
                <ul className="career-item__duties">
                  {entry.duties.map((duty) => (
                    <li key={duty}>{duty}</li>
                  ))}
                </ul>
                <ul className="career-item__tags" aria-label={`${entry.company} 관련 기술·영역`}>
                  {entry.tags.map((tag) => (
                    <li key={tag} className="tag">{tag}</li>
                  ))}
                </ul>
              </div>
            </li>
          );
        })}
      </ol>
    </section>
  );
}
