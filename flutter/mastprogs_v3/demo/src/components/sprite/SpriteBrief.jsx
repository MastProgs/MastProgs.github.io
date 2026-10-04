import { ArrowSquareOutIcon } from "@phosphor-icons/react";
import meta from "../../content/pixel-assets.json";
import { SECTION_IDS, SPRITE_BRIEF, SPRITE_ROUTE } from "../../content/site.js";
import { useMediaQuery } from "../../hooks/useMediaQuery.js";
import { buildSpriteModel } from "../../pixel/sprite.js";
import { CoreItem } from "../core/CoreItem.jsx";

// AI-NOTE: 메인 스프라이트 요약(사용자 지시: 워크플로우 요약 다음. 전체 작업 화면은 /sprite 새 탭).
// (갱신) 예전 독립 04 섹션에서 03 핵심 구현의 하위 항목 02 로 옮겼다. #sprite 앵커는 그대로, 제목은 CoreItem 의 h3 다.
// 원본 GIF 세 개(걷기·달리기·공격)만 보여 준다. 메인에서는 레이어 합성·팔레트 대응·타이머를 돌리지 않으며
// (그 일은 /sprite 의 usePixelPreview 하나가 맡는다) 무거운 레이어 JSON 도 import 하지 않는다(pixel/assets.js 금지).
// 동작 줄이기 설정이면 같은 원본의 첫 프레임 PNG 정지 화면을 보여 준다.
const SPRITE = buildSpriteModel(meta);
const REDUCED_MOTION = "(prefers-reduced-motion: reduce)";

export function SpriteBrief() {
  const reduced = useMediaQuery(REDUCED_MOTION);

  return (
    <CoreItem id={SECTION_IDS.sprite} title={SPRITE_BRIEF.title} lede={SPRITE_BRIEF.lede}>
      <div className="sprite-brief__body">
        <ul className="sprite-brief__stage" aria-label={SPRITE_BRIEF.previewLabel}>
          {SPRITE.motions.map((motion) => (
            <li key={motion.id} className="sprite-brief__hero">
              <img
                src={reduced ? motion.frames[0].src : motion.gif}
                width={SPRITE.width}
                height={SPRITE.height}
                alt={`${SPRITE_BRIEF.previewLabel}: ${motion.label}`}
                loading="lazy"
                decoding="async"
              />
              <span className="sprite-brief__motion" aria-hidden="true">{motion.label}</span>
            </li>
          ))}
        </ul>

        <div className="sprite-brief__side">
          <dl className="sprite-brief__points">
            {SPRITE_BRIEF.points.map((point) => (
              <div key={point.label} className="sprite-brief__point">
                <dt>{point.label}</dt>
                <dd>{point.text}</dd>
              </div>
            ))}
          </dl>
          <a className="btn btn--primary sprite-brief__link" href={SPRITE_ROUTE} target="_blank" rel="noopener noreferrer">
            {SPRITE_BRIEF.linkLabel}
            <ArrowSquareOutIcon size={18} aria-hidden="true" />
            <span className="sr-only">{SPRITE_BRIEF.linkHint}</span>
          </a>
        </div>
      </div>
    </CoreItem>
  );
}
