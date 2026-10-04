import { forwardRef } from "react";
import { ChatsCircleIcon, MicrophoneIcon, RulerIcon, ScissorsIcon, UserCheckIcon, WaveformIcon } from "@phosphor-icons/react";

// 도식 단계 id → Phosphor 아이콘. 장식 SVG·새 그림 없이 라이브러리 아이콘만 쓴다.
const STEP_ICONS = Object.freeze({
  audio: WaveformIcon,
  asr: MicrophoneIcon,
  align: RulerIcon,
  split: ScissorsIcon,
  review: ChatsCircleIcon,
  human: UserCheckIcon,
});

// AI-NOTE: 원본 앱 화면 캡처가 없는 사례(Voice to SRT)의 매체. 실제 화면처럼 보이게 꾸미지 않고, 처리 순서를 의미 있는 목록(ol)으로 그린다.
// 사례 카드(compact)와 대화상자가 같은 데이터를 쓰며, 대화상자 전환(view-transition-name)은 바깥 요소에 붙는다.
export const CaseDiagram = forwardRef(function CaseDiagram({ diagram, compact = false, style }, ref) {
  return (
    // 카드 안(compact)에서는 버튼 이름이 길어지지 않게 숨기고, 대화상자에서는 단계 목록을 그대로 읽게 한다.
    <div ref={ref} className={`case-diagram${compact ? " case-diagram--compact" : ""}`} aria-hidden={compact ? "true" : undefined} style={style}>
      <ol className="case-diagram__steps" aria-label={compact ? undefined : diagram.label}>
        {diagram.steps.map((step, index) => {
          const Icon = STEP_ICONS[step.id] ?? WaveformIcon;
          return (
            <li key={step.id} className="case-diagram__step">
              <span className="case-diagram__num">{String(index + 1).padStart(2, "0")}</span>
              <Icon className="case-diagram__icon" size={compact ? 18 : 22} aria-hidden="true" />
              <span className="case-diagram__label">{step.label}</span>
              {!compact && <span className="case-diagram__note">{step.note}</span>}
            </li>
          );
        })}
      </ol>
    </div>
  );
});
