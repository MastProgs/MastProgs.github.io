import assert from "node:assert/strict";
import { readdirSync, readFileSync, statSync } from "node:fs";
import path from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import {
  DEFAULT_THEME,
  THEMES,
  THEME_STORAGE_KEY,
  applyTheme,
  normalizeTheme,
  readStoredTheme,
  storageFrom,
  toggleTheme,
  writeStoredTheme,
} from "../src/theme/theme.js";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (relative) => readFileSync(path.join(root, relative), "utf8");
const listFiles = (dir) =>
  readdirSync(path.join(root, dir), { recursive: true })
    .map((name) => path.join(dir, String(name)))
    .filter((relative) => statSync(path.join(root, relative)).isFile());

function fakeStorage(initial = {}) {
  const data = new Map(Object.entries(initial));
  return {
    data,
    getItem: (key) => (data.has(key) ? data.get(key) : null),
    setItem: (key, value) => data.set(key, String(value)),
  };
}

test("blocked localStorage getter yields null storage and the dark default without throwing", () => {
  const blocked = Object.defineProperty({}, "localStorage", {
    get() {
      throw new Error("SecurityError");
    },
  });
  assert.equal(storageFrom(blocked), null);
  assert.equal(storageFrom(undefined), null);
  assert.equal(readStoredTheme(storageFrom(blocked)), "dark");
  assert.equal(writeStoredTheme(storageFrom(blocked), "light"), true, "no storage → nothing written, no throw");
  const storage = fakeStorage();
  assert.equal(storageFrom({ localStorage: storage }), storage);
});

test("default is dark; only dark|light are accepted", () => {
  assert.deepEqual(THEMES, ["dark", "light"]);
  assert.equal(DEFAULT_THEME, "dark");
  assert.equal(normalizeTheme("light"), "light");
  for (const bad of [undefined, null, "", "LIGHT", "sepia", "{}", 1]) assert.equal(normalizeTheme(bad), "dark");
  assert.equal(toggleTheme("dark"), "light");
  assert.equal(toggleTheme("light"), "dark");
  assert.equal(toggleTheme("junk"), "light", "unknown values behave as the dark default");
});

test("storage whitelist: one key, one of two values, nothing else is written", () => {
  const storage = fakeStorage();
  assert.equal(readStoredTheme(storage), "dark", "nothing stored → dark");
  assert.equal(writeStoredTheme(storage, "light"), true);
  assert.deepEqual([...storage.data.entries()], [[THEME_STORAGE_KEY, "light"]]);
  assert.equal(readStoredTheme(storage), "light");
  for (const bad of ["evil", "", null, { theme: "light" }]) assert.equal(writeStoredTheme(storage, bad), false);
  assert.deepEqual([...storage.data.entries()], [[THEME_STORAGE_KEY, "light"]], "invalid values never reach storage");
  assert.equal(readStoredTheme(fakeStorage({ [THEME_STORAGE_KEY]: "<script>" })), "dark", "tampered values fall back to dark");
  const broken = { getItem: () => { throw new Error("blocked"); }, setItem: () => { throw new Error("blocked"); } };
  assert.equal(readStoredTheme(broken), "dark");
  assert.equal(writeStoredTheme(broken, "light"), false);
  assert.equal(readStoredTheme(null), "dark");
});

test("applyTheme writes only data-theme and color-scheme on the root", () => {
  const node = { dataset: {}, style: {} };
  applyTheme(node, "light");
  assert.deepEqual([node.dataset.theme, node.style.colorScheme], ["light", "light"]);
  applyTheme(node, "nope");
  assert.deepEqual([node.dataset.theme, node.style.colorScheme], ["dark", "dark"]);
});

test("theme state is central: storage is touched only by the theme module and its boot code", () => {
  const sources = listFiles("src").filter((file) => /\.(jsx?)$/.test(file));
  for (const file of sources) {
    const text = read(file);
    const normalized = file.replaceAll("\\", "/");
    if (/localStorage|sessionStorage|indexedDB|document\.cookie/.test(text)) {
      assert.ok(["src/theme/theme.js", "src/theme/ThemeContext.jsx", "src/main.jsx"].includes(normalized), `${normalized} must not use browser storage`);
      assert.doesNotMatch(text, /sessionStorage|indexedDB|document\.cookie/);
      assert.doesNotMatch(text, /localStorage\.setItem/, "writes go through writeStoredTheme only");
    }
    if (/\.setItem\(/.test(text)) assert.equal(normalized, "src/theme/theme.js");
  }
  assert.match(read("src/theme/theme.js"), /storage\?\.setItem\(THEME_STORAGE_KEY, theme\)/);
});

test("main résumé and /workflow share the same provider and both expose the theme control", () => {
  const main = read("src/main.jsx");
  assert.match(main, /<ThemeProvider>\s*<App \/>\s*<\/ThemeProvider>/);
  assert.match(main, /applyTheme\(document\.documentElement, readStoredTheme\(storage\)\)/, "theme applied before first paint");
  const app = read("src/App.jsx");
  assert.match(app, /if \(entry\.isDetail\) return <WorkflowDetailPage \/>/, "detail page renders under the same provider");
  assert.match(app, /if \(entry\.isSprite\) \{[\s\S]*?<SpritePage \/>/, "sprite page renders under the same provider");
  for (const file of ["src/components/SiteHeader.jsx", "src/components/StickyBar.jsx", "src/components/workflow-detail/WorkflowDetailPage.jsx", "src/components/sprite/SpritePage.jsx"]) {
    assert.match(read(file), /<ThemeToggle\b/, file);
  }
  const toggle = read("src/components/ThemeToggle.jsx");
  assert.match(toggle, /useTheme\(\)/);
  assert.match(toggle, /aria-label=\{copy\.switchTo\}/);
  assert.match(read("src/styles/theme.css"), /\.theme-toggle \{[^}]*min-width: 44px;[^}]*height: 44px;/);
});

const tokensIn = (block) => Object.fromEntries([...block.matchAll(/(--[\w-]+):\s*([^;]+);/g)].map((match) => [match[1], match[2].trim()]));

test("light theme redefines every colour token (stage ink intentionally shared); no image invert filters", () => {
  const css = read("src/styles/theme.css");
  const dark = tokensIn(css.match(/:root \{([\s\S]*?)\n\}/)[1]);
  const light = tokensIn(css.match(/:root\[data-theme="light"\] \{([\s\S]*?)\n\}/)[1]);
  const shared = new Set(["--stage-ink", "--stage-ink-2", "--stage-ink-3"]);
  for (const token of Object.keys(dark)) {
    if (shared.has(token)) continue;
    assert.ok(token in light, `${token} has a light value`);
  }
  assert.doesNotMatch(read("src/styles/base.css"), /--bg:|--ink:/, "colour tokens live only in theme.css");
  for (const file of listFiles("src/styles")) {
    assert.doesNotMatch(read(file), /filter:\s*[^;]*(invert|hue-rotate)/, `${file} must not fake themes or palettes with filters`);
  }
});

const luminance = (hex) => {
  const [r, g, b] = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255).map((c) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4));
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};
const contrast = (a, b) => {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
};

test("body text keeps AA contrast on page and panel backgrounds in both themes", () => {
  const css = read("src/styles/theme.css");
  const dark = tokensIn(css.match(/:root \{([\s\S]*?)\n\}/)[1]);
  const light = { ...dark, ...tokensIn(css.match(/:root\[data-theme="light"\] \{([\s\S]*?)\n\}/)[1]) };
  for (const [name, tokens] of [["dark", dark], ["light", light]]) {
    for (const bg of ["--bg", "--panel", "--surface", "--tile"]) {
      for (const fg of ["--ink", "--ink-2", "--ink-soft", "--ink-3", "--orange-text"]) {
        const ratio = contrast(tokens[fg], tokens[bg]);
        assert.ok(ratio >= 4.5, `${name} ${fg} on ${bg} = ${ratio.toFixed(2)}`);
      }
    }
  }
});
