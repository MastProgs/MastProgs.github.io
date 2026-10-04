import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import path from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import { stripComments } from "./strip-comments.mjs";
import { CASES, NAV_LINKS, SECTION_IDS, SUBTITLES_ROUTE } from "../src/content/site.js";
import {
  SUBTITLE_BOUNDARY,
  SUBTITLE_EDITOR,
  SUBTITLE_PIPELINE,
  SUBTITLE_STRUCTURE,
  SUBTITLE_USES,
  SUBTITLES_PAGE,
  WALKTHROUGH_COPY,
  WALKTHROUGH_FIXTURE as FIX,
  WALKTHROUGH_STAGES,
} from "../src/content/subtitles.js";
import {
  MAX_DISPLAY_PAD_MS,
  PROPOSAL_FIELDS,
  applyDecisions,
  buildWalkthrough,
  cueFromWords,
  finalCues,
  formatSrtTime,
  levelsFor,
  padDisplay,
  sentencesToCuts,
  splitAtWordCuts,
  stageReducer,
  toSrt,
  validateProposal,
  wordPauses,
} from "../src/subtitles/model.js";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (relative) => readFileSync(path.join(root, relative), "utf8");
const code = (relative) => stripComments(read(relative));
const WALK = buildWalkthrough(FIX);

// ── 단어 정렬 → 끊는 시각 ───────────────────────────────────

test("break times come only from aligned word times; the AI returns same-letter sentences without times", () => {
  assert.deepEqual(WALK.split.codexCuts, [4, 9]);
  assert.deepEqual(WALK.split.claudeCuts, [4]);
  assert.deepEqual(WALK.split.agreed, [4], "the shared cut is applied directly");
  assert.deepEqual(WALK.split.disputed, [9]);
  assert.deepEqual(WALK.split.cuts, [4, 9], "the disputed cut is applied only after the final debate round agrees");
  assert.ok(FIX.split.debate.length <= 2, "at most two debate rounds");
  for (const cue of WALK.cues) {
    assert.equal(cue.startMs, FIX.words[cue.from].startMs, `${cue.id} start = first word start`);
    assert.equal(cue.endMs, FIX.words[cue.to].endMs, `${cue.id} end = last word end`);
  }
  // 응답 객체에 시간 필드가 없다(예시 데이터 자체도 원본 형식을 따른다).
  for (const side of [FIX.split.codex, FIX.split.claude]) {
    assert.ok(side.sentences.every((sentence) => typeof sentence === "string"));
    assert.deepEqual(Object.keys(side).sort(), ["reason", "sentences"]);
  }
});

test("sentence validation rejects changed letters, time fields, empty sentences and mid-word boundaries", () => {
  const words = FIX.words;
  assert.equal(sentencesToCuts(words, ["자 그럼 오늘 일정부터 확인할게요", "먼저 장비를 점검하고 광장에서 모입시다 아 잠깐만요"]), null, "letters changed");
  assert.equal(sentencesToCuts(words, ["자 그럼 오늘 일정부터 확인할게요"]), null, "letters dropped");
  assert.equal(sentencesToCuts(words, [{ text: FIX.split.codex.sentences.join(" "), startMs: 0 }]), null, "time field");
  assert.equal(sentencesToCuts(words, [{ text: FIX.split.codex.sentences.join(" "), end: 10 }]), null, "time field");
  assert.equal(sentencesToCuts(words, [FIX.split.codex.sentences.join(" "), " . "]), null, "empty sentence");
  assert.equal(sentencesToCuts(words, ["자 그럼 오늘 일정", "부터 확인할게요 먼저 장비를 점검하고 광장애서 모입시다 아 잠깐만요"]), null, "mid-word boundary");
  assert.deepEqual(sentencesToCuts(words, [{ text: "자, 그럼 오늘 일정부터 확인할게요." }, { text: "먼저 장비를 점검하고 광장애서 모입시다. 아, 잠깐만요!", reason: "x" }]), [4], "punctuation/spacing only is the same letters");
  assert.throws(() => splitAtWordCuts(words, [11]), "cannot cut after the last word");
  assert.throws(() => splitAtWordCuts(words, [1.5]));
  assert.throws(() => cueFromWords(words, 3, 2));
});

test("pauses use the longer of the word gap and the VAD silence; levels are 0..9 per 100 ms", () => {
  assert.deepEqual(
    WALK.pauses.map((pause) => [pause.after, pause.ms]),
    [
      [4, 640],
      [9, 420],
    ],
  );
  // VAD 쉼이 단어 간격보다 길면 VAD 쪽을 쓴다.
  const words = [
    { text: "가", startMs: 0, endMs: 900 },
    { text: "나", startMs: 950, endMs: 1500 },
  ];
  assert.deepEqual(wordPauses(words, [{ startMs: 0, endMs: 500 }, { startMs: 1000, endMs: 1500 }]).map((pause) => pause.ms), [500]);
  assert.equal(WALK.levels.length, FIX.durationMs / 100);
  assert.ok(WALK.levels.every((level) => Number.isInteger(level) && level >= 0 && level <= 9));
  assert.deepEqual(levelsFor(FIX.words, FIX.durationMs), [...WALK.levels], "deterministic");
});

// ── 표시 시간 보정 ─────────────────────────────────────────

test("display padding: at most 0.3 s, only into VAD speech, never shrinks, never crosses neighbours, raw times preserved", () => {
  assert.deepEqual([WALK.whole.startMs, WALK.whole.endMs], [300, 7180]);
  assert.deepEqual([WALK.whole.displayStartMs, WALK.whole.displayEndMs], [260, 7480], "end capped at +0.3 s although VAD continues");
  assert.deepEqual(
    WALK.cues.map((cue) => [cue.displayStartMs, cue.displayEndMs]),
    [
      [260, 2700],
      [3100, 5900],
      [6150, 7480],
    ],
  );
  WALK.cues.forEach((cue, i) => {
    assert.ok(cue.displayStartMs <= cue.startMs && cue.displayEndMs >= cue.endMs, "never shrinks");
    assert.ok(cue.startMs - cue.displayStartMs <= MAX_DISPLAY_PAD_MS && cue.displayEndMs - cue.endMs <= MAX_DISPLAY_PAD_MS);
    if (i > 0) assert.ok(cue.displayStartMs >= WALK.cues[i - 1].displayEndMs, "no overlap with the previous cue");
  });
  // 이웃 경계: 다음 자막이 바로 붙어 있으면 넓히지 않는다. VAD 밖이면 넓히지 않는다.
  const tight = padDisplay(
    [
      { startMs: 1000, endMs: 2000 },
      { startMs: 2100, endMs: 3000 },
    ],
    [{ startMs: 500, endMs: 3600 }],
  );
  assert.deepEqual(tight.map((cue) => [cue.displayStartMs, cue.displayEndMs]), [[700, 2100], [2100, 3300]]);
  assert.deepEqual(tight.map((cue) => [cue.startMs, cue.endMs]), [[1000, 2000], [2100, 3000]], "raw word times untouched");
  const silent = padDisplay([{ startMs: 1000, endMs: 2000 }], [{ startMs: 5000, endMs: 6000 }]);
  assert.deepEqual([silent[0].displayStartMs, silent[0].displayEndMs], [1000, 2000]);
});

// ── 교정 제안 · 사람 결정 · SRT ─────────────────────────────

test("proposal schema matches the original review fields; time fields, unknown ids and empty text are rejected", () => {
  assert.deepEqual(PROPOSAL_FIELDS, ["id", "text", "reason", "source", "uncertainty", "needsReview"]);
  assert.deepEqual(SUBTITLE_BOUNDARY.proposalFields, [...PROPOSAL_FIELDS]);
  const ids = WALK.cues.map((cue) => cue.id);
  assert.equal(WALK.proposals.length, 1);
  assert.deepEqual(Object.keys(WALK.proposals[0]).sort(), [...PROPOSAL_FIELDS].sort());
  assert.deepEqual(validateProposal(FIX.proposals[0], ids), { ok: true, reason: null });
  assert.equal(validateProposal({ ...FIX.proposals[0], startMs: 10 }, ids).reason, "시간 변경 필드");
  assert.equal(validateProposal({ ...FIX.proposals[0], endMs: 10 }, ids).reason, "시간 변경 필드");
  assert.equal(validateProposal({ ...FIX.proposals[0], extra: 1 }, ids).reason, "허용하지 않는 필드");
  assert.equal(validateProposal({ ...FIX.proposals[0], id: "cue-9" }, ids).reason, "알 수 없는 ID");
  assert.equal(validateProposal({ ...FIX.proposals[0], text: "  " }, ids).reason, "빈 필수값");
});

test("human decisions: pending/held keep the text, accepted replaces it and marks re-alignment; times never change; SRT follows", () => {
  const pending = finalCues(WALK, {});
  const held = finalCues(WALK, { "cue-2": "held" });
  const accepted = finalCues(WALK, { "cue-2": "accepted" });
  assert.equal(pending[1].text, FIX.displayTexts[1]);
  assert.equal(held[1].text, FIX.displayTexts[1]);
  assert.equal(accepted[1].text, FIX.proposals[0].text);
  assert.deepEqual([pending[1].decision, held[1].decision, accepted[1].decision], ["pending", "held", "accepted"]);
  assert.equal(accepted[1].alignmentStale, true, "spoken text changed → word alignment must be redone");
  assert.equal(pending[0].decision, null, "cues without a proposal have no decision");
  for (const list of [pending, held, accepted]) {
    list.forEach((cue, i) => assert.deepEqual([cue.displayStartMs, cue.displayEndMs], [WALK.cues[i].displayStartMs, WALK.cues[i].displayEndMs]));
  }
  assert.equal(formatSrtTime(3723004), "01:02:03,004");
  const srt = toSrt(accepted);
  assert.equal(
    srt,
    [
      "1\n00:00:00,260 --> 00:00:02,700\n자, 그럼 오늘 일정부터 확인할게요.",
      "2\n00:00:03,100 --> 00:00:05,900\n먼저 장비를 점검하고 광장에서 모입시다.",
      "3\n00:00:06,150 --> 00:00:07,480\n아, 잠깐만요!",
    ].join("\n\n"),
  );
  assert.match(toSrt(held), /광장애서/);
  // 시간순 번호.
  assert.match(toSrt([...accepted].reverse()), /^1\n00:00:00,260/);
  assert.equal(applyDecisions(WALK.cues, WALK.proposals, { "cue-2": "accepted" })[1].text, FIX.proposals[0].text);
});

// ── 단계 재생기 ────────────────────────────────────────────

test("stage transport: prev/next/seek pause, play from the end restarts once, ticks stop at the last stage", () => {
  const total = WALKTHROUGH_STAGES.length;
  assert.equal(total, 6);
  const run = (state, action) => stageReducer(state, action, total);
  let state = { stage: 0, playing: false };
  assert.deepEqual(run(state, { type: "prev" }), { stage: 0, playing: false });
  state = run(state, { type: "play" });
  assert.deepEqual(state, { stage: 0, playing: true });
  for (let i = 0; i < 10; i += 1) state = run(state, { type: "tick" });
  assert.deepEqual(state, { stage: total - 1, playing: false }, "stops at the end, no loop");
  assert.equal(run(state, { type: "tick" }), state, "ticks while paused do nothing");
  assert.deepEqual(run(state, { type: "play" }), { stage: 0, playing: true }, "play from the end replays from the start");
  assert.deepEqual(run({ stage: 2, playing: true }, { type: "next" }), { stage: 3, playing: false });
  assert.deepEqual(run({ stage: 2, playing: true }, { type: "seek", stage: 5 }), { stage: 5, playing: false });
  assert.deepEqual(run({ stage: 2, playing: true }, { type: "seek", stage: 99 }), { stage: 5, playing: false });
  assert.deepEqual(run({ stage: 3, playing: true }, { type: "reset" }), { stage: 0, playing: false });
  const same = { stage: 1, playing: false };
  assert.equal(run(same, { type: "pause" }), same);
  assert.equal(run(same, { type: "nope" }), same);
});

test("walkthrough data is small, frozen and built once at module scope (no repeated React prop churn)", () => {
  assert.ok(Object.isFrozen(WALK) && Object.isFrozen(WALK.cues) && Object.isFrozen(WALK.cues[0]) && Object.isFrozen(WALK.levels));
  assert.ok(Object.isFrozen(FIX) && Object.isFrozen(FIX.words) && Object.isFrozen(FIX.words[0]));
  assert.ok(FIX.words.length <= 20 && WALK.levels.length <= 120, "tiny synthetic fixture");
  const walk = code("src/components/subtitles/SubtitleWalkthrough.jsx");
  assert.match(walk, /^const WALK = buildWalkthrough\(WALKTHROUGH_FIXTURE\);/m);
  assert.doesNotMatch(walk, /useMemo\(\(\) => buildWalkthrough/, "not rebuilt per render");
  assert.equal((walk.match(/window\.setTimeout\(/g) ?? []).length, 1);
  assert.match(walk, /return \(\) => window\.clearTimeout\(timer\)/);
  assert.match(walk, /removeEventListener\("visibilitychange"/);
  assert.match(walk, /\{ stage: 0, playing: false \}/, "never autoplays on load");
});

// ── 페이지 · 사례 · 정책 ────────────────────────────────────

// (갱신, 사용자 최신 지시 "여기에 srt 도 추가하자") 예전 "메인 섹션·내비게이션에 없음" 검사는 대체됐다. 메인에는 03 핵심 구현 하위 항목
// #subtitles 요약이 있고(tests/core-group.test.mjs), 상위 내비게이션에는 따로 넣지 않는다. 상세 라우트는 여전히 별도 청크다.
test("/subtitles route: lazy chunk, one h1, back link, theme toggle, case dialog; only a 핵심 구현 child on main, not a top nav entry", () => {
  assert.equal(SUBTITLES_ROUTE, "/subtitles");
  const app = read("src/App.jsx");
  assert.match(app, /isSubtitles: path === SUBTITLES_ROUTE/);
  assert.match(app, /const SubtitlesPage = lazy\(\(\) => import\("\.\/components\/subtitles\/SubtitlesPage\.jsx"\)/);
  assert.match(app, /<Suspense fallback=\{null\}>\s*<SubtitlesPage \/>/);
  assert.doesNotMatch(app, /import \{ SubtitlesPage \}|content\/subtitles\.js|subtitles\/model\.js/, "no static import into the main chunk");
  const page = code("src/components/subtitles/SubtitlesPage.jsx");
  assert.equal((page.match(/<h1[\s>]/g) ?? []).length, 1);
  assert.equal((code("src/components/subtitles/SubtitleWalkthrough.jsx").match(/<h1[\s>]/g) ?? []).length, 0);
  assert.match(page, /<a className="wfd-top__back" href="\/">/);
  assert.match(page, /<ThemeToggle compact \/>/);
  assert.match(page, /item\.id === "case-subtitles"/);
  assert.match(page, /<CaseDialog item=\{caseOpen \? SUBTITLE_CASE : null\}/);
  assert.ok(!NAV_LINKS.some((link) => /subtitle|자막|Voice/i.test(`${link.href}${link.label}`)), "no separate top nav entry");
  assert.equal(SECTION_IDS.subtitles, "subtitles", "child anchor inside 핵심 구현");
  assert.match(read("src/styles.css"), /@import "\.\/styles\/subtitles\.css";/);
});

// 소개 판은 어두운 테마에서도 밝은 stage 판이다. 공용 .srt-btn(color: var(--ink))이 사례 버튼 글자를 흰색으로 덮지 않아야 한다.
test("intro case button keeps stage ink on the light intro panel for default, hover and focus (beats shared .srt-btn)", () => {
  // CSS 는 JS 파서로 주석을 지울 수 없으므로 블록 주석만 제거한다.
  const css = read("src/styles/subtitles.css").replace(/\/\*[\s\S]*?\*\//g, "");
  const page = code("src/components/subtitles/SubtitlesPage.jsx");
  assert.match(page, /className="srt-btn srt-intro__case"/);
  const rules = [...css.matchAll(/([^{}]+)\{([^}]*)\}/g)].map((m, order) => ({ selectors: m[1].split(",").map((s) => s.trim()), body: m[2], order }));
  const ruleFor = (selector) => rules.filter((rule) => rule.selectors.includes(selector));
  const prop = (body, name) => body.match(new RegExp(`(?:^|;|\\s)${name}:\\s*([^;]+);`))?.[1].trim();
  for (const state of ["", ":hover", ":focus-visible"]) {
    const own = ruleFor(`.srt-btn.srt-intro__case${state}`);
    assert.ok(own.length, `rule for ${state || "default"}`);
    const last = own.at(-1);
    assert.equal(prop(last.body, "color"), "var(--stage-ink)", `${state || "default"} text uses stage ink`);
    assert.doesNotMatch(last.body, /var\(--(ink|ink-2|hover-wash)\)/, `${state || "default"} avoids page-theme tokens`);
    // 같은 상태의 공용 규칙보다 뒤에 있어야 특이성이 같아도 이긴다.
    for (const shared of ruleFor(`.srt-btn${state}`)) assert.ok(last.order > shared.order, `${state || "default"} comes after shared .srt-btn${state}`);
  }
  assert.ok(!ruleFor(".srt-intro__case").some((rule) => prop(rule.body, "color")), "no lone single-class colour rule that the shared button overrides");
});

test("subtitles page performs no ASR, network, upload, audio playback or persistence", () => {
  for (const file of ["src/components/subtitles/SubtitlesPage.jsx", "src/components/subtitles/SubtitleWalkthrough.jsx", "src/subtitles/model.js", "src/content/subtitles.js"]) {
    const text = code(file);
    assert.doesNotMatch(text, /fetch\(|XMLHttpRequest|WebSocket|localStorage|sessionStorage|indexedDB|<audio|<video|autoPlay|new Audio|getUserMedia|type="file"|FormData/, file);
  }
});

test("content covers the real pipeline facts, keeps the AI timing boundary and makes no metric or disclaimer claims", () => {
  const all = JSON.stringify([SUBTITLES_PAGE, SUBTITLE_PIPELINE, SUBTITLE_BOUNDARY, SUBTITLE_EDITOR, SUBTITLE_STRUCTURE, SUBTITLE_USES, WALKTHROUGH_STAGES, WALKTHROUGH_COPY]);
  for (const fact of ["FFmpeg", "VAD", "Qwen 한국어", "large-v3", "large-v2", "turbo", "강제 정렬", "0.3초", "0.1초", "Codex", "Claude", "두 번", "수락", "보류", "실행 취소", "SRT", "CP949", "UTF-8 BOM", "Electron", "Go", "Python CUDA", "찾아 바꾸기", "나누기", "합치기", "개발 중"]) {
    assert.ok(all.includes(fact), `mentions ${fact}`);
  }
  assert.match(all, /시간을 지어내지 않습니다|시간 만들기/, "AI does not invent timestamps");
  assert.match(all, /오디오는 외부로 보내지 않습니다/);
  assert.doesNotMatch(all, /\d+\s*%|\d+\s*배\s*(빠|향상)|정확도\s*\d|WER|CER|출시|정식 버전/, "no quality/speed metrics or release claims");
  assert.doesNotMatch(all, /설명용|데모|실제 AI 아님|실제 AI를 호출하지/, "no disclaimers");
  assert.doesNotMatch(all, /\p{Extended_Pictographic}/u, "no emoji");
  assert.doesNotMatch(all, /[A-Za-z]:[\\/]|\\Devlop|ai-log|\.wav|\.mp4|\.env/, "no private paths, logs or media names");
});

test("case rail order: AgentWorkflow, Hero Pixel Studio, Voice to SRT, KETI, intake with stable ids and sequential indices", () => {
  assert.deepEqual(
    CASES.map((item) => [item.index, item.id]),
    [
      ["01", "case-agentworkflow"],
      ["02", "case-pixel"],
      ["03", "case-subtitles"],
      ["04", "case-keti"],
      ["05", "case-intake"],
    ],
  );
  const voice = CASES.find((item) => item.id === "case-subtitles");
  assert.equal(voice.title, "Voice to SRT");
  assert.equal(voice.mediaKind, "diagram");
  assert.equal(voice.image, undefined, "no fabricated screenshot");
  assert.ok(voice.diagram.steps.length >= 5);
  assert.match(voice.evidence, /원본 앱 화면 캡처는 아닙니다/);
  // 원본 이미지 사례는 그대로: 실제 파일·캡션 유지.
  for (const item of CASES.filter((entry) => entry.mediaKind !== "diagram")) {
    assert.ok(existsSync(path.join(root, "public", item.image.src)), item.image.src);
    assert.ok(item.image.alt.length > 10);
  }
  assert.deepEqual(
    CASES.filter((item) => item.image).map((item) => item.image.src),
    ["/cases/master_overview.png", "/cases/hero_pixel_studio_screen.png", "/cases/mlops_flow.png", "/cases/intake_flow.png"],
    "existing source images unchanged",
  );
  const dialog = code("src/components/cases/CaseDialog.jsx");
  assert.match(dialog, /item\.mediaKind === "diagram"/);
  assert.match(dialog, /원본 자료 · 정적 참고 이미지/, "real image evidence caption kept");
  assert.match(dialog, /처리 원리 도식/);
  assert.match(dialog, /href=\{detailRoute\} target="_blank" rel="noopener noreferrer"/);
  assert.match(dialog, /"case-subtitles": SUBTITLES_ROUTE/);
  const rail = code("src/components/cases/CasesSection.jsx");
  assert.match(rail, /<CaseDiagram ref=/);
  assert.match(rail, /CASES\.map/);
  const diagram = code("src/components/cases/CaseDiagram.jsx");
  assert.doesNotMatch(diagram, /<svg|<img/, "diagram uses library icons and markup only");
});
