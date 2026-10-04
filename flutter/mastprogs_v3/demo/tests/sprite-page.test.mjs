import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import path from "node:path";
import { test } from "node:test";
import { stripComments } from "./strip-comments.mjs";
import { fileURLToPath } from "node:url";
import { SECTION_IDS, SPRITE_BRIEF, SPRITE_ROUTE } from "../src/content/site.js";
import { SPRITE_PAGE } from "../src/content/pixelStudio.js";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (relative) => readFileSync(path.join(root, relative), "utf8");
const meta = JSON.parse(read("src/content/pixel-assets.json"));

// 사용자 지시: 스프라이트 요약은 메인 워크플로우 다음, 전체 작업 화면은 /sprite 별도 페이지(새 탭).
test("/sprite route: pathname match with trailing slash, lazy chunk, same provider, single h1, back link and theme control", () => {
  assert.equal(SPRITE_ROUTE, "/sprite");
  const app = read("src/App.jsx");
  assert.match(app, /isSprite: path === SPRITE_ROUTE/);
  assert.match(app, /replace\(\/\\\/\+\$\/, ""\)/, "trailing slash is normalised");
  assert.match(app, /const SpritePage = lazy\(/);
  assert.match(app, /<Suspense fallback=\{null\}>\s*<SpritePage \/>/);
  const page = read("src/components/sprite/SpritePage.jsx");
  assert.equal((page.match(/<h1[\s>]/g) ?? []).length, 1);
  assert.match(page, /<a className="wfd-top__back" href="\/">/);
  assert.match(page, /<ThemeToggle compact \/>/);
  assert.doesNotMatch(page, /localStorage|sessionStorage|fetch\(/);
  assert.doesNotMatch(read("src/components/cases/PixelStudioPreview.jsx"), /<h1[\s>]/, "the studio heading stays below the page h1");
  for (const value of [...Object.values(SPRITE_PAGE).flat(), ...Object.values(SPRITE_BRIEF).flat().map((item) => (typeof item === "string" ? item : `${item.label} ${item.text}`))]) {
    assert.doesNotMatch(value, /\p{Extended_Pictographic}/u, "no emoji");
    assert.doesNotMatch(value, /설명용|데모/, "no disclaimer");
  }
});

test("sprite page keeps every studio feature and the original case dialog evidence", () => {
  const page = read("src/components/sprite/SpritePage.jsx");
  assert.match(page, /import \{ PixelStudioPreview \} from "\.\.\/cases\/PixelStudioPreview\.jsx"/);
  assert.match(page, /import \{ CaseDialog \} from "\.\.\/cases\/CaseDialog\.jsx"/);
  assert.match(page, /item\.id === "case-pixel"/);
  const preview = read("src/components/cases/PixelStudioPreview.jsx");
  for (const token of ["PIXEL_PRESETS.map", 'type="color"', 'role="switch"', "<PaletteSetRow", "<LayerTimeline", "<StudioInspector", "<RigPanel", "actions.toggleShuffle", "actions.selectMotion", "motion.frames[playback.frame]", "motion.gif"]) {
    assert.ok(preview.includes(token), `studio keeps ${token}`);
  }
  assert.match(read("src/content/site.js"), /hero_pixel_studio_screen\.png/, "original editor screenshot stays in the case rail");
  assert.match(read("src/styles.css"), /@import "\.\/styles\/sprite\.css";/);
});

test("main sprite brief: after workflow, original GIFs only, no studio data/timers, new-tab detail link", () => {
  assert.equal(SECTION_IDS.sprite, "sprite");
  const brief = read("src/components/sprite/SpriteBrief.jsx");
  assert.match(brief, /id=\{SECTION_IDS\.sprite\}/);
  assert.match(brief, /href=\{SPRITE_ROUTE\} target="_blank" rel="noopener noreferrer"/);
  assert.match(brief, /import meta from "\.\.\/\.\.\/content\/pixel-assets\.json"/);
  // AI-NOTE 주석은 "import 하지 않는다"는 설명으로 금지 단어를 언급하므로, 주석 범위만 공백으로 지우고 실제 코드(문자열 포함)를 검사한다.
  const briefCode = stripComments(brief);
  assert.doesNotMatch(briefCode, /pixel\/assets\.js|pixel-layers|usePixelPreview|setTimeout|setInterval|<canvas/, "no layer data, mapping or timers on the main page");
  assert.match(brief, /reduced \? motion\.frames\[0\]\.src : motion\.gif/, "reduced motion shows the original still frame");
  for (const motion of meta.motions) {
    assert.ok(existsSync(path.join(root, "public", motion.gif)), motion.gif);
    assert.ok(existsSync(path.join(root, "public", motion.frames[0].src)), motion.frames[0].src);
  }
  const css = read("src/styles/sprite.css");
  assert.match(css, /\.sprite-brief__hero img \{[^}]*image-rendering: pixelated;/);
  assert.match(css, /\.sprite-brief__link \{[^}]*min-height: 48px;/);
  assert.doesNotMatch(css, /filter:/);
});
