import { useId } from "react";
import { ArrowsOutSimpleIcon, PauseIcon, PlayIcon, ShuffleIcon } from "@phosphor-icons/react";
import { PIXEL_COPY, PIXEL_PRESETS } from "../../content/pixelStudio.js";
import { usePixelPreview } from "../../hooks/usePixelPreview.js";
import { HERO_COLOR_TABLE, HERO_LAYERS, HERO_MOTION_RIG, HERO_RIG, HERO_SPRITE, PALETTE_SETS } from "../../pixel/assets.js";
import { celBounds } from "../../pixel/layers.js";
import { cyclesFor } from "../../pixel/playback.js";
import { LayerTimeline } from "./pixel/LayerTimeline.jsx";
import { PaletteSetRow } from "./pixel/PaletteSetRow.jsx";
import { RigPanel } from "./pixel/RigPanel.jsx";
import { StudioInspector } from "./pixel/StudioInspector.jsx";

const STUDIO = Object.freeze({ layers: HERO_LAYERS, colorTable: HERO_COLOR_TABLE, sets: PALETTE_SETS, motionRig: HERO_MOTION_RIG });
const pctOf = (value, total) => `${(value / total) * 100}%`;

// AI-NOTE: 작업 사례 02(Hero Pixel Studio, id case-pixel; 사용자 최신 지시로 04 → 02)와 연결된 라이브 미리보기. 사용자 최신 지시로 사례 레일 아래에서 빼서
// /sprite 상세 페이지(SpritePage)에만 마운트한다. "사례 자세히 보기" 로 같은 사례 대화상자(원본 편집기 화면 캡처 근거)를 연다.
// 화면: 왼쪽 공통 캔버스(최근접 확대, 같은 기준점·발바닥 선) + 원본 GIF/프레임, 오른쪽 조작(재생·무작위 섞기·모션·팔레트·추가 외곽선
// → 2행 팔레트 세트·적용 비율). 아래 작업 화면: 레이어×프레임 타임라인, 선택 레이어·어니언·기준선·중심 비교, 골격 패널.
// 큰 캔버스는 원본 레이어 셀을 원본 규칙으로 합성한 결과이고, 모든 화면이 재생 커서 하나를 따른다.
// 모든 버튼·색 입력은 44px 이상이고 키보드·터치로 같은 일을 한다.
export function PixelStudioPreview({ onOpenCase }) {
  const sprite = HERO_SPRITE;
  const view = usePixelPreview(sprite, STUDIO);
  const headingId = useId();
  const { motion, playback, ready, actions, guides } = view;
  // 원본 GIF 는 스스로 멈출 수 없으므로 실제로 재생 중(화면 안·탭 보임·재생 켬)일 때만 쓰고, 그 외에는 재생 커서가 가리키는
  // 같은 원본 PNG 정지 화면(프레임 비교가 같은 실제 프레임끼리 되도록).
  const showGif = view.active;
  const staticFrame = (motion.frames[playback.frame] ?? motion.frames[0]).src;
  const W = sprite.canvasWidth;
  const H = sprite.canvasHeight;
  const stageStyle = {
    "--px-w": W,
    "--px-h": H,
    "--px-sole": pctOf(guides.soleRow + 1, H),
    "--px-crown": pctOf(guides.crownRow, H),
    "--px-pivot": pctOf(guides.pivotX + 0.5, W),
  };
  const bounds = celBounds(view.model, view.frameIndex, view.selectedLayer);
  const boundsStyle = bounds && {
    left: pctOf(bounds.x + sprite.pad, W),
    top: pctOf(bounds.y + sprite.pad, H),
    width: pctOf(bounds.w, W),
    height: pctOf(bounds.h, H),
  };

  return (
    <section ref={view.rootRef} className="pixel-preview" aria-labelledby={headingId}>
      <div className="pixel-preview__head">
        <h2 id={headingId} className="pixel-preview__title">
          {PIXEL_COPY.heading}
        </h2>
        <button type="button" className="pixel-preview__open" onClick={onOpenCase} aria-haspopup="dialog">
          {PIXEL_COPY.openCase}
          <ArrowsOutSimpleIcon size={16} aria-hidden="true" />
        </button>
        <p className="pixel-preview__lead">{PIXEL_COPY.lead}</p>
      </div>

      <div className="pixel-preview__body">
        <div className="pixel-preview__stages">
          <figure className="pixel-stage" style={stageStyle}>
            <div className="pixel-stage__frame">
              {view.guidesOn && (
                <>
                  <span className="pixel-stage__crown" aria-hidden="true" />
                  <span className="pixel-stage__cross-v" aria-hidden="true" />
                  <span className="pixel-stage__ground" aria-hidden="true" />
                  <span className="pixel-stage__pivot" aria-hidden="true" />
                </>
              )}
              <canvas
                ref={view.canvasRef}
                className="pixel-stage__canvas"
                width={W}
                height={H}
                role="img"
                aria-label={`${PIXEL_COPY.stageLabel}: ${motion.label}`}
                hidden={ready !== "ready"}
              />
              {ready === "ready" && boundsStyle && <span className="pixel-stage__cel" style={boundsStyle} aria-hidden="true" />}
              {ready !== "ready" && (
                <img
                  className="pixel-stage__canvas"
                  src={view.active ? motion.gif : staticFrame}
                  width={sprite.width}
                  height={sprite.height}
                  alt={`${PIXEL_COPY.original}: ${motion.label}`}
                />
              )}
            </div>
            <figcaption className="pixel-stage__caption">
              <span className="pixel-stage__motion">{motion.label}</span>
              <span>
                {Math.min(playback.loop + 1, cyclesFor(motion.id))}/{cyclesFor(motion.id)}
                {PIXEL_COPY.cycles} · {playback.frame + 1}/{motion.frames.length}
              </span>
              {!view.inView && view.playing && <span className="sr-only">{PIXEL_COPY.pausedOffscreen}</span>}
            </figcaption>
            {ready === "fallback" && <p className="pixel-stage__note">{PIXEL_COPY.fallback}</p>}
          </figure>

          {ready === "ready" && (
            <figure className="pixel-original">
              <img src={showGif ? motion.gif : staticFrame} width={sprite.width} height={sprite.height} alt={`${showGif ? PIXEL_COPY.original : PIXEL_COPY.originalStatic}: ${motion.label}`} />
              <figcaption>{showGif ? PIXEL_COPY.original : PIXEL_COPY.originalStatic}</figcaption>
            </figure>
          )}
        </div>

        <div className="pixel-controls">
          <div className="pixel-controls__row">
            <button
              type="button"
              className="pixel-btn pixel-btn--primary"
              aria-label={view.playing ? PIXEL_COPY.pause : PIXEL_COPY.play}
              title={view.playing ? PIXEL_COPY.pause : PIXEL_COPY.play}
              onClick={actions.togglePlay}
            >
              {view.playing ? <PauseIcon size={20} weight="fill" aria-hidden="true" /> : <PlayIcon size={20} weight="fill" aria-hidden="true" />}
            </button>
            <button type="button" className="pixel-btn pixel-btn--chip" aria-pressed={view.shuffleOn} onClick={actions.toggleShuffle}>
              <ShuffleIcon size={18} aria-hidden="true" />
              {PIXEL_COPY.shuffle}
            </button>
          </div>

          <div className="pixel-controls__group" role="group" aria-label={PIXEL_COPY.motionGroup}>
            <p className="pixel-controls__label" aria-hidden="true">{PIXEL_COPY.motionGroup}</p>
            <div className="pixel-seg">
              {sprite.motions.map((item) => (
                <button
                  key={item.id}
                  type="button"
                  className={`pixel-seg__item${item.id === motion.id ? " is-current" : ""}`}
                  aria-pressed={item.id === motion.id}
                  onClick={() => actions.selectMotion(item.id)}
                >
                  {item.label}
                </button>
              ))}
            </div>
          </div>

          <div className="pixel-controls__group" role="group" aria-label={PIXEL_COPY.paletteGroup}>
            <p className="pixel-controls__label" aria-hidden="true">{PIXEL_COPY.paletteGroup}</p>
            <div className="pixel-swatches">
              {PIXEL_PRESETS.map((preset) => (
                <button
                  key={preset.id}
                  type="button"
                  className={`pixel-swatch${view.presetId === preset.id ? " is-current" : ""}`}
                  aria-pressed={view.presetId === preset.id}
                  onClick={() => actions.selectPreset(preset.id)}
                >
                  <span className={`pixel-swatch__chip${preset.accent ? "" : " is-original"}`} style={preset.accent ? { background: preset.accent } : undefined} aria-hidden="true" />
                  {preset.label}
                </button>
              ))}
              <label className={`pixel-swatch pixel-swatch--input${view.presetId === "custom" ? " is-current" : ""}`}>
                <input type="color" value={view.customAccent ?? "#3a7bd5"} onChange={(event) => actions.setAccent(event.target.value)} />
                <span>{PIXEL_COPY.accentInput}</span>
              </label>
            </div>
          </div>

          <div className="pixel-controls__group">
            <div className="pixel-outline">
              <button type="button" role="switch" aria-checked={view.outlineOn} className="pixel-switch" onClick={actions.toggleOutline}>
                <span className="pixel-switch__track" aria-hidden="true">
                  <span className="pixel-switch__knob" />
                </span>
                {PIXEL_COPY.outline}
              </button>
              {/* AI-NOTE: 색 입력은 실제로 그리는 외곽선 색(effectiveOutlineColor)을 보여 준다. 직접 고르면 manual, '자동 색' 으로 되돌린다. */}
              <label className={`pixel-swatch pixel-swatch--input${view.outlineMode === "manual" ? " is-current" : ""}`}>
                <input type="color" value={view.outlineColor} onChange={(event) => actions.setOutlineColor(event.target.value)} />
                <span>{PIXEL_COPY.outlineColor}</span>
              </label>
              <button type="button" className={`pixel-btn pixel-btn--chip${view.outlineMode === "auto" ? " is-current" : ""}`} aria-pressed={view.outlineMode === "auto"} onClick={actions.setOutlineAuto}>
                {PIXEL_COPY.outlineAuto}
              </button>
            </div>
            <p className="pixel-controls__hint">
              {PIXEL_COPY.outlineHint} {view.outlineMode === "auto" ? PIXEL_COPY.outlineAutoHint : PIXEL_COPY.outlineManualHint}
            </p>
          </div>

          <PaletteSetRow sets={STUDIO.sets} mode={view.paletteMode} set={view.set} ratio={view.ratio} shares={view.shares} onSelect={actions.selectSet} onRatio={actions.setRatio} />

          <p className="pixel-controls__status">{view.showcase ? PIXEL_COPY.showcaseOn : PIXEL_COPY.showcaseOff}</p>
        </div>
      </div>

      {ready === "ready" && (
        <div className="pixel-workspace" role="group" aria-label={PIXEL_COPY.workspace}>
          {/* AI-NOTE: 훅 반환 객체 전체(view)를 넘기지 않는다. 작은 값·정적 참조·안정된 paint 접근자만(장시간 재생 멈춤 수정). */}
          <LayerTimeline
            model={view.model}
            steps={view.steps}
            cursor={playback.frame}
            frameIndex={view.frameIndex}
            loop={view.loop}
            playing={view.playing}
            selectedLayer={view.selectedLayer}
            visibility={view.visibility}
            isolated={view.isolated}
            effectiveVisibility={view.effectiveVisibility}
            motionLabel={motion.label}
            actions={actions}
          />
          <StudioInspector
            model={view.model}
            frameIndex={view.frameIndex}
            selectedLayer={view.selectedLayer}
            isolated={view.isolated}
            onionOn={view.onionOn}
            onionOpacity={view.onionOpacity}
            guidesOn={view.guidesOn}
            guides={guides}
            neighbors={view.neighbors}
            centerShift={view.centerShift}
            imageSize={view.imageSize}
            frameKeys={view.frameKeys}
            paint={view.paintImage}
            actions={actions}
          />
          <RigPanel rig={HERO_RIG} frame={view.rig} />
        </div>
      )}
    </section>
  );
}
