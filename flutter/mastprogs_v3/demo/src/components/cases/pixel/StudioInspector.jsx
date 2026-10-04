import { useId } from "react";
import { ArrowCounterClockwiseIcon } from "@phosphor-icons/react";
import { LAYER_LABELS, PIXEL_COPY } from "../../../content/pixelStudio.js";
import { celBounds } from "../../../pixel/layers.js";
import { ONION_TINT } from "../../../pixel/timeline.js";
import { PixelCanvas } from "./PixelCanvas.jsx";

const rgb = ([r, g, b]) => `rgb(${r} ${g} ${b})`;

function Switch({ checked, onToggle, children }) {
  return (
    <button type="button" role="switch" aria-checked={checked} className="pixel-switch" onClick={onToggle}>
      <span className="pixel-switch__track" aria-hidden="true">
        <span className="pixel-switch__knob" />
      </span>
      {children}
    </button>
  );
}

// 공통 캔버스 위 기준선(원본 pivotX·soleRow). 두 비교 화면이 같은 기준선을 쓴다.
function GuideMarks({ guides, width, height }) {
  return (
    <>
      <span className="pixel-guide pixel-guide--v" style={{ left: `${((guides.pivotX + 0.5) / width) * 100}%` }} aria-hidden="true" />
      <span className="pixel-guide pixel-guide--h" style={{ top: `${((guides.soleRow + 1) / height) * 100}%` }} aria-hidden="true" />
    </>
  );
}

// AI-NOTE: 같은 프레임 커서를 쓰는 보조 화면들. 선택 레이어의 실제 셀만 따로 그리고(같은 색 설정), 어니언·기준선을 켜고 끄며,
// 원본처럼 공통 기준점에 둔 결과와 "프레임마다 실루엣을 잘라 가운데 맞춘" 결과를 나란히 보여 준다.
// 오른쪽은 실제 프레임 픽셀을 실제 경계 상자로 옮긴 것이라 이동량(dx, dy)은 데이터에서 나온 값이다.
// AI-NOTE: 훅 반환 객체(view) 전체나 RGBA 배열을 받지 않는다. 정적 모델 참조·숫자·문자열 키·안정된 paint 접근자만 받는다.
export function StudioInspector({
  model,
  frameIndex,
  selectedLayer,
  isolated,
  onionOn,
  onionOpacity,
  guidesOn,
  guides,
  neighbors,
  centerShift,
  imageSize,
  frameKeys,
  paint,
  actions,
}) {
  const opacityId = useId();
  const layer = model.layers[selectedLayer];
  const label = LAYER_LABELS[layer.name] ?? layer.name;
  const bounds = celBounds(model, frameIndex, selectedLayer);
  const { width, height } = imageSize;
  const stepLabel = (step) => (step === null ? PIXEL_COPY.onionNone : `${step + 1}`);

  return (
    <div className="pixel-inspector">
      <section className="pixel-card" aria-label={PIXEL_COPY.selectedLayer}>
        <p className="pixel-card__title">
          {PIXEL_COPY.selectedLayer} <strong>{label}</strong> <code>{layer.name}</code>
        </p>
        <div className="pixel-card__row">
          <div className="pixel-mini">
            <PixelCanvas paint={paint} kind="layer" frameKey={frameKeys.layer} width={width} height={height} className="pixel-mini__canvas" label={`${PIXEL_COPY.selectedLayer}: ${label}`} />
          </div>
          <div className="pixel-card__stack">
            <p className="pixel-card__meta">{bounds ? `x ${bounds.x} · y ${bounds.y} · ${bounds.w}×${bounds.h}` : PIXEL_COPY.noCel}</p>
            <Switch checked={isolated} onToggle={actions.toggleIsolate}>
              {PIXEL_COPY.isolate}
            </Switch>
            <button type="button" className="pixel-btn pixel-btn--chip" onClick={actions.resetLayers}>
              <ArrowCounterClockwiseIcon size={16} aria-hidden="true" />
              {PIXEL_COPY.showAll}
            </button>
          </div>
        </div>
      </section>

      <section className="pixel-card" aria-label={PIXEL_COPY.onion}>
        <Switch checked={onionOn} onToggle={actions.toggleOnion}>
          {PIXEL_COPY.onion}
        </Switch>
        <div className="pixel-ratio">
          <label htmlFor={opacityId} className="pixel-ratio__label">
            {PIXEL_COPY.onionOpacity}
          </label>
          <input
            id={opacityId}
            className="pixel-range"
            type="range"
            min="10"
            max="100"
            step="5"
            value={Math.round(onionOpacity * 100)}
            disabled={!onionOn}
            onChange={(event) => actions.setOnionOpacity(Number(event.target.value) / 100)}
          />
          <output htmlFor={opacityId} className="pixel-ratio__value">
            {Math.round(onionOpacity * 100)}%
          </output>
        </div>
        <p className="pixel-card__meta pixel-onion-legend">
          <span className="pixel-onion-legend__chip" style={{ background: rgb(ONION_TINT.prev) }} aria-hidden="true" />
          {PIXEL_COPY.onionPrev} {stepLabel(neighbors.prev)}
          <span className="pixel-onion-legend__chip" style={{ background: rgb(ONION_TINT.next) }} aria-hidden="true" />
          {PIXEL_COPY.onionNext} {stepLabel(neighbors.next)}
        </p>
      </section>

      <section className="pixel-card" aria-label={PIXEL_COPY.guides}>
        <Switch checked={guidesOn} onToggle={actions.toggleGuides}>
          {PIXEL_COPY.guides}
        </Switch>
        <p className="pixel-card__meta">
          {PIXEL_COPY.guideReadout} {model.pivotX} · {PIXEL_COPY.soleRow} {model.soleRow} · {PIXEL_COPY.crownRow} {model.crownRow}
        </p>
      </section>

      <section className="pixel-card pixel-card--wide" aria-label={PIXEL_COPY.centerTitle}>
        <p className="pixel-card__title">{PIXEL_COPY.centerTitle}</p>
        <div className="pixel-center">
          <figure className="pixel-center__item">
            <div className="pixel-mini">
              <PixelCanvas paint={paint} kind="current" frameKey={frameKeys.current} width={width} height={height} className="pixel-mini__canvas" label={PIXEL_COPY.centerCommon} />
              <GuideMarks guides={guides} width={width} height={height} />
            </div>
            <figcaption>{PIXEL_COPY.centerCommon}</figcaption>
          </figure>
          <figure className="pixel-center__item">
            <div className="pixel-mini">
              <PixelCanvas paint={paint} kind="centered" frameKey={frameKeys.current} width={width} height={height} className="pixel-mini__canvas" label={PIXEL_COPY.centerTrim} />
              <GuideMarks guides={guides} width={width} height={height} />
            </div>
            <figcaption>
              {PIXEL_COPY.centerTrim}
              <span className="pixel-center__shift">
                {PIXEL_COPY.centerShift} x {centerShift.dx > 0 ? `+${centerShift.dx}` : centerShift.dx} · y {centerShift.dy > 0 ? `+${centerShift.dy}` : centerShift.dy}
              </span>
            </figcaption>
          </figure>
        </div>
      </section>
    </div>
  );
}
