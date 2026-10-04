import { GraduationCapIcon } from "@phosphor-icons/react";
import { SKILLS } from "../../content/resume.js";
import { SECTION_IDS } from "../../content/site.js";
import { useRevealOnce } from "../../hooks/useRevealOnce.js";

const toDateTime = (period) => period.replace(".", "-");

// 05 학력·역량: 학력 목록과 영역별 기술 목록. 숙련도 점수·막대 없이 이름만 나열한다.
export function SkillsSection({ revealEnabled }) {
  const revealRef = useRevealOnce(revealEnabled);
  return (
    <section id={SECTION_IDS.skills} className="skills resume-section" aria-labelledby="skills-title" ref={revealRef}>
      <div className="resume-section__head">
        <h2 id="skills-title" className="section-title">
          <span className="section-title__index">{SKILLS.index}</span>
          <span>{SKILLS.heading}</span>
        </h2>
      </div>
      <div className="skills__grid">
        <div className="skills__edu">
          <h3 id="education-title" className="profile__block-title">{SKILLS.educationHeading}</h3>
          <ol className="edu-list" aria-labelledby="education-title">
            {SKILLS.education.map((item) => (
              <li key={item.id} className="edu-item">
                <GraduationCapIcon className="edu-item__icon" size={20} aria-hidden="true" />
                <time className="edu-item__date" dateTime={toDateTime(item.date)}>{item.date}</time>
                <span className="edu-item__text">
                  <span className="edu-item__school">{item.school}</span>
                  <span className="edu-item__major">
                    {item.major} · {item.degree}
                  </span>
                </span>
              </li>
            ))}
          </ol>
        </div>
        <div className="skills__stack">
          <h3 id="stack-title" className="profile__block-title">{SKILLS.skillsHeading}</h3>
          <dl className="skill-groups" aria-labelledby="stack-title">
            {SKILLS.groups.map((group) => (
              <div key={group.id} className="skill-groups__row">
                <dt>{group.label}</dt>
                <dd>
                  <ul className="skill-chips">
                    {group.items.map((item) => (
                      <li key={item} className="tag">{item}</li>
                    ))}
                  </ul>
                </dd>
              </div>
            ))}
          </dl>
        </div>
      </div>
    </section>
  );
}
