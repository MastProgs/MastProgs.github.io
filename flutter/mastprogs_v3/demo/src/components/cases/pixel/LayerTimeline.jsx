import { useId } from "react";
import { CaretLeftIcon, CaretRightIcon, EyeIcon, EyeSlashIcon, PauseIcon, PlayIcon } from "@phosphor-icons/react";
import { LAYER_LABELS, PIXEL_COPY } from "../../../content/pixelStudio.js";
import { celState } from "../../../pixel/layers.js";

// AI-NOTE: Aseprite 식 "레이어 × 프레임" 표. 행 = 원본 레이어 20개(위가 앞, Aseprite 처럼 위에서부터), 열 = 현재 모션의 프레임.
// 칸은 실제 셀 데이터에서 나온다: ■ 새 셀(직전 프레임과 위치·픽셀이 다름), □ 직전과 같은 셀, 빈칸 = 셀 없음.
// 현재 열(재생 헤드)은 재생 커서 하나를 그대로 따른다. 칸을 누르면 그 레이어를 고르고 그 프레임에서 멈춘다(포인터용 보조,
// 키보드는 위 프레임 번호 버튼과 행의 레이어 이름 버튼으로 같은 일을 한다). 표는 자기 영역 안에서만 스크롤한다.
// AI-NOTE: 훅 반환 객체(view) 전체를 받지 않는다(장시간 재생 시 React 개발 타이밍 항목이 큰 데이터를 복제하던 원인).
// 정적 모델·단계 배열 참조와 현재 단계 번호(cursor), 작은 표시 배열만 받는다.
export function LayerTimeline({ model, steps, cursor, frameIndex, loop, playing, selectedLayer, visibility, isolated, effectiveVisibility, motionLabel, actions }) {
  const sliderId = useId();
  const rows = [...model.layers].reverse();
  const length = steps.length;
  const frame = model.frames[frameIndex];
  const previousStep = (step) => (step > 0 ? steps[step - 1] : loop ? steps[length - 1] : null);
  const atStart = !loop && cursor === 0;
  const atEnd = !loop && cursor === length - 1;
  const position = `${motionLabel} ${cursor + 1}/${length} · ${frame.ms}ms`;

  return (
    <div className="pixel-timeline">
      <div className="pixel-transport">
        <button type="button" className="pixel-btn" aria-label={PIXEL_COPY.prevFrame} title={PIXEL_COPY.prevFrame} aria-disabled={atStart} onClick={() => !atStart && actions.stepFrame(-1)}>
          <CaretLeftIcon size={18} weight="bold" aria-hidden="true" />
        </button>
        <button type="button" className="pixel-btn" aria-label={playing ? PIXEL_COPY.pause : PIXEL_COPY.play} title={playing ? PIXEL_COPY.pause : PIXEL_COPY.play} onClick={actions.togglePlay}>
          {playing ?<PauseIcon size={18} weight="fill" aria-hidden="true" /> : <PlayIcon size={18} weight="fill" aria-hidden="true" />}
        </button>
        <button type="button" className="pixel-btn" aria-label={PIXEL_COPY.nextFrame} title={PIXEL_COPY.nextFrame} aria-disabled={atEnd} onClick={() => !atEnd && actions.stepFrame(1)}>
          <CaretRightIcon size={18} weight="bold" aria-hidden="true" />
        </button>
        <label htmlFor={sliderId} className="sr-only">
          {PIXEL_COPY.frameSlider}
        </label>
        <input
          id={sliderId}
          className="pixel-range pixel-transport__slider"
          type="range"
          min="0"
          max={length - 1}
          step="1"
          value={cursor}
          aria-valuetext={position}
          onChange={(event) => actions.selectFrame(Number(event.target.value))}
        />
        <span className="pixel-transport__pos">
          {cursor + 1}/{length} · {frame.ms}ms · {frame.key}
        </span>
      </div>

      <div className="pixel-timeline__scroll" role="region" aria-label={PIXEL_COPY.timeline} tabIndex={0}>
        <div className="pixel-timeline__grid" style={{ "--tl-cols": length }}>
          <div className="pixel-timeline__corner">{PIXEL_COPY.layerColumn}</div>
          {steps.map((_, step) => (
            <button
              key={step}
              type="button"
              className={`pixel-timeline__frame${step === cursor ? " is-current" : ""}`}
              aria-pressed={step === cursor}
              aria-label={`${motionLabel} ${step + 1}`}
              onClick={() => actions.selectFrame(step)}
            >
              {step + 1}
            </button>
          ))}

          {rows.map((layer) => {
            const label = LAYER_LABELS[layer.name] ?? layer.name;
            const shown = effectiveVisibility[layer.index];
            const selected = layer.index === selectedLayer;
            const rowClass = `${selected ? " is-selected" : ""}${shown ? "" : " is-hidden"}${layer.isComposite ? " is-ref" : ""}`;
            return [
              <div key={`${layer.name}-head`} className={`pixel-timeline__layer${rowClass}`}>
                {layer.isComposite ? (
                  <span className="pixel-timeline__eye is-static" aria-hidden="true">
                    <EyeSlashIcon size={16} />
                  </span>
                ) : (
                  <button
                    type="button"
                    className="pixel-timeline__eye"
                    aria-pressed={visibility[layer.index]}
                    aria-label={`${label} ${visibility[layer.index] ? PIXEL_COPY.hideLayer : PIXEL_COPY.showLayer}`}
                    title={`${label} ${visibility[layer.index] ? PIXEL_COPY.hideLayer : PIXEL_COPY.showLayer}`}
                    disabled={isolated}
                    onClick={() => actions.toggleLayer(layer.index)}
                  >
                    {visibility[layer.index] ? <EyeIcon size={16} aria-hidden="true" /> : <EyeSlashIcon size={16} aria-hidden="true" />}
                  </button>
                )}
                {layer.isComposite ? (
                  <span className="pixel-timeline__name">{PIXEL_COPY.compositeRow}</span>
                ) : (
                  <button type="button" className="pixel-timeline__name" aria-pressed={selected} onClick={() => actions.selectLayer(layer.index)}>
                    {label}
                    <span className="pixel-timeline__id">{layer.name}</span>
                  </button>
                )}
              </div>,
              ...steps.map((frameIndex, step) => {
                const state = celState(model, frameIndex, layer.index, previousStep(step));
                return (
                  <span
                    key={`${layer.name}-${step}`}
                    className={`pixel-timeline__cel is-${state}${step === cursor ? " is-current" : ""}${rowClass}`}
                    aria-hidden="true"
                    onClick={layer.isComposite ? undefined : () => actions.selectCell(layer.index, step)}
                  />
                );
              }),
            ];
          })}
        </div>
      </div>
      <p className="pixel-controls__hint">{PIXEL_COPY.timelineLegend}</p>
    </div>
  );
}
