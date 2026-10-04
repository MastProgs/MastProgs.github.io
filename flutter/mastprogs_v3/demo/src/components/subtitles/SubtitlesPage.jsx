import { useEffect, useState } from "react";
import { ArrowLeftIcon, ArrowsOutSimpleIcon, CloudIcon, CpuIcon, LockIcon } from "@phosphor-icons/react";
import {
  SUBTITLE_BOUNDARY,
  SUBTITLE_EDITOR,
  SUBTITLE_PIPELINE,
  SUBTITLE_STRUCTURE,
  SUBTITLE_USES,
  SUBTITLES_PAGE,
} from "../../content/subtitles.js";
import { CASES } from "../../content/site.js";
import { ThemeToggle } from "../ThemeToggle.jsx";
import { CaseDialog } from "../cases/CaseDialog.jsx";
import { SubtitleWalkthrough } from "./SubtitleWalkthrough.jsx";

const SUBTITLE_CASE = CASES.find((item) => item.id === "case-subtitles");
const pad = (n) => String(n).padStart(2, "0");

// AI-NOTE: /subtitles 상세 페이지(Voice to SRT). App.jsx 가 lazy 로 불러온다(내용·예시 데이터는 이 청크에만).
// 머리글은 /workflow·/sprite 와 같은 모양(이력서로 돌아가기 + 테마 전환), h1 하나, 같은 ThemeProvider.
// 메인 섹션·내비게이션에는 없고 사례 03 대화상자의 '처리 과정 자세히 보기'(새 탭)로 들어온다(사용자: 사례 항목 + 상세면 충분).
// 순서: 소개(개발 중·구현된 기능) → 처리 흐름(원리) → 과정 따라가기(예시) → AI 경계 → 편집기 → 구성·데이터 위치 → 쓰임.
// 원본 앱 화면 캡처는 없으므로 만들지 않는다. 도식은 아이콘 + 의미 있는 목록이다.
export function SubtitlesPage() {
  const [caseOpen, setCaseOpen] = useState(false);
  const copy = SUBTITLES_PAGE;

  useEffect(() => {
    const previous = document.title;
    document.title = `${copy.eyebrow} · 김형준`;
    return () => {
      document.title = previous;
    };
  }, [copy.eyebrow]);

  return (
    <div className="shell wfd-shell srt-shell" id="top">
      <header className="wfd-top">
        <a className="wfd-top__back" href="/">
          <ArrowLeftIcon size={18} aria-hidden="true" />
          {copy.backLabel}
        </a>
        <ThemeToggle compact />
      </header>

      <main className="wfd-page">
        <section className="wfd-intro" aria-labelledby="srt-page-title">
          <p className="wfd-intro__eyebrow">{copy.eyebrow}</p>
          <h1 id="srt-page-title" className="wfd-intro__title">{copy.title}</h1>
          <p className="srt-status">{copy.status}</p>
          <div className="wfd-intro__body">
            {copy.intro.map((line) => (
              <p key={line}>{line}</p>
            ))}
          </div>
          <button type="button" className="srt-btn srt-intro__case" onClick={() => setCaseOpen(true)} aria-haspopup="dialog">
            {copy.openCase}
            <ArrowsOutSimpleIcon size={16} aria-hidden="true" />
          </button>
        </section>

        <section className="srt-section" aria-labelledby="srt-flow-title">
          <h2 id="srt-flow-title" className="srt-section__title">{copy.sections.flow}</h2>
          <ol className="srt-flow">
            {SUBTITLE_PIPELINE.map((step, index) => (
              <li key={step.id} className={`srt-flow__step is-${step.where === "외부 CLI" ? "external" : step.where === "사람" ? "human" : "local"}`}>
                <p className="srt-flow__head">
                  <span className="srt-flow__num">{pad(index + 1)}</span>
                  <span className="srt-flow__label">{step.label}</span>
                  <span className="srt-flow__where">{step.where}</span>
                </p>
                <p className="srt-flow__text">{step.text}</p>
              </li>
            ))}
          </ol>
        </section>

        <section className="srt-section" aria-labelledby="srt-walk-title">
          <h2 id="srt-walk-title" className="srt-section__title">{copy.sections.walkthrough}</h2>
          <SubtitleWalkthrough />
        </section>

        <section className="srt-section" aria-labelledby="srt-boundary-title">
          <h2 id="srt-boundary-title" className="srt-section__title">{copy.sections.boundary}</h2>
          <div className="srt-boundary">
            {[SUBTITLE_BOUNDARY.does, SUBTITLE_BOUNDARY.doesNot].map((group, index) => (
              <div key={group.title} className={`srt-boundary__col${index === 1 ? " is-not" : ""}`}>
                <h3 className="srt-boundary__title">{group.title}</h3>
                <ul>
                  {group.items.map((item) => (
                    <li key={item}>{item}</li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
          <p className="srt-fields">
            <span className="srt-dim">{SUBTITLE_BOUNDARY.proposalNote}</span>
            {SUBTITLE_BOUNDARY.proposalFields.map((field) => (
              <code key={field}>{field}</code>
            ))}
          </p>
        </section>

        <section className="srt-section" aria-labelledby="srt-editor-title">
          <h2 id="srt-editor-title" className="srt-section__title">{copy.sections.editor}</h2>
          <dl className="srt-grid">
            {SUBTITLE_EDITOR.map((item) => (
              <div key={item.label}>
                <dt>{item.label}</dt>
                <dd>{item.text}</dd>
              </div>
            ))}
          </dl>
        </section>

        <section className="srt-section" aria-labelledby="srt-structure-title">
          <h2 id="srt-structure-title" className="srt-section__title">{copy.sections.structure}</h2>
          <ol className="srt-parts">
            {SUBTITLE_STRUCTURE.parts.map((part) => (
              <li key={part.label}>
                <CpuIcon size={18} aria-hidden="true" />
                <strong>{part.label}</strong>
                <span>{part.text}</span>
              </li>
            ))}
          </ol>
          <div className="srt-boundary">
            <div className="srt-boundary__col">
              <h3 className="srt-boundary__title">
                <LockIcon size={18} aria-hidden="true" />
                {SUBTITLE_STRUCTURE.local.title}
              </h3>
              <ul>
                {SUBTITLE_STRUCTURE.local.items.map((item) => (
                  <li key={item}>{item}</li>
                ))}
              </ul>
            </div>
            <div className="srt-boundary__col is-external">
              <h3 className="srt-boundary__title">
                <CloudIcon size={18} aria-hidden="true" />
                {SUBTITLE_STRUCTURE.external.title}
              </h3>
              <ul>
                {SUBTITLE_STRUCTURE.external.items.map((item) => (
                  <li key={item}>{item}</li>
                ))}
              </ul>
            </div>
          </div>
        </section>

        <section className="srt-section" aria-labelledby="srt-uses-title">
          <h2 id="srt-uses-title" className="srt-section__title">{copy.sections.uses}</h2>
          <dl className="srt-grid srt-grid--uses">
            {SUBTITLE_USES.map((item) => (
              <div key={item.label}>
                <dt>{item.label}</dt>
                <dd>{item.text}</dd>
              </div>
            ))}
          </dl>
        </section>
      </main>

      <CaseDialog item={caseOpen ? SUBTITLE_CASE : null} onClose={() => setCaseOpen(false)} showDetailLink={false} />
    </div>
  );
}
