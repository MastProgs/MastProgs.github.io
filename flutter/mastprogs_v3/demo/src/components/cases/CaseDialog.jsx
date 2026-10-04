import { ArrowSquareOutIcon } from "@phosphor-icons/react";
import { SUBTITLES_ROUTE } from "../../content/site.js";
import { Modal } from "../Modal.jsx";
import { CaseDiagram } from "./CaseDiagram.jsx";

export const CASE_MEDIA_TRANSITION = "case-media";

// 사례 id → 상세 페이지 경로. 상세 페이지가 있는 사례만 대화상자 아래에 새 탭 링크를 둔다.
const DETAIL_ROUTES = Object.freeze({ "case-subtitles": SUBTITLES_ROUTE });

// AI-NOTE: 매체는 두 종류다. 원본 이미지(image)는 기존처럼 "원본 자료 · 정적 참고 이미지" 캡션으로 실제 근거를 보이고,
// 원본 화면 캡처가 없는 사례(mediaKind "diagram")는 처리 원리 도식으로 그리며 캡션도 도식이라고 밝힌다(원본 화면처럼 꾸미지 않음).
// 포커스 이동·Esc·배경 inert·포커스 복귀는 Modal 이 그대로 맡는다.
// showDetailLink: 상세 페이지 안에서 같은 사례를 열 때는 자기 자신으로 가는 링크를 숨긴다.
export function CaseDialog({ item, onClose, showDetailLink = true }) {
  const detailRoute = item && showDetailLink ? DETAIL_ROUTES[item.id] : null;
  return (
    <Modal open={item !== null} onClose={onClose} labelledBy="case-dialog-title" className="case-dialog" closeLabel="사례 닫기">
      {item && (
        <article className="case-detail">
          <header className="case-detail__head">
            <p className="case-detail__index">작업 사례 {item.index}</p>
            <h2 id="case-dialog-title" className="case-detail__title">{item.title}</h2>
            <p className="case-detail__summary">{item.summary}</p>
          </header>
          {item.mediaKind === "diagram" ? (
            <figure className="case-detail__media case-detail__media--diagram">
              <CaseDiagram diagram={item.diagram} style={{ viewTransitionName: CASE_MEDIA_TRANSITION }} />
              <figcaption>처리 원리 도식 · 원본 문서와 소스 기준</figcaption>
            </figure>
          ) : (
            <figure className={`case-detail__media case-detail__media--${item.fit}`}>
              <img
                src={item.image.src}
                width={item.image.width}
                height={item.image.height}
                alt={item.image.alt}
                style={{ viewTransitionName: CASE_MEDIA_TRANSITION }}
              />
              <figcaption>원본 자료 · 정적 참고 이미지</figcaption>
            </figure>
          )}
          <dl className="case-detail__facts">
            <div>
              <dt>문제</dt>
              <dd>{item.problem}</dd>
            </div>
            <div>
              <dt>내 역할</dt>
              <dd>
                <ul>
                  {item.role.map((line) => (
                    <li key={line}>{line}</li>
                  ))}
                </ul>
              </dd>
            </div>
            <div>
              <dt>근거</dt>
              <dd>{item.evidence}</dd>
            </div>
            {item.limits && (
              <div>
                <dt>한계</dt>
                <dd>{item.limits}</dd>
              </div>
            )}
          </dl>
          {detailRoute && item.detail && (
            <p className="case-detail__more">
              <a className="case-detail__link" href={detailRoute} target="_blank" rel="noopener noreferrer">
                {item.detail.label}
                <ArrowSquareOutIcon size={16} aria-hidden="true" />
                <span className="sr-only">(새 탭에서 열림)</span>
              </a>
            </p>
          )}
        </article>
      )}
    </Modal>
  );
}
