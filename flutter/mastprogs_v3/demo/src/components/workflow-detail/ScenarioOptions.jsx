import { OPTION_HINT, SCENARIO_OPTIONS } from "../../content/workflowDetail.js";

// AI-NOTE: 시나리오 옵션 스위치. 경로에 해당하지 않는 옵션은 disabled 로 두고 이유를 한 줄로 보여 준다.
// route 가 "direct" 이면 스위치를 그리지 않고 이유 한 줄만 보여 준다(직접 처리에는 기획·검수·Seed 가 없어 쓸 수 없는 옵션을
// 늘어놓지 않음, 사용자 최신 요청). 스위치 행은 44px 이상이다.
export function ScenarioOptions({ route, values = {}, onChange }) {
  const hint = route === "direct" ? OPTION_HINT.direct : route === "parallel" ? OPTION_HINT.parallel : null;
  const hintId = `wfd-options-hint-${route}`;
  if (route === "direct") {
    return (
      <div className="wfd-options">
        <p className="wfd-options__hint">{hint}</p>
      </div>
    );
  }
  return (
    <div className="wfd-options" role="group" aria-label="시나리오 옵션" aria-describedby={hint ? hintId : undefined}>
      {SCENARIO_OPTIONS.map((option) => {
        const enabled = option.routes.includes(route) && typeof onChange === "function";
        const checked = enabled && Boolean(values[option.id]);
        const id = `wfd-opt-${route}-${option.id}`;
        return (
          <div key={option.id} className={`wfd-switch${enabled ? "" : " is-disabled"}`}>
            <button
              type="button"
              role="switch"
              id={id}
              className="wfd-switch__track"
              aria-checked={checked}
              disabled={!enabled}
              onClick={() => onChange(option.id, !checked)}
            >
              <span className="wfd-switch__knob" aria-hidden="true" />
            </button>
            <label className="wfd-switch__label" htmlFor={id}>
              {option.label}
            </label>
          </div>
        );
      })}
      {hint && (
        <p id={hintId} className="wfd-options__hint">
          {hint}
        </p>
      )}
      {route === "parallel" && values.seed && <p className="wfd-options__hint">{OPTION_HINT.parallelSeed}</p>}
    </div>
  );
}
