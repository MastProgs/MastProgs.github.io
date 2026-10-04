// Voice to SRT 처리 원리(순수 함수, node:test 가 직접 import). 화면(SubtitlesPage)은 buildWalkthrough 결과만 읽는다.
// AI-NOTE: 원본 문서·소스의 규칙을 작게 옮긴 것이다(실제 인식·정렬·AI 호출은 하지 않는다).
// - 자막 시간은 단어 정렬 시각에서만 만든다(cueFromWords). AI 응답은 글자가 같은 문장 묶음이어야 하고 시간 필드가 있으면 거부한다
//   (원본 internal/core/segment.go ValidateSentences). 문장 경계가 단어 중간이면 쓰지 않는다.
// - 표시 시간 보정(padDisplay): VAD 말소리가 이어질 때만 최대 0.3초 넓히고, 줄이지 않고, 앞뒤 자막을 넘지 않으며, 정렬 시각은 보존한다.
// - 교정 제안(validateProposal): 원본 review.go ReviewProposal 의 필드(id·text·reason·source·uncertainty·needsReview)만 허용, 시간 필드 거부.
// - 결과 배열·객체는 모두 freeze 한다(React props 로 넘어가도 작은 고정 데이터).

export const MAX_DISPLAY_PAD_MS = 300;
export const PAUSE_MARK_MS = 300;
export const LEVEL_STEP_MS = 100;
export const PROPOSAL_FIELDS = Object.freeze(["id", "text", "reason", "source", "uncertainty", "needsReview"]);
// 시간 필드로 보는 이름: start·end·time·duration·offset 로 시작하거나 Ms 로 끝나는 키(startMs, endMs, time, durationSec …).
const isTimeField = (key) => /^(start|end|time|duration|offset)/i.test(key) || /Ms$/.test(key);

const deepFreeze = (value) => {
  if (value && typeof value === "object" && !Object.isFrozen(value)) {
    for (const child of Object.values(value)) deepFreeze(child);
    Object.freeze(value);
  }
  return value;
};

const letters = (text) => String(text).replace(/[\s.,!?…~'"“”‘’·]/g, "");

// ── 단어 → 자막 ────────────────────────────────────────────
export function cueFromWords(words, from, to) {
  if (!(from >= 0 && to < words.length && from <= to)) throw new Error(`잘못된 단어 범위 ${from}..${to}`);
  const slice = words.slice(from, to + 1);
  return { from, to, startMs: slice[0].startMs, endMs: slice[slice.length - 1].endMs, spoken: slice.map((word) => word.text).join(" ") };
}

// cuts: 그 단어 "뒤"에서 끊는 단어 번호들. 끊는 시각은 항상 단어 경계(앞 단어 끝 / 다음 단어 시작)다.
export function splitAtWordCuts(words, cuts) {
  const sorted = [...new Set(cuts)].sort((a, b) => a - b);
  for (const cut of sorted) if (!Number.isInteger(cut) || cut < 0 || cut >= words.length - 1) throw new Error(`단어 경계가 아님: ${cut}`);
  const cues = [];
  let from = 0;
  for (const cut of [...sorted, words.length - 1]) {
    cues.push(cueFromWords(words, from, cut));
    from = cut + 1;
  }
  return cues;
}

// AI 문장 나누기 응답 → 끊는 단어 번호. 글자가 다르거나, 시간 필드가 있거나, 단어 중간에서 끊으면 null(그 묶음은 쓰지 않음).
export function sentencesToCuts(words, sentences) {
  if (!Array.isArray(sentences) || sentences.length === 0) return null;
  const texts = [];
  for (const item of sentences) {
    if (typeof item === "string") texts.push(item);
    else if (item && typeof item === "object") {
      if (Object.keys(item).some(isTimeField)) return null;
      texts.push(item.text);
    } else return null;
  }
  if (texts.some((text) => typeof text !== "string" || letters(text) === "")) return null;
  if (letters(texts.join("")) !== letters(words.map((word) => word.text).join(""))) return null;
  // 단어별 누적 글자 수 경계와 문장별 누적 글자 수가 맞아야 한다.
  const wordEnds = [];
  let total = 0;
  for (const word of words) {
    total += letters(word.text).length;
    wordEnds.push(total);
  }
  const cuts = [];
  let acc = 0;
  for (let i = 0; i < texts.length - 1; i += 1) {
    acc += letters(texts[i]).length;
    const index = wordEnds.indexOf(acc);
    if (index < 0) return null;
    cuts.push(index);
  }
  return cuts;
}

// ── 쉼·소리 크기 ───────────────────────────────────────────
// 단어 사이 간격과 VAD 의 쉼 중 긴 쪽(원본: 정렬이 단어 끝을 늘려 잡아도 실제 쉼을 알 수 있게).
export function wordPauses(words, vad = [], minMs = PAUSE_MARK_MS) {
  const pauses = [];
  for (let i = 0; i < words.length - 1; i += 1) {
    const gapStart = words[i].endMs;
    const gapEnd = words[i + 1].startMs;
    let vadSilence = 0;
    for (let s = 0; s < vad.length - 1; s += 1) {
      const silenceStart = vad[s].endMs;
      const silenceEnd = vad[s + 1].startMs;
      if (silenceEnd > words[i].startMs && silenceStart < words[i + 1].endMs) vadSilence = Math.max(vadSilence, silenceEnd - silenceStart);
    }
    const ms = Math.max(gapEnd - gapStart, vadSilence);
    if (ms >= minMs) pauses.push({ after: i, startMs: gapStart, endMs: gapEnd, ms });
  }
  return pauses;
}

// 0.1초마다 소리 크기 0~9(예시 데이터용 결정적 값: 단어 안은 4~8, 단어 밖은 0~1). 실제 앱은 PCM 에너지에서 만든다.
export function levelsFor(words, durationMs, stepMs = LEVEL_STEP_MS) {
  const levels = [];
  for (let t = 0; t < durationMs; t += stepMs) {
    const mid = t + stepMs / 2;
    const index = words.findIndex((word) => mid >= word.startMs && mid < word.endMs);
    levels.push(index < 0 ? (t / stepMs) % 3 === 0 ? 1 : 0 : 4 + ((index * 3 + t / stepMs) % 5));
  }
  return levels;
}

// ── 표시 시간 보정 ─────────────────────────────────────────
// 앞 자막의 (넓힌) 표시 끝과 다음 자막의 정렬 시작을 넘지 않으므로 표시 시간끼리 겹치지 않는다. startMs·endMs(정렬 시각)는 그대로 둔다.
export function padDisplay(cues, vad, maxPadMs = MAX_DISPLAY_PAD_MS) {
  const out = [];
  cues.forEach((cue, i) => {
    const prevLimit = i > 0 ? out[i - 1].displayEndMs : 0;
    const nextLimit = i < cues.length - 1 ? cues[i + 1].startMs : Infinity;
    const startSeg = vad.find((seg) => seg.startMs <= cue.startMs && seg.endMs > cue.startMs);
    const endSeg = vad.find((seg) => seg.startMs < cue.endMs && seg.endMs >= cue.endMs);
    const displayStartMs = startSeg ? Math.max(startSeg.startMs, cue.startMs - maxPadMs, prevLimit) : cue.startMs;
    const displayEndMs = endSeg ? Math.min(endSeg.endMs, cue.endMs + maxPadMs, nextLimit) : cue.endMs;
    out.push({ ...cue, displayStartMs: Math.min(displayStartMs, cue.startMs), displayEndMs: Math.max(displayEndMs, cue.endMs) });
  });
  return out;
}

// ── 교정 제안 ──────────────────────────────────────────────
export function validateProposal(proposal, knownIds) {
  if (!proposal || typeof proposal !== "object") return { ok: false, reason: "형식" };
  const keys = Object.keys(proposal);
  if (keys.some(isTimeField)) return { ok: false, reason: "시간 변경 필드" };
  if (keys.some((key) => !PROPOSAL_FIELDS.includes(key))) return { ok: false, reason: "허용하지 않는 필드" };
  if (!knownIds.includes(proposal.id)) return { ok: false, reason: "알 수 없는 ID" };
  if (typeof proposal.text !== "string" || proposal.text.trim() === "") return { ok: false, reason: "빈 필수값" };
  return { ok: true, reason: null };
}

// decisions: { [proposalId]: "accepted" | "held" | undefined }. 수락된 제안만 화면 문구를 바꾸고, 그 자막은 다시 정렬할 상태가 된다.
export function applyDecisions(cues, proposals, decisions = {}) {
  return cues.map((cue) => {
    const proposal = proposals.find((item) => item.id === cue.id);
    const decision = proposal ? decisions[proposal.id] ?? "pending" : null;
    if (proposal && decision === "accepted") return { ...cue, text: proposal.text, decision, alignmentStale: true };
    return { ...cue, decision, alignmentStale: false };
  });
}

// ── SRT ───────────────────────────────────────────────────
export function formatSrtTime(ms) {
  const value = Math.max(0, Math.round(ms));
  const pad = (n, width = 2) => String(n).padStart(width, "0");
  return `${pad(Math.floor(value / 3600000))}:${pad(Math.floor(value / 60000) % 60)}:${pad(Math.floor(value / 1000) % 60)},${pad(value % 1000, 3)}`;
}

export const formatSeconds = (ms) => `${(ms / 1000).toFixed(2)}초`;

export function toSrt(cues) {
  return [...cues]
    .sort((a, b) => a.displayStartMs - b.displayStartMs)
    .map((cue, index) => `${index + 1}\n${formatSrtTime(cue.displayStartMs)} --> ${formatSrtTime(cue.displayEndMs)}\n${cue.text}`)
    .join("\n\n");
}

// ── 예시 전체를 단계 데이터로 ───────────────────────────────
// 화면은 이 결과(작은 고정 객체)만 읽는다. 사람의 결정(decisions)은 SRT 단계에서 finalCues 로 반영한다.
export function buildWalkthrough(fixture) {
  const { words, vad, durationMs } = fixture;
  const whole = padDisplay([cueFromWords(words, 0, words.length - 1)], vad);
  const pauses = wordPauses(words, vad);
  const levels = levelsFor(words, durationMs);
  const codexCuts = sentencesToCuts(words, fixture.split.codex.sentences);
  const claudeCuts = sentencesToCuts(words, fixture.split.claude.sentences);
  if (!codexCuts || !claudeCuts) throw new Error("예시 문장 나누기 응답이 원래 글자와 다릅니다");
  // 두 AI 가 같은 곳은 바로, 갈린 곳은 토론 마지막 판단이 동의일 때만 반영한다.
  const agreed = codexCuts.filter((cut) => claudeCuts.includes(cut));
  const disputed = [...codexCuts, ...claudeCuts].filter((cut) => !(codexCuts.includes(cut) && claudeCuts.includes(cut)));
  const lastRound = fixture.split.debate[fixture.split.debate.length - 1];
  const resolved = lastRound && lastRound.claude === "동의" ? disputed : [];
  const cuts = [...agreed, ...resolved].sort((a, b) => a - b);
  const cues = padDisplay(splitAtWordCuts(words, cuts), vad).map((cue, i) => ({ ...cue, id: `cue-${i + 1}`, text: fixture.displayTexts[i] }));
  const knownIds = cues.map((cue) => cue.id);
  const proposals = fixture.proposals.filter((proposal) => validateProposal(proposal, knownIds).ok);
  return deepFreeze({
    durationMs,
    words: words.map((word, index) => ({ ...word, index, risk: fixture.compareDiff.index === index ? fixture.compareDiff.text : null })),
    rawText: words.map((word) => word.text).join(" "),
    vad,
    whole: whole[0],
    pauses,
    levels,
    split: { codexCuts, claudeCuts, agreed, disputed, resolved, cuts, debate: fixture.split.debate, codexReason: fixture.split.codex.reason, claudeReason: fixture.split.claude.reason },
    cues,
    proposals,
  });
}

export const finalCues = (walkthrough, decisions) => applyDecisions(walkthrough.cues, walkthrough.proposals, decisions);

// ── 단계 이동(재생기) ───────────────────────────────────────
// state: { stage, playing }. 이전·다음·고르기는 멈춘다. 끝에서 재생하면 처음부터 한 번 다시(자동 반복 없음).
export const STAGE_INTERVAL_MS = 2600;
export function stageReducer(state, action, total) {
  const last = total - 1;
  const clamp = (value) => Math.min(last, Math.max(0, value));
  switch (action.type) {
    case "prev":
      return { stage: clamp(state.stage - 1), playing: false };
    case "next":
      return { stage: clamp(state.stage + 1), playing: false };
    case "seek":
      return Number.isInteger(action.stage) ? { stage: clamp(action.stage), playing: false } : state;
    case "play":
      return { stage: state.stage >= last ? 0 : state.stage, playing: true };
    case "pause":
      return state.playing ? { ...state, playing: false } : state;
    case "reset":
      return { stage: 0, playing: false };
    case "tick":
      if (!state.playing) return state;
      return state.stage + 1 >= last ? { stage: last, playing: false } : { stage: state.stage + 1, playing: true };
    default:
      return state;
  }
}
