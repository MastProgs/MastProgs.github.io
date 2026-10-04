import { ArrowCounterClockwiseIcon, PauseIcon, PlayIcon, SkipForwardIcon } from "@phosphor-icons/react";
import { STAGE } from "../../content/site.js";
import { RUN_STATUS } from "../../workflow/constants.js";
import { describeRun, isFailureAvailable, planHasRework } from "../../workflow/model.js";

const pad = (value) => String(value).padStart(2, "0");

export function Transport({ state, onPlay, onPause, onReset, onNext, onToggleFail, showFailToggle = true }) {
  const { status, cursor, plan, mode } = state;
  const running = status === RUN_STATUS.RUNNING;
  const done = status === RUN_STATUS.DONE;
  const atStart = cursor === 0 && status === RUN_STATUS.IDLE;
  const failAvailable = isFailureAvailable(mode);
  const failChecked = failAvailable && state.failOn;
  const run = describeRun(state);

  let playLabel = "재생";
  if (running) playLabel = "일시정지";
  else if (done) playLabel = "다시 실행";
  const ToggleIcon = running ? PauseIcon : PlayIcon;

  return (
    <div className="transport">
      <button
        type="button"
        className="transport__round transport__round--primary"
        aria-label={playLabel}
        title={playLabel}
        onClick={running ? onPause : onPlay}
      >
        <ToggleIcon size={22} weight="regular" aria-hidden="true" />
      </button>
      {/* AI-NOTE: 누른 직후 비활성화되면 포커스가 사라지므로 disabled 대신 aria-disabled 로 표시하고 클릭을 무시한다. */}
      <button
        type="button"
        className="transport__round"
        aria-label="처음으로"
        title="처음으로"
        aria-disabled={atStart}
        onClick={atStart ? undefined : onReset}
      >
        <ArrowCounterClockwiseIcon size={22} aria-hidden="true" />
      </button>
      <button type="button" className="transport__next" aria-disabled={done} onClick={done ? undefined : onNext}>
        <SkipForwardIcon size={18} aria-hidden="true" />
        <span>다음 단계</span>
      </button>
      <p className="transport__counter">
        <span className="transport__counter-label">실행</span>
        <span className="transport__counter-value">
          {pad(cursor)} / {pad(plan.length)}
        </span>
        {planHasRework(plan) && <span className="transport__counter-note">{STAGE.reworkHint}</span>}
      </p>
      {/* AI-NOTE: ScenarioOptions 가 같은 QA 스위치를 그리는 화면(직접 처리)에서는 showFailToggle={false} 로 중복을 숨긴다. */}
      {showFailToggle && <span className="transport__divider" aria-hidden="true" />}
      {showFailToggle && <div className={`fail-toggle${failAvailable ? "" : " is-disabled"}`}>
        <button
          type="button"
          role="switch"
          id="fail-toggle"
          className="fail-toggle__switch"
          aria-checked={failChecked}
          aria-describedby={failAvailable ? undefined : "fail-toggle-hint"}
          disabled={!failAvailable}
          onClick={() => onToggleFail(!state.failOn)}
        >
          <span className="fail-toggle__knob" aria-hidden="true" />
        </button>
        <label className="fail-toggle__label" htmlFor="fail-toggle">
          {STAGE.failToggle}
        </label>
        {!failAvailable && (
          <span id="fail-toggle-hint" className="fail-toggle__hint">
            {STAGE.failDisabledHint}
          </span>
        )}
      </div>}
      <p className={`run-pill run-pill--${run.tone}`}>
        <span className="run-pill__dot" aria-hidden="true" />
        <span>{run.text}</span>
      </p>    </div>
  );
}
