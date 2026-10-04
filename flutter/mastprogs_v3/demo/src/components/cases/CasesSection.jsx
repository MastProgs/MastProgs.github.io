import { useCallback, useRef, useState } from "react";
import { ArrowsOutSimpleIcon, CaretLeftIcon, CaretRightIcon } from "@phosphor-icons/react";
import { CASES, CASES_RAIL, SECTION_IDS } from "../../content/site.js";
import { useCaseRail } from "../../hooks/useCaseRail.js";
import { useRevealOnce } from "../../hooks/useRevealOnce.js";
import { stepIndex } from "../../lib/rail.js";
import { runViewTransition } from "../../lib/motion.js";
import { CaseDiagram } from "./CaseDiagram.jsx";
import { CaseDialog, CASE_MEDIA_TRANSITION } from "./CaseDialog.jsx";

// AI-NOTE: 픽셀 라이브 미리보기는 사용자 최신 지시로 이 레일에서 빼서 /sprite 페이지(SpritePage, 별도 청크)로 옮겼다.
// Hero Pixel Studio 카드(사례 02, id case-pixel)와 원본 편집기 화면 캡처는 근거로 이 레일에 그대로 남는다.
// AI-NOTE: 사용자 최신 지시로 사례 순서는 01 AgentWorkflow → 02 Hero Pixel Studio → 03 Voice to SRT → 04 KETI → 05 현장 요청 처리.
// id 는 그대로(새 사례만 case-subtitles). 카드 매체는 원본 이미지(image) 또는 처리 원리 도식(mediaKind "diagram") 두 가지다.
// 도식 사례는 원본 앱 화면 캡처가 없어서 CSS·의미 구조 도식으로 그리며, 원본 이미지 카드는 기존 근거·캡션을 그대로 쓴다.
const pad = (value) => String(value).padStart(2, "0");

// AI-NOTE: 카드 이미지와 대화상자 이미지가 같은 view-transition-name 을 동시에 갖지 않도록,
// 열 때는 전환 직전 카드에 이름을 붙였다가 갱신 콜백에서 떼고, 닫을 때는 반대로 처리한다.
export function CasesSection({ revealEnabled }) {
  const [openId, setOpenId] = useState(null);
  const openIdRef = useRef(null);
  openIdRef.current = openId;
  const mediaRefs = useRef(new Map());
  const cardRefs = useRef([]);
  const revealRef = useRevealOnce(revealEnabled);
  const { railRef, setItemRef, active, scrollToIndex } = useCaseRail(CASES.length);

  const setMediaRef = (id, node) => {
    if (node) mediaRefs.current.set(id, node);
    else mediaRefs.current.delete(id);
  };

  const setMediaName = (id, name) => {
    const node = mediaRefs.current.get(id);
    if (node) node.style.viewTransitionName = name;
  };

  const openCase = useCallback((id) => {
    runViewTransition(() => setOpenId(id), {
      onBefore: () => setMediaName(id, CASE_MEDIA_TRANSITION),
      onDuring: () => setMediaName(id, ""),
    });
  }, []);

  const closeCase = useCallback(() => {
    const id = openIdRef.current;
    if (id === null) return;
    runViewTransition(() => setOpenId(null), {
      onDuring: () => setMediaName(id, CASE_MEDIA_TRANSITION),
      onFinish: () => setMediaName(id, ""),
    });
  }, []);

  // AI-NOTE: 목차 링크는 JS 가 있으면 레일 안에서만 해당 카드를 가운데로 옮기고 카드에 포커스를 준다(페이지는 필요한 만큼만 이동).
  // JS 가 없으면 href 앵커가 그대로 동작한다.
  const jumpTo = (event, index) => {
    event.preventDefault();
    railRef.current?.scrollIntoView({ block: "nearest" });
    scrollToIndex(index);
    cardRefs.current[index]?.focus({ preventScroll: true });
  };

  // 키보드로 카드에 들어오면 그 카드를 가운데로 맞춘다. 마우스 클릭은 대화상자 전환과 겹치지 않게 제외한다.
  const handleCardFocus = (event, index) => {
    if (event.currentTarget.matches(":focus-visible") && index !== active) scrollToIndex(index);
  };

  const step = (delta) => {
    const target = stepIndex(active, delta, CASES.length);
    if (target !== null) scrollToIndex(target);
  };
  const prevDisabled = stepIndex(active, -1, CASES.length) === null;
  const nextDisabled = stepIndex(active, 1, CASES.length) === null;

  const openCaseData = CASES.find((item) => item.id === openId) ?? null;

  return (
    <section id={SECTION_IDS.cases} className="cases" aria-labelledby="cases-title" ref={revealRef}>
      <div className="cases__head">
        <h2 id="cases-title" className="section-title">
          <span className="section-title__index">{CASES_RAIL.index}</span>
          <span>{CASES_RAIL.heading}</span>
        </h2>
        <nav className="cases__index" aria-label={CASES_RAIL.indexLabel}>
          <ul>
            {CASES.map((item, index) => (
              <li key={item.id}>
                <a
                  href={`#${item.id}`}
                  className={index === active ? "is-active" : undefined}
                  aria-current={index === active ? "true" : undefined}
                  onClick={(event) => jumpTo(event, index)}
                >
                  <span className="cases__index-num">{item.index}</span>
                  {item.title}
                </a>
              </li>
            ))}
          </ul>
        </nav>
      </div>

      <div className="rail-controls">
        <p className="rail-controls__count" aria-hidden="true">
          <span>{pad(active + 1)}</span> / {pad(CASES.length)}
        </p>
        {/* AI-NOTE: 끝에서 비활성화될 때 포커스를 잃지 않도록 disabled 대신 aria-disabled 를 쓴다(전송 막대와 같은 규칙). */}
        <button
          type="button"
          className="rail-controls__btn"
          aria-label={CASES_RAIL.prev}
          title={CASES_RAIL.prev}
          aria-disabled={prevDisabled}
          onClick={prevDisabled ? undefined : () => step(-1)}
        >
          <CaretLeftIcon size={20} aria-hidden="true" />
        </button>
        <button
          type="button"
          className="rail-controls__btn"
          aria-label={CASES_RAIL.next}
          title={CASES_RAIL.next}
          aria-disabled={nextDisabled}
          onClick={nextDisabled ? undefined : () => step(1)}
        >
          <CaretRightIcon size={20} aria-hidden="true" />
        </button>
      </div>

      <ul className="case-list" ref={railRef} aria-label={CASES_RAIL.railLabel}>
        {CASES.map((item, index) => (
          <li
            key={item.id}
            id={item.id}
            ref={setItemRef(index)}
            className={`case-item${index === active ? " is-active" : ""}`}
            style={{ "--i": index }}
          >
            <button
              ref={(node) => {
                cardRefs.current[index] = node;
              }}
              type="button"
              className="case-card"
              aria-haspopup="dialog"
              onClick={() => openCase(item.id)}
              onFocus={(event) => handleCardFocus(event, index)}
            >
              <span className={`case-card__media case-card__media--${item.mediaKind === "diagram" ? "diagram" : item.fit}`}>
                {item.mediaKind === "diagram" ? (
                  <CaseDiagram ref={(node) => setMediaRef(item.id, node)} diagram={item.diagram} compact />
                ) : (
                  <img
                    ref={(node) => setMediaRef(item.id, node)}
                    src={item.image.src}
                    width={item.image.width}
                    height={item.image.height}
                    alt={item.image.alt}
                    loading="lazy"
                    decoding="async"
                  />
                )}
              </span>
              <span className="case-card__body">
                <span className="case-card__index">{item.index}</span>
                <span className="case-card__title">{item.title}</span>
                <span className="case-card__summary">{item.summary}</span>
                <span className="case-card__tags">
                  {item.tags.map((tag) => (
                    <span key={tag} className="tag">{tag}</span>
                  ))}
                </span>
                <span className="case-card__more">
                  {CASES_RAIL.more}
                  <ArrowsOutSimpleIcon size={16} aria-hidden="true" />
                </span>
              </span>
            </button>
          </li>
        ))}
      </ul>

      <CaseDialog item={openCaseData} onClose={closeCase} />
    </section>
  );
}
