import { useEffect, useReducer, useState } from "react";
import { ArrowCounterClockwiseIcon, CaretLeftIcon, CaretRightIcon, PauseIcon, PlayIcon } from "@phosphor-icons/react";
import { WALKTHROUGH_COPY as COPY, WALKTHROUGH_FIXTURE, WALKTHROUGH_STAGES as STAGES } from "../../content/subtitles.js";
import { STAGE_INTERVAL_MS, buildWalkthrough, finalCues, formatSeconds, stageReducer, toSrt } from "../../subtitles/model.js";

// 모듈을 읽을 때 한 번만 만든 작은 고정 데이터. 렌더마다 새 배열을 만들지 않아 props 가 바뀌지 않는다.
const WALK = buildWalkthrough(WALKTHROUGH_FIXTURE);
const TOTAL = STAGES.length;
const SECONDS = Array.from({ length: Math.floor(WALK.durationMs / 1000) + 1 }, (_, i) => i);
const pct = (ms) => `${(ms / WALK.durationMs) * 100}%`;
const span = (startMs, endMs) => ({ left: pct(startMs), width: pct(endMs - startMs) });
const cutTime = (cut) => WALK.words[cut].endMs;
const pad = (n) => String(n).padStart(2, "0");
const sec = (ms) => (ms / 1000).toFixed(2);

// AI-NOTE: 처리 원리를 단계별로 따라가는 예시(src/content/subtitles.js WALKTHROUGH_FIXTURE, 가상 대사). 실제 음성 인식·정렬·AI 호출·
// 오디오 재생·업로드·저장은 없다. 재생은 사용자가 누를 때만 단계를 차례로 넘기고(자동 시작 없음), 끝에서 멈춘다(반복 없음).
// 탭이 가려지면 멈춘다. 이전·다음·단계 고르기는 멈춘다. 사람의 수락·보류는 이 화면 상태로만 남고 새로 고치면 사라진다.
// 시간축의 모든 경계는 단어 정렬 시각에서 나온다(AI 응답에는 시간이 없다).
export function SubtitleWalkthrough() {
  const [state, dispatch] = useReducer((current, action) => stageReducer(current, action, TOTAL), { stage: 0, playing: false });
  const [decisions, setDecisions] = useState({});
  // 직접 단계를 옮겼을 때만 알린다(자동 넘김 중에는 알리지 않음).
  const [message, announce] = useState("");
  const { stage, playing } = state;
  const meta = STAGES[stage];
  const atEnd = stage === TOTAL - 1;

  useEffect(() => {
    if (!playing) return undefined;
    const timer = window.setTimeout(() => dispatch({ type: "tick" }), STAGE_INTERVAL_MS);
    return () => window.clearTimeout(timer);
  }, [playing, stage]);

  useEffect(() => {
    const handle = () => {
      if (document.hidden) dispatch({ type: "pause" });
    };
    document.addEventListener("visibilitychange", handle);
    return () => document.removeEventListener("visibilitychange", handle);
  }, []);

  const go = (action) => {
    dispatch(action);
    const next = stageReducer(state, action, TOTAL);
    if (next.stage !== stage) announce(`${pad(next.stage + 1)} ${STAGES[next.stage].label}: ${STAGES[next.stage].title}`);
  };

  const decide = (id, value) => setDecisions((current) => ({ ...current, [id]: value }));
  const undo = (id) =>
    setDecisions((current) => {
      const next = { ...current };
      delete next[id];
      return next;
    });

  let playLabel = COPY.play;
  if (playing) playLabel = COPY.pause;
  else if (atEnd) playLabel = COPY.restart;

  return (
    <div className="srt-walk">
      <ol className="srt-walk__stages" aria-label={COPY.stageList}>
        {STAGES.map((item, index) => (
          <li key={item.id}>
            <button
              type="button"
              className={`srt-walk__stage${index === stage ? " is-current" : ""}${index < stage ? " is-past" : ""}`}
              aria-current={index === stage ? "step" : undefined}
              onClick={() => go({ type: "seek", stage: index })}
            >
              <span className="srt-walk__stage-num">{pad(index + 1)}</span>
              {item.label}
            </button>
          </li>
        ))}
      </ol>

      <div className="srt-walk__transport" role="group" aria-label={COPY.transportLabel}>
        <button type="button" className="wfd-transport__btn" aria-label={COPY.prev} title={COPY.prev} aria-disabled={stage === 0} onClick={stage === 0 ? undefined : () => go({ type: "prev" })}>
          <CaretLeftIcon size={20} weight="bold" aria-hidden="true" />
        </button>
        <button type="button" className="wfd-transport__btn wfd-transport__btn--primary" aria-label={playLabel} title={playLabel} onClick={() => go({ type: playing ? "pause" : "play" })}>
          {playing ? <PauseIcon size={22} weight="fill" aria-hidden="true" /> : <PlayIcon size={22} weight="fill" aria-hidden="true" />}
        </button>
        <button type="button" className="wfd-transport__btn" aria-label={COPY.next} title={COPY.next} aria-disabled={atEnd} onClick={atEnd ? undefined : () => go({ type: "next" })}>
          <CaretRightIcon size={20} weight="bold" aria-hidden="true" />
        </button>
        <button type="button" className="wfd-transport__btn wfd-transport__btn--quiet" aria-label={COPY.reset} title={COPY.reset} aria-disabled={stage === 0 && !playing} onClick={stage === 0 && !playing ? undefined : () => go({ type: "reset" })}>
          <ArrowCounterClockwiseIcon size={20} aria-hidden="true" />
        </button>
        <p className="srt-walk__counter">
          <span className="srt-walk__count">
            {pad(stage + 1)} / {pad(TOTAL)}
          </span>
          <span className="srt-walk__fixture">{COPY.fixtureLabel}</span>
        </p>
      </div>
      <p className="sr-only" aria-live="polite">
        {message}
      </p>

      <section className="srt-walk__panel" aria-labelledby="srt-stage-title">
        <h3 id="srt-stage-title" className="srt-walk__title">
          <span className="srt-walk__title-num">{pad(stage + 1)}</span>
          {meta.title}
        </h3>
        <p className="srt-walk__text">{meta.text}</p>
        <Timeline stage={stage} />
        <StageDetail stage={stage} decisions={decisions} onDecide={decide} onUndo={undo} />
      </section>
    </div>
  );
}

// 공용 시간축. 단계가 올라갈수록 행이 더해지고, 그 단계에서 새로 생긴 요소는 is-new 로 강조한다.
function Timeline({ stage }) {
  const showWords = stage >= 1;
  const showVad = stage >= 2;
  const showCuts = stage >= 3;
  const cues = showCuts ? WALK.cues : stage === 2 ? [WALK.whole] : [];
  return (
    <figure className="srt-tl" aria-label={COPY.timelineLabel}>
      <div className="srt-tl__axis" aria-hidden="true">
        {SECONDS.map((s) => (
          <span key={s} style={{ left: pct(s * 1000) }}>
            {s}
          </span>
        ))}
      </div>

      {stage === 3 && (
        <div className="srt-tl__row srt-tl__row--levels is-new">
          <span className="srt-tl__label">{COPY.levels}</span>
          <div className="srt-tl__track srt-tl__levels" aria-hidden="true">
            {WALK.levels.map((level, i) => (
              <span key={i} style={{ height: `${(level / 9) * 100}%` }} data-level={level} />
            ))}
          </div>
        </div>
      )}

      {showVad && (
        <div className={`srt-tl__row${stage === 2 ? " is-new" : ""}`}>
          <span className="srt-tl__label">{COPY.vad}</span>
          <div className="srt-tl__track">
            {WALK.vad.map((seg) => (
              <span key={seg.startMs} className="srt-tl__vad" style={span(seg.startMs, seg.endMs)} title={`${sec(seg.startMs)}–${sec(seg.endMs)}`} />
            ))}
          </div>
        </div>
      )}

      <div className={`srt-tl__row${stage === 1 ? " is-new" : ""}`}>
        <span className="srt-tl__label">{showWords ? COPY.words : "인식 구간"}</span>
        <div className="srt-tl__track">
          {showWords ? (
            WALK.words.map((word) => (
              <span
                key={word.index}
                className={`srt-tl__word${word.risk && (stage <= 1 || stage === 4) ? " is-risk" : ""}`}
                style={span(word.startMs, word.endMs)}
                title={`${word.text} ${sec(word.startMs)}–${sec(word.endMs)}`}
              >
                <span className="srt-tl__word-text">{word.text}</span>
              </span>
            ))
          ) : (
            <span className="srt-tl__chunk is-new" style={span(0, WALK.durationMs)}>
              {WALK.rawText}
            </span>
          )}
          {showCuts &&
            WALK.pauses.map((pause) => (
              <span key={pause.after} className={`srt-tl__pause${stage === 3 ? " is-new" : ""}`} style={{ left: pct((pause.startMs + pause.endMs) / 2) }}>
                {COPY.pauseMark} {sec(pause.ms)}
              </span>
            ))}
        </div>
      </div>

      {cues.length > 0 && (
        <div className={`srt-tl__row${stage === 2 || stage === 3 ? " is-new" : ""}`}>
          <span className="srt-tl__label">
            {COPY.raw} · {COPY.display}
          </span>
          <div className="srt-tl__track srt-tl__track--cues">
            {cues.map((cue) => (
              <span key={`${cue.startMs}-${cue.endMs}`} className="srt-tl__cue-wrap">
                <span className="srt-tl__cue-display" style={span(cue.displayStartMs, cue.displayEndMs)} title={`${COPY.display} ${sec(cue.displayStartMs)}–${sec(cue.displayEndMs)}`} />
                <span className="srt-tl__cue" style={span(cue.startMs, cue.endMs)} title={`${COPY.raw} ${sec(cue.startMs)}–${sec(cue.endMs)}`} />
              </span>
            ))}
            {showCuts &&
              WALK.split.cuts.map((cut) => (
                <span key={cut} className={`srt-tl__cut${WALK.split.disputed.includes(cut) ? " is-debated" : ""}${stage === 3 ? " is-new" : ""}`} style={{ left: pct(cutTime(cut)) }} />
              ))}
          </div>
        </div>
      )}
      <figcaption className="srt-tl__legend">
        <span className="srt-tl__key srt-tl__key--word" aria-hidden="true" />
        {COPY.words}
        {showVad && (
          <>
            <span className="srt-tl__key srt-tl__key--vad" aria-hidden="true" />
            {COPY.vad}
            <span className="srt-tl__key srt-tl__key--raw" aria-hidden="true" />
            {COPY.raw}
            <span className="srt-tl__key srt-tl__key--display" aria-hidden="true" />
            {COPY.display}
          </>
        )}
        {showCuts && (
          <>
            <span className="srt-tl__key srt-tl__key--cut" aria-hidden="true" />
            {COPY.cut}
          </>
        )}
      </figcaption>
    </figure>
  );
}

function StageDetail({ stage, decisions, onDecide, onUndo }) {
  const risky = WALK.words.find((word) => word.risk);
  switch (STAGES[stage].id) {
    case "asr":
      return (
        <dl className="srt-facts">
          <div>
            <dt>{WALKTHROUGH_FIXTURE.models.reference} 원문</dt>
            <dd className="srt-quote">{WALK.rawText}</dd>
          </div>
          <div>
            <dt>위험 표시</dt>
            <dd>
              {WALKTHROUGH_FIXTURE.models.reference}와 {WALKTHROUGH_FIXTURE.models.compare} 결과의 단어 내용이 다릅니다:{" "}
              <mark className="srt-mark">{risky.text}</mark> / <mark className="srt-mark srt-mark--alt">{risky.risk}</mark>
            </dd>
          </div>
        </dl>
      );
    case "align":
      return (
        <>
          <ol className="srt-words" aria-label={COPY.words}>
            {WALK.words.map((word) => (
              <li key={word.index} className={word.risk ? "is-risk" : undefined}>
                <span className="srt-words__text">{word.text}</span>
                <span className="srt-words__time">
                  {sec(word.startMs)}–{sec(word.endMs)}
                </span>
              </li>
            ))}
          </ol>
          <dl className="srt-facts">
            <div>
              <dt>{COPY.spoken}</dt>
              <dd className="srt-quote">{WALK.rawText}</dd>
            </div>
            <div>
              <dt>{COPY.displayText}</dt>
              <dd className="srt-quote">{WALKTHROUGH_FIXTURE.displayTexts.join(" ")}</dd>
            </div>
          </dl>
        </>
      );
    case "pad": {
      const cue = WALK.whole;
      return (
        <dl className="srt-facts srt-facts--grid">
          <div>
            <dt>{COPY.raw}</dt>
            <dd>
              {sec(cue.startMs)}–{sec(cue.endMs)}초
            </dd>
          </div>
          <div>
            <dt>{COPY.display}</dt>
            <dd>
              {sec(cue.displayStartMs)}–{sec(cue.displayEndMs)}초 <span className="srt-dim">(앞 {formatSeconds(cue.startMs - cue.displayStartMs)} · 뒤 {formatSeconds(cue.displayEndMs - cue.endMs)}, 최대 0.30초)</span>
            </dd>
          </div>
          <div>
            <dt>길이</dt>
            <dd>
              {formatSeconds(cue.displayEndMs - cue.displayStartMs)} · {WALK.rawText.replace(/\s/g, "").length}자 <span className="srt-dim">(6초·30자 기준을 넘어 나누기 대상)</span>
            </dd>
          </div>
        </dl>
      );
    }
    case "split":
      return (
        <div className="srt-split">
          <div className="srt-split__cols">
            {[
              { who: "Codex", cuts: WALK.split.codexCuts, reason: WALK.split.codexReason },
              { who: "Claude", cuts: WALK.split.claudeCuts, reason: WALK.split.claudeReason },
            ].map((side) => (
              <section key={side.who} className="srt-split__side" aria-label={`${side.who} 문장 나누기`}>
                <p className="srt-split__who">{side.who}</p>
                <p className="srt-split__cuts">
                  {side.cuts.map((cut) => (
                    <span key={cut} className={WALK.split.disputed.includes(cut) ? "is-debated" : undefined}>
                      {WALK.words[cut].text} | {WALK.words[cut + 1].text}
                    </span>
                  ))}
                </p>
                <p className="srt-dim">{side.reason}</p>
              </section>
            ))}
          </div>
          <ol className="srt-debate" aria-label={`${COPY.round} 기록`}>
            {WALK.split.debate.map((round) => (
              <li key={round.round}>
                <span className="srt-debate__round">
                  {COPY.round} {round.round}
                </span>
                Claude {round.claude} · {round.reason}
              </li>
            ))}
          </ol>
          <ul className="srt-cutlist" aria-label={COPY.cut}>
            {WALK.split.cuts.map((cut) => (
              <li key={cut}>
                {WALK.words[cut].text} | {WALK.words[cut + 1].text}: 앞 자막 끝 {sec(WALK.words[cut].endMs)}초 · 다음 자막 시작 {sec(WALK.words[cut + 1].startMs)}초
                <span className="srt-dim"> ({WALK.split.disputed.includes(cut) ? "토론 후 합의" : COPY.agree}, 단어 시각에서)</span>
              </li>
            ))}
          </ul>
        </div>
      );
    case "review":
      return <ProposalCards decisions={decisions} onDecide={onDecide} onUndo={onUndo} />;
    case "srt":
      return <pre className="srt-output" tabIndex={0} aria-label="SRT 결과">{toSrt(finalCues(WALK, decisions))}</pre>;
    default:
      return null;
  }
}

// 바뀐 어절만 표시한다(같은 위치 어절 비교, 예시 문장은 어절 수가 같다).
function diffWords(before, after) {
  const a = before.split(" ");
  const b = after.split(" ");
  return b.map((word, i) => ({ word, changed: word !== a[i] }));
}

function ProposalCards({ decisions, onDecide, onUndo }) {
  const cues = finalCues(WALK, decisions);
  return (
    <div className="srt-proposals">
      {WALK.proposals.map((proposal) => {
        const original = WALK.cues.find((cue) => cue.id === proposal.id);
        const decision = decisions[proposal.id] ?? "pending";
        const result = cues.find((cue) => cue.id === proposal.id);
        const statusText = decision === "accepted" ? "수락됨" : decision === "held" ? "보류됨" : "결정 전";
        return (
          <article key={proposal.id} className={`srt-proposal is-${decision}`} aria-label={`교정 제안 ${proposal.id}`}>
            <p className="srt-proposal__head">
              <span>교정 제안 · {proposal.id}</span>
              <span className="srt-proposal__agree">
                Codex {WALKTHROUGH_FIXTURE.proposalOpinions.codex} · Claude {WALKTHROUGH_FIXTURE.proposalOpinions.claude} · {COPY.agree}
              </span>
              <span className={`srt-proposal__status is-${decision}`}>{statusText}</span>
            </p>
            <div className="srt-proposal__diff">
              <p>
                <span className="srt-dim">지금</span> {original.text}
              </p>
              <p>
                <span className="srt-dim">제안</span>{" "}
                {diffWords(original.text, proposal.text).map(({ word, changed }, i) => (
                  <span key={i}>
                    {i > 0 && " "}
                    {changed ? <ins>{word}</ins> : word}
                  </span>
                ))}
              </p>
            </div>
            <dl className="srt-facts srt-facts--grid">
              <div>
                <dt>reason</dt>
                <dd>{proposal.reason}</dd>
              </div>
              <div>
                <dt>source</dt>
                <dd>{proposal.source}</dd>
              </div>
              <div>
                <dt>uncertainty</dt>
                <dd>{proposal.uncertainty}</dd>
              </div>
              <div>
                <dt>needsReview</dt>
                <dd>{proposal.needsReview ? "예" : "아니요"}</dd>
              </div>
            </dl>
            <div className="srt-proposal__actions">
              <button type="button" className="srt-btn srt-btn--primary" aria-pressed={decision === "accepted"} onClick={() => onDecide(proposal.id, "accepted")}>
                {COPY.accept}
              </button>
              <button type="button" className="srt-btn" aria-pressed={decision === "held"} onClick={() => onDecide(proposal.id, "held")}>
                {COPY.hold}
              </button>
              <button type="button" className="srt-btn srt-btn--quiet" aria-disabled={decision === "pending"} onClick={decision === "pending" ? undefined : () => onUndo(proposal.id)}>
                <ArrowCounterClockwiseIcon size={16} aria-hidden="true" />
                {COPY.undo}
              </button>
            </div>
            <p className="srt-dim" aria-live="polite">
              {result.alignmentStale ? COPY.stale : "시간은 바뀌지 않습니다. 제안 형식에 시간 필드가 없습니다."}
            </p>
          </article>
        );
      })}
    </div>
  );
}
