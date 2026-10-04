import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { test } from "node:test";
import { createLruCache } from "../src/pixel/cache.js";
import { OUTLINE_PAD, addOutline, fitsWithOutline, padPixels } from "../src/pixel/outline.js";
import { buildPaletteMap, detectAccentHue, extractPalette, recolorPixels, rgbToHsl } from "../src/pixel/palette.js";
import { createShuffleBag, cycleDuration, cyclesFor, showcaseFor, stepPlayback } from "../src/pixel/playback.js";
import { buildSpriteModel } from "../src/pixel/sprite.js";
import { PIXEL_COPY, PIXEL_PRESETS } from "../src/content/pixelStudio.js";

const read = (relative) => readFileSync(new URL(`../${relative}`, import.meta.url), "utf8");
const META = JSON.parse(read("src/content/pixel-assets.json"));
const SPRITE = buildSpriteModel(META);

// 고정 난수(mulberry32)로 섞기 결과를 재현한다.
function seeded(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// 작은 시험 스프라이트: 투명 바탕 위 파란 머리 2색 + 피부색 + 검은 잉크.
const BLUE_DARK = [30, 60, 160];
const BLUE_LIGHT = [90, 140, 230];
const SKIN = [240, 200, 160];
const INK = [20, 20, 28];
function makeSprite() {
  const w = 4;
  const h = 4;
  const data = new Uint8ClampedArray(w * h * 4);
  const put = (x, y, rgb) => data.set([...rgb, 255], (y * w + x) * 4);
  put(1, 0, BLUE_DARK);
  put(2, 0, BLUE_LIGHT);
  put(1, 1, SKIN);
  put(2, 1, SKIN);
  put(1, 2, INK);
  put(0, 3, INK); // 칼끝처럼 캔버스 가장자리에 닿는 픽셀
  return { data, w, h };
}

test("metadata: original v8 hero assets exist unchanged in public; frame counts and durations come from the JSON", () => {
  assert.deepEqual([META.width, META.height], [84, 89]);
  assert.deepEqual(SPRITE.motions.map((motion) => [motion.id, motion.frames.length]), [["walk", 8], ["run", 8], ["attack", 12]]);
  assert.equal(SPRITE.frameCount, 28);
  for (const motion of SPRITE.motions) {
    assert.ok(existsSync(new URL(`../public${motion.gif}`, import.meta.url)), motion.gif);
    for (const frame of motion.frames) {
      assert.ok(existsSync(new URL(`../public${frame.src}`, import.meta.url)), frame.src);
      assert.ok(Number.isInteger(frame.ms) && frame.ms > 0);
    }
  }
  assert.deepEqual(SPRITE.motions.map(cycleDuration), [940, 720, 920]);
  // 공통 캔버스: 모든 프레임이 같은 여백만큼만 옮겨진다(기준점이 프레임마다 바뀌지 않음).
  assert.deepEqual([SPRITE.canvasWidth, SPRITE.canvasHeight, SPRITE.pivotX, SPRITE.soleRow], [84 + 2 * OUTLINE_PAD, 89 + 2 * OUTLINE_PAD, META.pivotX + OUTLINE_PAD, META.soleRow + OUTLINE_PAD]);
});

test("palette: discrete per-colour remap of the accent ramp only; alpha and transparent pixels are untouched", () => {
  const { data } = makeSprite();
  const palette = extractPalette([data]);
  assert.equal(palette.length, 4, "unique opaque colours only");
  assert.ok(Math.abs(detectAccentHue(palette) - rgbToHsl(BLUE_DARK)[0]) < 30, "the blue hair is the accent");
  const map = buildPaletteMap(palette, "#c8323c");
  assert.equal(map.size, 2, "only the two blue entries are remapped");
  const out = recolorPixels(data, map);
  assert.notDeepEqual(out, data, "output visibly changes");
  for (let i = 0; i < data.length; i += 4) {
    assert.equal(out[i + 3], data[i + 3], "alpha preserved");
    if (data[i + 3] === 0) assert.deepEqual([...out.subarray(i, i + 4)], [0, 0, 0, 0]);
  }
  assert.ok([0, 255].includes(Math.min(...out.filter((_, i) => i % 4 === 3))));
  const pixel = (x, y, arr) => [...arr.subarray((y * 4 + x) * 4, (y * 4 + x) * 4 + 3)];
  assert.deepEqual(pixel(1, 1, out), SKIN, "skin untouched");
  assert.deepEqual(pixel(1, 2, out), INK, "original ink untouched");
  const red = rgbToHsl(pixel(1, 0, out));
  assert.ok(red[0] < 20 || red[0] > 340, `hair becomes red, hue ${red[0]}`);
  assert.ok(rgbToHsl(pixel(1, 0, out))[2] < rgbToHsl(pixel(2, 0, out))[2], "shading order (dark → light) is kept");
  assert.deepEqual(recolorPixels(data, buildPaletteMap(palette, null)), data, "original preset is identity");
  assert.equal(data[4 + 0], BLUE_DARK[0], "input array is not mutated");
});

test("added outline keeps original ink, only fills transparent neighbours, and never clips an edge-touching sword", () => {
  const { data, w, h } = makeSprite();
  assert.equal(fitsWithOutline(data, w, h), false, "the raw frame touches its edge");
  const padded = padPixels(data, w, h, OUTLINE_PAD);
  assert.deepEqual([padded.width, padded.height], [w + 2, h + 2]);
  assert.equal(fitsWithOutline(padded.data, padded.width, padded.height), true, "the common padded canvas leaves room");
  const outlined = addOutline(padded.data, padded.width, padded.height, [255, 241, 201]);
  let added = 0;
  for (let i = 0; i < padded.data.length; i += 4) {
    if (padded.data[i + 3] > 0) {
      assert.deepEqual([...outlined.subarray(i, i + 4)], [...padded.data.subarray(i, i + 4)], "drawn pixels unchanged");
    } else if (outlined[i + 3] > 0) {
      added += 1;
      assert.deepEqual([...outlined.subarray(i, i + 4)], [255, 241, 201, 255]);
    }
  }
  assert.ok(added > 0);
  // 가장자리 칼끝(원래 0,3 → 여백 뒤 1,4)의 왼쪽(0,4)에도 외곽선이 생긴다.
  assert.equal(outlined[(4 * padded.width + 0) * 4 + 3], 255);
  for (let i = 3; i < outlined.length; i += 4) assert.ok(outlined[i] === 0 || outlined[i] === 255, "alpha stays binary");
});

test("shuffle bag: every bag holds all three motions and no motion repeats back-to-back", () => {
  for (const rng of [seeded(1), seeded(42), seeded(2026), Math.random]) {
    const bag = createShuffleBag(["walk", "run", "attack"], rng);
    const draws = Array.from({ length: 300 }, () => bag.next());
    for (let i = 0; i < draws.length; i += 3) assert.deepEqual([...draws.slice(i, i + 3)].sort(), ["attack", "run", "walk"]);
    for (let i = 1; i < draws.length; i += 1) assert.notEqual(draws[i], draws[i - 1], `repeat at ${i}`);
  }
  assert.throws(() => createShuffleBag([]));
});

test("shuffle bag resumeFrom: after a manual pick or re-enabling shuffle, the next draw never repeats the current motion", () => {
  for (const rng of [seeded(1), seeded(7), seeded(2026), Math.random]) {
    const bag = createShuffleBag(["walk", "run", "attack"], rng);
    for (let round = 0; round < 50; round += 1) {
      bag.next();
      const current = ["walk", "run", "attack"][round % 3];
      bag.resumeFrom(current);
      const draws = [bag.next(), bag.next(), bag.next()];
      assert.notEqual(draws[0], current, `round ${round}`);
      assert.deepEqual([...draws].sort(), ["attack", "run", "walk"], "a fresh bag still holds all three");
    }
  }
});

test("preview hook draws the first motion once at bag init (StrictMode-safe) and resumes the bag on manual/shuffle changes", () => {
  const hook = read("src/hooks/usePixelPreview.js");
  assert.match(hook, /motion: firstMotionRef\.current/);
  assert.doesNotMatch(hook, /useState\(\(\) => \(\{ motion: bagRef\.current\.next\(\)/);
  assert.equal((hook.match(/resumeFrom\(/g) ?? []).length, 2);
  assert.match(hook, /debugWarn\(/);
});

test("playback switches motion only after complete natural cycles; hold keeps looping", () => {
  const picks = ["run", "attack"];
  const pickNext = () => picks.shift();
  let state = { motion: "walk", frame: 0, loop: 0, turn: 0 };
  const seen = [];
  for (let i = 0; i < 8 * cyclesFor("walk") - 1; i += 1) {
    state = stepPlayback(state, SPRITE.motionsById, { pickNext });
    seen.push(state.motion);
  }
  assert.ok(seen.every((motion) => motion === "walk"), "walk plays its full cycles");
  state = stepPlayback(state, SPRITE.motionsById, { pickNext });
  assert.deepEqual(state, { motion: "run", frame: 0, loop: 0, turn: 1 });
  let held = { motion: "attack", frame: 11, loop: 0, turn: 3 };
  held = stepPlayback(held, SPRITE.motionsById, { pickNext: () => "walk", hold: true });
  assert.deepEqual(held, { motion: "attack", frame: 0, loop: 0, turn: 3 });
  assert.equal(cyclesFor("attack"), 1);
  // 자동 연출은 차례마다 프리셋을 돌린다.
  const ids = PIXEL_PRESETS.map((preset) => preset.id);
  assert.deepEqual([0, 1, 2, 3].map((turn) => showcaseFor(turn, ids).outline), [false, false, true, true]);
  assert.equal(showcaseFor(ids.length, ids).presetId, ids[0]);
});

test("caches are bounded", () => {
  const cache = createLruCache(3);
  for (const key of ["a", "b", "c"]) cache.set(key, key);
  cache.get("a");
  cache.set("d", "d");
  assert.equal(cache.size, 3);
  assert.equal(cache.get("b"), undefined, "least recently used is evicted");
  assert.equal(cache.get("a"), "a");
  assert.throws(() => createLruCache(0));
});

test("preview wiring: imported metadata, timers cleaned, offscreen/hidden pause, reduced motion starts paused, no nested buttons", () => {
  assert.match(read("src/pixel/assets.js"), /import meta from "\.\.\/content\/pixel-assets\.json"/);
  const hook = read("src/hooks/usePixelPreview.js");
  assert.match(hook, /window\.setTimeout\(/);
  assert.match(hook, /return \(\) => window\.clearTimeout\(timer\)/);
  assert.match(hook, /const active = playing && inView && pageVisible/);
  assert.match(hook, /observer\.disconnect\(\)/);
  assert.match(hook, /removeEventListener\("visibilitychange"/);
  assert.match(hook, /useState\(\(\) => !prefersReducedMotion\(\)\)/);
  assert.match(hook, /createLruCache\(FRAME_CACHE_LIMIT\)/);
  assert.doesNotMatch(hook, /setInterval|fetch\(/);
  const css = read("src/styles/pixel.css");
  assert.match(css, /image-rendering: pixelated/);
  assert.doesNotMatch(css, /filter:/);
  const component = read("src/components/cases/PixelStudioPreview.jsx");
  assert.match(component, /role="switch"/);
  assert.equal(PIXEL_COPY.outline, "추가 외곽선");
  assert.match(css, /\.pixel-btn \{[^}]*min-width: 44px;[^}]*min-height: 44px;/);
  // 사용자 최신 지시: 전체 미리보기는 사례 레일에서 빠져 /sprite 페이지(lazy 청크)에만 마운트된다.
  const cases = read("src/components/cases/CasesSection.jsx");
  assert.doesNotMatch(cases, /PixelStudioPreview/, "the case rail no longer mounts the studio");
  const page = read("src/components/sprite/SpritePage.jsx");
  assert.match(page, /<PixelStudioPreview onOpenCase=/, "the studio lives on the sprite page");
  assert.ok(page.indexOf("<PixelStudioPreview") > page.indexOf("</section>"), "preview is outside any button");
  const app = read("src/App.jsx");
  assert.match(app, /lazy\(\(\) => import\("\.\/components\/sprite\/SpritePage\.jsx"\)/, "sprite page is split into its own chunk");
  assert.doesNotMatch(app, /import \{ (SpritePage|PixelStudioPreview) \}/, "no static import pulls pixel data into the main chunk");
  assert.match(component, /motion\.frames\[playback\.frame\]/, "static original follows the playback cursor");
  assert.match(read("src/content/site.js"), /hero_pixel_studio_screen\.png/, "original studio screenshot stays as evidence");
});
