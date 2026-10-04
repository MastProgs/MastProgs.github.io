import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { stripComments } from "./strip-comments.mjs";
import { DEFAULT_PALETTE_RATIO, DEFAULT_SET_ID, PIXEL_COPY, PIXEL_PRESETS, SOURCE_SET_ID } from "../src/content/pixelStudio.js";
import { OWNED_TIMING_BUDGET, REACT_TIMING_PREFIX, timingNameFor, trimOwnedTimings } from "../src/lib/devTimings.js";
import { buildLayerModel, compositeFrame, indicesToRgba, sourceColorTable } from "../src/pixel/layers.js";
import { buildPaletteMap, extractPalette, hexToRgb } from "../src/pixel/palette.js";
import { buildPaletteSets, colorShares } from "../src/pixel/paletteSets.js";
import { processFrame } from "../src/pixel/pipeline.js";
import { createShuffleBag, stepPlayback } from "../src/pixel/playback.js";
import { buildSpriteModel } from "../src/pixel/sprite.js";
import {
  INITIAL_STYLE,
  advancePlayback,
  autoOutlineColor,
  effectiveOutlineColor,
  needsNextMotion,
  planTick,
  resolvePaletteSet,
  styleReducer,
} from "../src/pixel/studio.js";
import { OUTLINE_PAD } from "../src/pixel/outline.js";

const read = (relative) => readFileSync(new URL(`../${relative}`, import.meta.url), "utf8");
const code = (relative) => stripComments(read(relative));
const json = (relative) => JSON.parse(read(relative));
const MODEL = buildLayerModel(json("src/content/pixel-layers.json"));
const TABLE = sourceColorTable(json("src/content/pixel-source-colors.json"));
const SETS = buildPaletteSets(json("src/content/pixel-palette-sets.json"));
const SPRITE = buildSpriteModel(json("src/content/pixel-assets.json"));
const SOURCE_PALETTE = extractPalette(MODEL.frames.map((frame) => indicesToRgba(compositeFrame(MODEL, frame.index).indices, TABLE)));
const run = (frameIndex, options = {}) =>
  processFrame({ model: MODEL, table: TABLE, frameIndex, visibility: MODEL.defaultVisibility, pad: OUTLINE_PAD, nearestCache: new Map(), ...options });
const hexOf = (data, i) => `#${((data[i] << 16) | (data[i + 1] << 8) | data[i + 2]).toString(16).padStart(6, "0")}`;

// WCAG 상대 휘도·대비.
const luminance = (hex) => {
  const lin = (v) => {
    const f = v / 255;
    return f <= 0.03928 ? f / 12.92 : ((f + 0.055) / 1.055) ** 2.4;
  };
  const [r, g, b] = hexToRgb(hex);
  return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);
};
const contrast = (a, b) => {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
};

// ── 원본 색상(팔레트 매핑 없음) ─────────────────────────────

test("palette source mode: '원본 색상' bypasses the set mapping, defaults stay AAP-64 at 100%, unknown ids never mean source", () => {
  assert.equal(INITIAL_STYLE.setId, DEFAULT_SET_ID);
  assert.equal(INITIAL_STYLE.ratio, DEFAULT_PALETTE_RATIO);
  assert.deepEqual(resolvePaletteSet(SETS, DEFAULT_SET_ID), { mode: "set", set: SETS[0] });
  assert.equal(SETS[0].name, "AAP-64");
  assert.deepEqual(resolvePaletteSet(SETS, SOURCE_SET_ID), { mode: "source", set: null }, "source never falls back to AAP-64");
  assert.equal(resolvePaletteSet(SETS, "nope").set, SETS[0], "only unknown ids fall back to the first set");
  assert.ok(!SETS.some((set) => set.id === SOURCE_SET_ID), "source id does not collide with an original set id");
  assert.notEqual(SOURCE_SET_ID, PIXEL_PRESETS[0].id, "the first-row 원본 accent preset is a different control");
  assert.equal(PIXEL_COPY.sourceSet, "원본 색상");
});

test("palette source mode: output equals the accent+outline result byte for byte, alpha preserved, never a set colour forced", () => {
  const accentMap = buildPaletteMap(SOURCE_PALETTE, PIXEL_PRESETS.find((preset) => preset.id === "violet").accent);
  const outlineRgb = hexToRgb("#20113d");
  for (const frameIndex of [MODEL.motions.walk[2], MODEL.motions.attack[7]]) {
    const base = run(frameIndex, { accentMap, outlineRgb });
    const { set } = resolvePaletteSet(SETS, SOURCE_SET_ID);
    const source = run(frameIndex, { accentMap, outlineRgb, set, ratio: 1 });
    assert.deepEqual(source.data, base.data, "ratio is ignored when there is no set");
    for (let i = 3; i < source.data.length; i += 4) assert.equal(source.data[i], base.data[i]);
    const mapped = run(frameIndex, { accentMap, outlineRgb, set: SETS[0], ratio: 1 });
    assert.notDeepEqual(mapped.data, source.data, "AAP-64 100% really differs from the source mode");
    // 원본 색상의 통계: 세트가 없으니 '세트 안' 비율 0, 점유율 합 1.
    const shares = colorShares(source.data, null);
    assert.equal(shares.inSetShare, 0);
    assert.ok(Math.abs(shares.entries.reduce((sum, entry) => sum + entry.share, 0) - 1) < 1e-9);
  }
});

test("style reducer: choosing 원본 색상 keeps the ratio value, switching back restores the set at that ratio", () => {
  let style = styleReducer(INITIAL_STYLE, { type: "ratio", value: 40 });
  style = styleReducer(style, { type: "set", id: SOURCE_SET_ID, sets: SETS });
  assert.equal(style.setId, SOURCE_SET_ID);
  assert.equal(style.ratio, 40);
  style = styleReducer(style, { type: "set", id: "db32", sets: SETS });
  assert.deepEqual([style.setId, style.ratio], ["db32", 40]);
  assert.equal(styleReducer(style, { type: "set", id: "unknown", sets: SETS }), style, "invalid ids are ignored");
  assert.equal(styleReducer(style, { type: "ratio", value: "x" }), style);
  assert.equal(styleReducer(style, { type: "ratio", value: 140 }).ratio, 100);
});

// ── 외곽선 자동/직접 ───────────────────────────────────────

test("outline auto colour: dark theme keeps the current preset colours, light theme picks a dark high-contrast outline", () => {
  for (const preset of PIXEL_PRESETS) {
    assert.equal(autoOutlineColor(preset.id, "dark"), preset.outline, `${preset.id} dark unchanged`);
    const light = autoOutlineColor(preset.id, "light");
    assert.equal(light, preset.outlineLight);
    assert.ok(contrast(light, "#ffffff") >= 7, `${preset.id} light outline ${light} contrasts with a light page`);
  }
  assert.equal(effectiveOutlineColor(INITIAL_STYLE, "light"), PIXEL_PRESETS[0].outlineLight);
  assert.equal(effectiveOutlineColor(INITIAL_STYLE, "dark"), PIXEL_PRESETS[0].outline);
});

test("outline manual colour: never overwritten by preset/theme/showcase; auto can be restored; on/off intent kept", () => {
  let style = styleReducer(INITIAL_STYLE, { type: "outlineColor", hex: "#12AB34" });
  assert.deepEqual([style.outlineMode, style.outlineManual, style.outlineOn], ["manual", "#12ab34", true]);
  style = styleReducer(style, { type: "preset", id: "crimson" });
  for (const theme of ["dark", "light"]) assert.equal(effectiveOutlineColor(style, theme), "#12ab34", `${theme} keeps the manual colour`);
  assert.equal(styleReducer(style, { type: "showcase", presetId: "gold", outline: false }), style, "showcase never runs after a manual pick");
  style = styleReducer(style, { type: "toggleOutline" });
  assert.equal(style.outlineOn, false);
  assert.equal(effectiveOutlineColor(style, "dark"), "#12ab34", "turning the outline off keeps the chosen colour");
  style = styleReducer(style, { type: "outlineAuto" });
  assert.equal(style.outlineMode, "auto");
  assert.equal(effectiveOutlineColor(style, "light"), PIXEL_PRESETS.find((preset) => preset.id === "crimson").outlineLight);
  assert.equal(style.outlineOn, false, "returning to auto colour does not switch the outline on");
  assert.equal(styleReducer(INITIAL_STYLE, { type: "outlineColor", hex: "bad" }), INITIAL_STYLE);
});

test("light auto outline + AAP-64 100%: every opaque pixel (outline included) is still the nearest set colour", () => {
  const style = styleReducer(styleReducer(INITIAL_STYLE, { type: "preset", id: "forest" }), { type: "toggleOutline" });
  const outline = effectiveOutlineColor(style, "light");
  const accentMap = buildPaletteMap(SOURCE_PALETTE, PIXEL_PRESETS.find((preset) => preset.id === "forest").accent);
  const { set } = resolvePaletteSet(SETS, style.setId);
  const members = new Set(set.colors);
  const base = run(MODEL.motions.run[1], { accentMap, outlineRgb: hexToRgb(outline) });
  const full = run(MODEL.motions.run[1], { accentMap, outlineRgb: hexToRgb(outline), set, ratio: style.ratio / 100 });
  let outlinePixels = 0;
  for (let i = 0; i < full.data.length; i += 4) {
    assert.equal(full.data[i + 3], base.data[i + 3], "alpha unchanged");
    if (full.data[i + 3] === 0) continue;
    assert.ok(members.has(hexOf(full.data, i)));
    if (hexOf(base.data, i) === outline) outlinePixels += 1;
  }
  assert.ok(outlinePixels > 50, "the dark outline is really drawn before mapping");
});

test("style changes never touch playback: the reducer has no playing field and style actions only dispatch", () => {
  const actions = [
    { type: "preset", id: "gold" },
    { type: "accent", hex: "#334455" },
    { type: "toggleOutline" },
    { type: "outlineColor", hex: "#101010" },
    { type: "outlineAuto" },
    { type: "set", id: SOURCE_SET_ID, sets: SETS },
    { type: "ratio", value: 10 },
  ];
  let style = INITIAL_STYLE;
  for (const action of actions) {
    style = styleReducer(style, action);
    assert.ok(!("playing" in style) && !("playback" in style), `${action.type} result has no playback field`);
  }
  assert.doesNotMatch(code("src/pixel/studio.js"), /playing|setPlaying/);
  const hook = code("src/hooks/usePixelPreview.js");
  for (const name of ["selectPreset", "setAccent", "toggleOutline", "setOutlineColor", "setOutlineAuto", "selectSet", "setRatio"]) {
    const line = hook.split("\n").find((text) => text.trim().startsWith(`${name}:`));
    assert.ok(line, `${name} exists`);
    assert.match(line, /dispatchStyle\(/, `${name} only dispatches a style change`);
    assert.doesNotMatch(line, /setPlaying|setPlayback/, `${name} does not pause`);
  }
  // 멈추는 곳은 재생 버튼·프레임 직접 선택뿐이다.
  assert.equal((hook.match(/setPlaying\(false\)/g) ?? []).length, 2, "pauseAt and stepFrame only");
});

// ── 재생 한 칸(StrictMode 순수성) ───────────────────────────

test("playback tick: the bag is drawn once outside the updater; the updater is pure under StrictMode double invocation", () => {
  const draws = [];
  const bag = createShuffleBag(["walk", "run", "attack"], () => 0.3);
  const draw = () => {
    const value = bag.next();
    draws.push(value);
    return value;
  };
  // 걷기 마지막 사이클의 마지막 프레임 → 다음 모션.
  const snapshot = { motion: "walk", frame: 7, loop: 1, turn: 2 };
  assert.equal(needsNextMotion(snapshot, SPRITE.motionsById, false), true);
  const update = planTick({ snapshot, latest: snapshot, motionsById: SPRITE.motionsById, hold: false, draw });
  assert.equal(draws.length, 1, "exactly one draw per tick");
  const first = update(snapshot);
  const second = update(snapshot);
  assert.deepEqual(first, second, "double invocation yields the same next state");
  assert.equal(draws.length, 1, "calling the updater twice never draws again");
  assert.deepEqual(first, { motion: draws[0], frame: 0, loop: 0, turn: 3 });
  // 중간 프레임에서는 꺼내지 않는다.
  const mid = planTick({ snapshot: { ...snapshot, frame: 3 }, latest: null, motionsById: SPRITE.motionsById, hold: false, draw });
  assert.equal(mid, null, "stale snapshot (latest differs) does nothing and draws nothing");
  const midState = { motion: "walk", frame: 3, loop: 0, turn: 0 };
  const midUpdate = planTick({ snapshot: midState, latest: midState, motionsById: SPRITE.motionsById, hold: false, draw });
  assert.equal(draws.length, 1, "no draw mid-cycle");
  assert.deepEqual(midUpdate(midState), { ...midState, frame: 4 });
  // 갱신 함수가 받은 상태가 snapshot 이 아니면(그사이 사용자가 옮김) 그대로 둔다.
  const moved = { ...midState, frame: 6 };
  assert.equal(midUpdate(moved), moved);
});

test("playback tick: pure advance matches the existing stepPlayback semantics (cycles, hold, complete turns only)", () => {
  const states = [
    { motion: "walk", frame: 0, loop: 0, turn: 0 },
    { motion: "walk", frame: 7, loop: 0, turn: 0 },
    { motion: "walk", frame: 7, loop: 1, turn: 0 },
    { motion: "attack", frame: 11, loop: 0, turn: 4 },
    { motion: "run", frame: 7, loop: 1, turn: 1 },
  ];
  for (const hold of [false, true]) {
    for (const state of states) {
      const nextMotion = needsNextMotion(state, SPRITE.motionsById, hold) ? "run" : null;
      assert.deepEqual(advancePlayback(state, SPRITE.motionsById, { nextMotion, hold }), stepPlayback(state, SPRITE.motionsById, { pickNext: () => "run", hold }));
    }
  }
  const hook = code("src/hooks/usePixelPreview.js");
  assert.match(hook, /planTick\(\{/);
  assert.doesNotMatch(hook, /setPlayback\(\(state\) => stepPlayback/, "no bag mutation inside a state updater");
  assert.doesNotMatch(hook, /pickNext: \(\) => bagRef\.current\.next\(\)/);
});

// ── 가벼운 props ───────────────────────────────────────────

test("lightweight props: no RGBA buffers or the whole hook view cross component props", () => {
  const preview = code("src/components/cases/PixelStudioPreview.jsx");
  assert.doesNotMatch(preview, /view=\{view\}/, "the hook result is never passed whole");
  assert.doesNotMatch(preview, /image=\{/);
  for (const name of ["StudioInspector", "LayerTimeline", "PixelCanvas"]) {
    const source = code(`src/components/cases/pixel/${name}.jsx`);
    assert.doesNotMatch(source, /\bview\b/, `${name} does not take view`);
    assert.doesNotMatch(source, /\.data\b|Uint8ClampedArray|layerView|centering\b/, `${name} does not read pixel buffers`);
  }
  const canvas = code("src/components/cases/pixel/PixelCanvas.jsx");
  assert.match(canvas, /export function PixelCanvas\(\{ paint, kind, frameKey, width, height, className, label \}\)/);
  assert.match(canvas, /useEffect\(\(\) => \{\s*paint\(kind, ref\.current\);\s*\}, \[paint, kind, frameKey\]\)/, "paints only inside an effect keyed by a string");
  // 훅 반환 객체에 큰 배열(현재 프레임·어니언·선택 레이어·중심 맞춤)이 없다.
  const hook = code("src/hooks/usePixelPreview.js");
  const returned = hook.slice(hook.lastIndexOf("return {"));
  for (const key of ["current", "stage", "layerView", "centering", "centered"]) {
    assert.doesNotMatch(returned, new RegExp(`^\\s*${key},`, "m"), `${key} is not returned`);
  }
  assert.match(returned, /paintImage,/);
  assert.match(returned, /frameKeys,/);
  // 접근자가 읽는 ref 는 레이아웃 효과에서만 쓴다(렌더 중 쓰기 없음).
  assert.match(hook, /useLayoutEffect\(\(\) => \{\s*imagesRef\.current = \{ current, layer: layerView, centered \};/);
  assert.match(hook, /const paintImage = useCallback\(\(kind, canvas\) => putImage\(canvas, imagesRef\.current\[kind\]\), \[\]\)/);
  assert.equal((hook.match(/imagesRef\.current/g) ?? []).length, 2, "the image ref is only written in a layout effect and read in the accessor");
  // 기존 크기 제한 캐시는 유지된다.
  for (const name of ["FRAME_CACHE_LIMIT", "MAP_CACHE_LIMIT", "NEAREST_CACHE_LIMIT"]) assert.match(hook, new RegExp(`createLruCache\\(${name}\\)`));
});

// ── 개발 모드 타이밍 항목 상한 ──────────────────────────────

function fakePerformance(counts) {
  const cleared = [];
  return {
    cleared,
    getEntriesByName: (name, type) => (type === "measure" ? Array.from({ length: counts[name] ?? 0 }) : []),
    clearMeasures: (...args) => {
      cleared.push(args);
      if (args.length) counts[args[0]] = 0;
    },
  };
}

test("dev timing budget: only owned React component entries over budget are cleared, by name, never globally", () => {
  const owned = ["PixelCanvas", "LayerTimeline", "StudioInspector"];
  const counts = {
    [timingNameFor("PixelCanvas")]: OWNED_TIMING_BUDGET + 5,
    [timingNameFor("LayerTimeline")]: OWNED_TIMING_BUDGET,
    [timingNameFor("StudioInspector")]: 3,
    [timingNameFor("SomeoneElse")]: 99999,
    "user-mark": 99999,
  };
  const perf = fakePerformance(counts);
  const cleared = trimOwnedTimings(perf, owned);
  assert.deepEqual(cleared, [`${REACT_TIMING_PREFIX}PixelCanvas`]);
  assert.ok(perf.cleared.every((args) => args.length === 1 && typeof args[0] === "string"), "clearMeasures always receives one owned name");
  assert.equal(counts[timingNameFor("SomeoneElse")], 99999, "foreign entries untouched");
  assert.equal(counts["user-mark"], 99999);
  assert.equal(counts[timingNameFor("LayerTimeline")], OWNED_TIMING_BUDGET, "at budget is kept");
  assert.deepEqual(trimOwnedTimings(null, owned), [], "no performance API → nothing");
  assert.deepEqual(trimOwnedTimings({}, owned), []);

  const source = code("src/lib/devTimings.js");
  assert.doesNotMatch(source, /clearMeasures\(\)/, "no global clear");
  assert.doesNotMatch(source, /performance\.measure\s*=|console\.error\s*=|try\s*\{/, "no monkeypatch or error suppression");
  const hook = code("src/hooks/usePixelPreview.js");
  assert.match(hook, /if \(!import\.meta\.env\?\.DEV/, "dev only");
  assert.match(hook, /trimOwnedTimings\(performance, STUDIO_TIMING_COMPONENTS\)/);
  const main = read("src/main.jsx");
  assert.match(main, /StrictMode/, "StrictMode stays on");
});
