import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { DEFAULT_PALETTE_RATIO, DEFAULT_SET_ID, LAYER_LABELS, PIXEL_COPY, PIXEL_PRESETS } from "../src/content/pixelStudio.js";
import {
  buildLayerModel,
  celState,
  compositeFrame,
  compositeReference,
  decodeCel,
  indicesToRgba,
  isolateLayer,
  sourceColorTable,
  toggleLayer,
  visibilityKey,
} from "../src/pixel/layers.js";
import { buildPaletteMap, extractPalette, hexToRgb } from "../src/pixel/palette.js";
import { applyPaletteSet, buildPaletteSets, clampRatio, colorShares } from "../src/pixel/paletteSets.js";
import { processFrame } from "../src/pixel/pipeline.js";
import { buildRig, frameRig, plantPoints, poseRig } from "../src/pixel/rig.js";
import { OUTLINE_PAD } from "../src/pixel/outline.js";
import {
  ONION_TINT,
  composeOver,
  guideCoordinates,
  isLooping,
  onionNeighbors,
  opaqueBounds,
  recenterByBounds,
  stepFrame,
  tintPixels,
} from "../src/pixel/timeline.js";

const read = (relative) => readFileSync(new URL(`../${relative}`, import.meta.url), "utf8");
const json = (relative) => JSON.parse(read(relative));
const META = json("src/content/pixel-assets.json");
const MODEL = buildLayerModel(json("src/content/pixel-layers.json"));
const DEFS = json("src/content/pixel-source-colors.json");
const TABLE = sourceColorTable(DEFS);
const SETS = buildPaletteSets(json("src/content/pixel-palette-sets.json"));
const RIG_JSON = json("src/content/pixel-rig.json");
const RIG = buildRig(RIG_JSON);
const MOTION_RIG = json("src/content/pixel-motion-rig.json");

const PAD = OUTLINE_PAD;
const W = MODEL.width + PAD * 2;
const H = MODEL.height + PAD * 2;
const SOURCE_PALETTE = extractPalette(MODEL.frames.map((frame) => indicesToRgba(compositeFrame(MODEL, frame.index).indices, TABLE)));
const run = (frameIndex, options = {}) =>
  processFrame({ model: MODEL, table: TABLE, frameIndex, visibility: MODEL.defaultVisibility, pad: PAD, nearestCache: new Map(), ...options });
const hexOf = (data, i) => `#${((data[i] << 16) | (data[i + 1] << 8) | data[i + 2]).toString(16).padStart(6, "0")}`;

test("layer data: 20 original layers (composite hidden, last), 28 frames with the original keys and durations", () => {
  assert.deepEqual([MODEL.res, MODEL.width, MODEL.height], [64, 84, 89]);
  assert.equal(MODEL.layers.length, 20);
  assert.equal(MODEL.compositeIndex, 19);
  assert.equal(MODEL.layers[19].name, "composite");
  assert.equal(MODEL.layers[19].visible, false);
  assert.ok(MODEL.layers.slice(0, 19).every((layer) => layer.visible), "every real layer is visible in the source file");
  for (const layer of MODEL.layers) assert.ok(LAYER_LABELS[layer.name], `Korean label for ${layer.name}`);
  assert.deepEqual(Object.fromEntries(Object.entries(MODEL.motions).map(([id, list]) => [id, list.length])), { walk: 8, run: 8, attack: 12 });
  // 원본 PNG 메타데이터와 같은 기준점·발바닥 줄·프레임 길이.
  assert.equal(MODEL.pivotX, META.pivotX);
  assert.equal(MODEL.soleRow, META.soleRow);
  assert.equal(MODEL.crownRow, 23);
  for (const motion of META.motions) {
    assert.deepEqual(
      MODEL.motions[motion.id].map((index) => MODEL.frames[index].ms),
      motion.frames.map((frame) => frame.ms),
      `${motion.id} durations`,
    );
    MODEL.motions[motion.id].forEach((index, step) => assert.equal(MODEL.frames[index].key, `${motion.id}-${String(step).padStart(2, "0")}`));
  }
});

test("RLE cels: [count u16 LE, master index] triples decode to exactly w×h, inside the canvas, with known colours only", () => {
  let cels = 0;
  for (const frame of MODEL.frames) {
    frame.cels.forEach((cel, li) => {
      if (!cel) return;
      cels += 1;
      const raw = decodeCel(cel);
      assert.equal(raw.length, cel.w * cel.h);
      assert.ok(cel.x >= 0 && cel.y >= 0 && cel.x + cel.w <= MODEL.width && cel.y + cel.h <= MODEL.height, `${frame.key}/${li} in bounds`);
      for (const value of raw) assert.ok(value === 0 || TABLE[value], `${frame.key}/${li} colour ${value}`);
    });
    assert.ok(frame.cels[MODEL.compositeIndex], `${frame.key} keeps its composite reference`);
  }
  assert.ok(cels > 28 * 15, "many real cels");
  // 원본 색 표: 번호 1 = defs[0], 0 = 투명.
  assert.equal(TABLE[0], null);
  assert.deepEqual(TABLE[1], hexToRgb(`#${DEFS[0][1]}`));
  assert.throws(() => decodeCel({ w: 2, h: 2, data: Buffer.from([1, 0, 3]).toString("base64") }), "short RLE is rejected");
});

test("re-compositing the 19 visible layers (last opaque wins) reproduces the stored composite reference for all 28 frames", () => {
  for (const frame of MODEL.frames) {
    const { indices, owner } = compositeFrame(MODEL, frame.index);
    assert.deepEqual(indices, compositeReference(MODEL, frame.index), frame.key);
    for (let p = 0; p < indices.length; p += 1) assert.equal(indices[p] === 0, owner[p] === -1);
    // composite 레이어는 표시값을 켜도 합성하지 않는다.
    const allOn = MODEL.layers.map(() => true);
    assert.deepEqual(compositeFrame(MODEL, frame.index, allOn).indices, indices);
  }
  const rgba = indicesToRgba(compositeFrame(MODEL, 0).indices, TABLE);
  for (let i = 3; i < rgba.length; i += 4) assert.ok(rgba[i] === 0 || rgba[i] === 255, "binary alpha");
});

test("several layers change their own cels together in every motion (not a sequential build of one flattened image)", () => {
  for (const [motion, steps] of Object.entries(MODEL.motions)) {
    for (let step = 1; step < steps.length; step += 1) {
      const changed = MODEL.layers.filter((layer) => !layer.isComposite && celState(MODEL, steps[step], layer.index, steps[step - 1]) === "key");
      assert.ok(changed.length >= 2, `${motion} ${step}: ${changed.length} layers changed`);
    }
  }
  assert.equal(celState(MODEL, 0, 0, null), "empty", "fx layer has no cel in walk-00");
});

test("visibility: hide/show/isolate are deterministic and only remove that layer's pixels", () => {
  const sword = MODEL.layers.findIndex((layer) => layer.name === "sword");
  const hidden = toggleLayer(MODEL.defaultVisibility, sword);
  assert.equal(hidden[sword], false);
  assert.deepEqual(toggleLayer(hidden, sword), [...MODEL.defaultVisibility], "toggle twice = original");
  assert.equal(visibilityKey(MODEL.defaultVisibility), "1111111111111111111" + "0");
  for (const frameIndex of [0, MODEL.motions.attack[4]]) {
    const full = compositeFrame(MODEL, frameIndex);
    const without = compositeFrame(MODEL, frameIndex, hidden);
    assert.ok(full.owner.some((owner) => owner === sword), "sword visible in the full frame");
    assert.ok(without.owner.every((owner) => owner !== sword), "no sword pixel after hiding");
    for (let p = 0; p < full.indices.length; p += 1) {
      if (full.owner[p] !== sword) assert.equal(without.indices[p], full.indices[p], "other layers' winning pixels unchanged");
    }
    // 격리: 그 레이어 셀의 불투명 픽셀만.
    const solo = compositeFrame(MODEL, frameIndex, isolateLayer(MODEL, sword));
    const cel = MODEL.frames[frameIndex].cels[sword];
    const raw = decodeCel(cel);
    let count = 0;
    for (let p = 0; p < solo.indices.length; p += 1) {
      if (!solo.indices[p]) continue;
      count += 1;
      const x = (p % MODEL.width) - cel.x;
      const y = Math.floor(p / MODEL.width) - cel.y;
      assert.equal(solo.indices[p], raw[y * cel.w + x]);
    }
    assert.equal(count, raw.filter(Boolean).length);
  }
  assert.equal(isolateLayer(MODEL, MODEL.compositeIndex).some(Boolean), false, "composite cannot be isolated into view");
});

test("all 10 original palette sets: 100% puts every opaque output pixel (outline included) inside the set; alpha preserved", () => {
  assert.equal(SETS.length, 10);
  assert.deepEqual(SETS.map((set) => set.id), ["aap64", "endesga64", "resurrect64", "apollo", "endesga32", "lospec500", "cc29", "slso8", "pear36", "db32"]);
  assert.equal(SETS[0].name, "AAP-64");
  assert.equal(SETS[0].colors.length, 64);
  const accentMap = buildPaletteMap(SOURCE_PALETTE, PIXEL_PRESETS.find((preset) => preset.id === "crimson").accent);
  const outlineRgb = hexToRgb("#ffe2d6");
  const frames = [MODEL.motions.walk[0], MODEL.motions.attack[6]];
  for (const set of SETS) {
    const members = new Set(set.colors);
    for (const frameIndex of frames) {
      const base = run(frameIndex, { accentMap, outlineRgb });
      const full = run(frameIndex, { accentMap, outlineRgb, set, ratio: 1 });
      assert.deepEqual([full.width, full.height], [W, H]);
      let opaque = 0;
      for (let i = 0; i < full.data.length; i += 4) {
        assert.equal(full.data[i + 3], base.data[i + 3], "alpha unchanged");
        if (full.data[i + 3] === 0) continue;
        opaque += 1;
        assert.ok(members.has(hexOf(full.data, i)), `${set.id}: ${hexOf(full.data, i)} not in set`);
      }
      assert.ok(opaque > 500);
      assert.equal(colorShares(full.data, set).inSetShare, 1);
    }
  }
});

test("palette application ratio: 0% is byte-identical to the accent/outline result, 50% lies between endpoints, alpha preserved", () => {
  const set = SETS.find((item) => item.id === "slso8");
  const frameIndex = MODEL.motions.run[3];
  const accentMap = buildPaletteMap(SOURCE_PALETTE, "#3f9a4a");
  const base = run(frameIndex, { accentMap, outlineRgb: [255, 241, 201] });
  assert.deepEqual(run(frameIndex, { accentMap, outlineRgb: [255, 241, 201], set, ratio: 0 }).data, base.data);
  const full = applyPaletteSet(base.data, set, 1);
  const half = applyPaletteSet(base.data, set, 0.5);
  const quarter = applyPaletteSet(base.data, set, 0.25);
  let moved = 0;
  for (let i = 0; i < base.data.length; i += 4) {
    assert.equal(half[i + 3], base.data[i + 3]);
    if (base.data[i + 3] === 0) {
      assert.deepEqual([...half.subarray(i, i + 4)], [0, 0, 0, 0]);
      continue;
    }
    for (let c = 0; c < 3; c += 1) {
      const lo = Math.min(base.data[i + c], full[i + c]);
      const hi = Math.max(base.data[i + c], full[i + c]);
      assert.ok(half[i + c] >= lo && half[i + c] <= hi, "between endpoints");
      assert.ok(Math.abs(quarter[i + c] - base.data[i + c]) <= Math.abs(half[i + c] - base.data[i + c]), "monotone in ratio");
      if (half[i + c] !== base.data[i + c]) moved += 1;
    }
  }
  assert.ok(moved > 0, "50% visibly moves colours");
  assert.deepEqual([clampRatio(-1), clampRatio(2), clampRatio("x")], [0, 1, 0]);
  assert.deepEqual(applyPaletteSet(base.data, set, 0), base.data);
  // 점유율 합 = 1, 내림차순.
  const shares = colorShares(full, set);
  assert.ok(Math.abs(shares.entries.reduce((sum, entry) => sum + entry.share, 0) - 1) < 1e-9);
  assert.ok(shares.entries.every((entry, i, list) => i === 0 || list[i - 1].count >= entry.count));
});

test("palette defaults: AAP-64 at 100% from the central constants; the hook starts from them", () => {
  assert.equal(DEFAULT_SET_ID, "aap64");
  assert.equal(DEFAULT_PALETTE_RATIO, 100);
  // 색 설정 상태는 styleReducer(INITIAL_STYLE) 하나로 옮겼다. 초기값은 같은 중앙 상수에서 나온다.
  const studio = readFileSync(new URL("../src/pixel/studio.js", import.meta.url), "utf8");
  assert.match(studio, /setId: DEFAULT_SET_ID/);
  assert.match(studio, /ratio: DEFAULT_PALETTE_RATIO/);
  const hook = readFileSync(new URL("../src/hooks/usePixelPreview.js", import.meta.url), "utf8");
  assert.match(hook, /useReducer\(styleReducer, INITIAL_STYLE\)/);
});

test("onion neighbours stay inside the motion: loops wrap, attack clamps; ghosts sit below the current frame", () => {
  assert.deepEqual([isLooping("walk"), isLooping("run"), isLooping("attack")], [true, true, false]);
  assert.deepEqual(onionNeighbors(8, 0, true), { prev: 7, next: 1 });
  assert.deepEqual(onionNeighbors(8, 7, true), { prev: 6, next: 0 });
  assert.deepEqual(onionNeighbors(12, 0, false), { prev: null, next: 1 });
  assert.deepEqual(onionNeighbors(12, 11, false), { prev: 10, next: null });
  assert.deepEqual([stepFrame(8, 7, 1, true), stepFrame(8, 0, -1, true), stepFrame(12, 11, 1, false), stepFrame(12, 0, -1, false)], [0, 7, 11, 0]);

  const steps = MODEL.motions.walk;
  const current = run(steps[0]);
  const prev = tintPixels(run(steps[7]).data, ONION_TINT.prev, 0.35);
  const next = tintPixels(run(steps[1]).data, ONION_TINT.next, 0.35);
  const stage = composeOver([prev, next, current.data], current.data.length);
  let ghostOnly = 0;
  for (let i = 0; i < stage.length; i += 4) {
    if (current.data[i + 3] === 255) {
      assert.deepEqual([...stage.subarray(i, i + 4)], [...current.data.subarray(i, i + 4)], "current always on top, untouched");
    } else if (stage[i + 3] > 0) {
      ghostOnly += 1;
      assert.ok(stage[i + 3] < 255, "ghost pixels are translucent");
    }
  }
  assert.ok(ghostOnly > 0, "neighbouring real frames show around the current one");
  for (let i = 3; i < prev.length; i += 4) assert.ok(prev[i] === 0 || prev[i] === Math.round(0.35 * 255));
});

test("guides and centring: common pivot/sole/crown coordinates, bbox-centring shift comes from real pixels", () => {
  assert.deepEqual(guideCoordinates(MODEL, PAD), { pivotX: 38 + PAD, soleRow: 79 + PAD, crownRow: 23 + PAD });
  const guides = guideCoordinates(MODEL, PAD);
  const shifts = new Set();
  for (const frame of MODEL.frames) {
    const image = run(frame.index);
    const box = opaqueBounds(image.data, W, H);
    const moved = recenterByBounds(image.data, W, H, guides);
    assert.equal(moved.dx, guides.pivotX - Math.floor(box.x + (box.w - 1) / 2));
    assert.equal(moved.dy, guides.soleRow - (box.y + box.h - 1));
    const after = opaqueBounds(moved.data, W, H);
    assert.equal(after.y + after.h - 1, guides.soleRow, `${frame.key} bottom on the sole row`);
    shifts.add(moved.dx);
  }
  assert.ok(shifts.size > 1, "per-frame trimming would move frames by different amounts");
});

test("rig: source rest skeleton angles equal attack frame 0 world angles; FK keeps bone lengths; missing angles are not invented", () => {
  assert.equal(RIG.bones.length, 18);
  for (const bone of RIG.bones) if (bone.parent) assert.ok(RIG.bonesByName[bone.parent], `${bone.name} parent exists`);
  assert.equal(RIG.bones[0].name, "torso");
  assert.deepEqual(RIG.units, { crown_y: 247, ground_y: 1148, H_px: 901, dot_px: 8.4 });
  assert.equal(RIG.extraLayers.length, 4);
  const rest = MOTION_RIG.motions.attack[0].rot_world;
  for (const bone of RIG.bones) assert.ok(Math.abs(bone.restAngle - rest[bone.name]) < 0.01, `${bone.name} ${bone.restAngle} vs ${rest[bone.name]}`);
  const restPose = poseRig(RIG, rest);
  for (const bone of RIG.bones) {
    assert.ok(Math.hypot(restPose[bone.name].from[0] - bone.from[0], restPose[bone.name].from[1] - bone.from[1]) < 0.5, bone.name);
    assert.ok(Math.hypot(restPose[bone.name].to[0] - bone.to[0], restPose[bone.name].to[1] - bone.to[1]) < 0.5, bone.name);
  }
  // 프레임 수·길이가 레이어 프레임과 같다(같은 커서로 읽는다).
  for (const [motion, frames] of Object.entries(MOTION_RIG.motions)) {
    assert.equal(frames.length, MODEL.motions[motion].length);
    frames.forEach((frame, step) => assert.equal(frame.ms, MODEL.frames[MODEL.motions[motion][step]].ms));
  }
  const walk = frameRig(MOTION_RIG, "walk", 0);
  assert.deepEqual(walk.rootCells, [0, 1]);
  assert.deepEqual(walk.plant, { near: "heel", far: "toe" });
  const pose = poseRig(RIG, walk.rotWorld);
  for (const name of ["head", "hair_ahoge_1", "hair_ahoge_2"]) assert.equal(pose[name].posed, false, `${name} has no walk angle chain`);
  for (const bone of RIG.bones) {
    const posed = pose[bone.name];
    if (!posed.posed) continue;
    assert.ok(Math.abs(Math.hypot(posed.to[0] - posed.from[0], posed.to[1] - posed.from[1]) - bone.length) < 1e-6);
    assert.equal(posed.angle, walk.rotWorld[bone.name]);
  }
  // 무릎은 허벅지 끝에서 이어진다(강체 FK).
  assert.ok(Math.hypot(pose.near_shin.from[0] - pose.near_thigh.to[0], pose.near_shin.from[1] - pose.near_thigh.to[1]) < 1e-6);
  assert.equal(plantPoints(RIG, pose, walk.plant).length, 2);
  assert.equal(frameRig(MOTION_RIG, "walk", 99), null);
});

test("studio wiring: one cursor drives every view, frame picks pause, caches bounded, no storage/network, Korean copy", () => {
  const hook = read("src/hooks/usePixelPreview.js");
  assert.equal((hook.match(/window\.setTimeout\(/g) ?? []).length, 1, "one timer");
  assert.match(hook, /const frameIndex = steps\[playback\.frame\]/);
  assert.match(hook, /selectFrame: pauseAt/);
  assert.match(hook, /stepFrame: \(delta\) => \{\s*setPlaying\(false\)/);
  assert.match(hook, /createLruCache\(NEAREST_CACHE_LIMIT\)/);
  assert.match(hook, /NEAREST_ENTRY_LIMIT/);
  assert.doesNotMatch(hook, /localStorage|sessionStorage|fetch\(|setInterval/);
  const files = ["LayerTimeline", "StudioInspector", "RigPanel", "PaletteSetRow", "PixelCanvas"].map((name) => read(`src/components/cases/pixel/${name}.jsx`));
  const preview = read("src/components/cases/PixelStudioPreview.jsx");
  for (const text of [...files, preview, hook]) {
    assert.doesNotMatch(text, /\p{Extended_Pictographic}/u, "no emoji");
    assert.doesNotMatch(text, /fetch\(|localStorage/);
  }
  assert.match(preview, /<PaletteSetRow /);
  assert.ok(preview.indexOf("PIXEL_PRESETS.map") < preview.indexOf("<PaletteSetRow"), "palette sets are a second row below the kept accent row");
  assert.match(preview, /role="switch" aria-checked=\{view\.outlineOn\}/, "added outline control kept");
  assert.equal(PIXEL_COPY.ratio, "팔레트 적용 비율");
  assert.equal(PIXEL_COPY.outline, "추가 외곽선");
  for (const value of Object.values(PIXEL_COPY)) assert.doesNotMatch(String(value), /\p{Extended_Pictographic}/u);
  const css = read("src/styles/pixel.css");
  assert.match(css, /\.pixel-timeline__scroll \{[^}]*overflow: auto;/, "timeline scrolls inside its own box");
  assert.match(css, /\.pixel-timeline__eye \{[^}]*width: 44px;[^}]*height: 44px;/);
  assert.match(css, /\.pixel-range \{[^}]*min-height: 44px;/);
});
