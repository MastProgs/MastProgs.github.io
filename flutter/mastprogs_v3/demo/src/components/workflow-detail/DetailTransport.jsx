import { ArrowCounterClockwiseIcon, CrosshairIcon, PauseIcon, PlayIcon, SkipBackIcon, SkipForwardIcon } from "@phosphor-icons/react";
import { DETAIL_COPY, SPEED_OPTIONS } from "../../content/workflowDetail.js";
import { RUN_STATUS } from "../../workflow/constants.js";
import { frameTitle } from "../../workflow-detail/frames.js";
import { getScenario } from "../../workflow-detail/model.js";

const pad = (value) => String(value).padStart(2, "0");
const STATUS_TEXT = { idle: "대기", running: "재생 중", paused: "일시정지", done: "완료" };

// AI-NOTE: 직접 처리·순차·독립 병렬 공용 프레임 재생기(음악 재생기형). 바깥 모양은 하나의 둥근 판이며,
// 고정(sticky) 상태에서도 같은 모양이다(위만 둥글고 아래가 각진 막대 금지).
// 조작: 이전 프레임 · 재생/일시정지 · 다음 프레임 · 처음으로, 프레임 위치 슬라이더(0..total 정수, 키보드는 브라우저 기본),
// 현재 프레임 번호·제목, 속도(0.5·1·2배 — 넘김 간격만 바뀜), 현재 프레임 따라가기 스위치(기본 켬).
// 이전·위치 이동·다음은 리듀서에서 일시정지로 멈춘다. 끝에 닿으면 재생 버튼은 처음부터 다시 재생(자동 반복 없음).
// 경계에서는 disabled 대신 aria-disabled 를 써서 누른 버튼의 키보드 포커스가 사라지지 않게 한다. 누를 곳은 모두 44px 이상.
// 전역 단축키는 두지 않는다(입력 중 키를 가로채지 않음).
export function DetailTransport({ state, follow, onPlay, onPause, onReset, onNext, onPrev, onSeek, onSpeed, onFollow }) {
  const scenario = getScenario(state.options);
  const { status, cursor } = state;
  const { total } = scenario;
  const running = status === RUN_STATUS.RUNNING;
  const done = status === RUN_STATUS.DONE;
  const atStart = cursor === 0 && status === RUN_STATUS.IDLE;
  const atFirst = cursor === 0;
  let playLabel = "재생";
  if (running) playLabel = "일시정지";
  else if (done) playLabel = "처음부터 다시 재생";
  const ToggleIcon = running ? PauseIcon : PlayIcon;
  const title = frameTitle(scenario, cursor);
  const progress = total === 0 ? 0 : (cursor / total) * 100;

  return (
    <div className={`wfd-transport${running ? " is-running" : ""}`} role="group" aria-label="프레임 재생기">
      <div className="wfd-transport__controls">
        <button type="button" className="wfd-transport__btn" aria-label="이전 프레임" title="이전 프레임" aria-disabled={atFirst} onClick={atFirst ? undefined : onPrev}>
          <SkipBackIcon size={20} weight="fill" aria-hidden="true" />
        </button>
        <button type="button" className="wfd-transport__btn wfd-transport__btn--primary" aria-label={playLabel} title={playLabel} onClick={running ? onPause : onPlay}>
          <ToggleIcon size={24} weight="fill" aria-hidden="true" />
        </button>
        <button type="button" className="wfd-transport__btn" aria-label="다음 프레임" title="다음 프레임" aria-disabled={done} onClick={done ? undefined : onNext}>
          <SkipForwardIcon size={20} weight="fill" aria-hidden="true" />
        </button>
        <button type="button" className="wfd-transport__btn wfd-transport__btn--quiet" aria-label="처음으로" title="처음으로" aria-disabled={atStart} onClick={atStart ? undefined : onReset}>
          <ArrowCounterClockwiseIcon size={20} aria-hidden="true" />
        </button>
      </div>

      <div className="wfd-transport__now">
        <p className="wfd-transport__counter">
          <span>{DETAIL_COPY.frameLabel}</span>
          <span className="wfd-transport__value">
            {pad(cursor)} / {pad(total)}
          </span>
          <span className={`wfd-transport__status wfd-transport__status--${status}`}>{STATUS_TEXT[status]}</span>
        </p>
        <p className="wfd-transport__title" title={title}>
          {title}
        </p>
      </div>

      <div className="wfd-transport__extra">
        <label className="wfd-transport__speed">
          <span className="sr-only">{DETAIL_COPY.speedLabel}</span>
          <select value={state.speed} onChange={(event) => onSpeed(Number(event.target.value))}>
            {SPEED_OPTIONS.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </label>
        <button type="button" className="wfd-transport__follow" aria-pressed={follow} title={DETAIL_COPY.followLabel} onClick={() => onFollow(!follow)}>
          <CrosshairIcon size={18} weight={follow ? "bold" : "regular"} aria-hidden="true" />
          <span>{DETAIL_COPY.followLabel}</span>
        </button>
      </div>

      <input
        type="range"
        className="wfd-transport__scrub"
        min={0}
        max={total}
        step={1}
        value={cursor}
        aria-label={DETAIL_COPY.frameSlider}
        aria-valuetext={`${DETAIL_COPY.frameLabel} ${cursor} / ${total}, ${title}`}
        style={{ "--progress": `${progress}%` }}
        onChange={(event) => onSeek(Number(event.target.value))}
      />
    </div>
  );
}
