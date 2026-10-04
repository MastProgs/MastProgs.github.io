import assert from "node:assert/strict";
import { readdirSync, readFileSync, statSync } from "node:fs";
import path from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const files = readdirSync(path.join(root, "src"), { recursive: true })
  .map((name) => path.join("src", String(name)))
  .filter((file) => /\.jsx?$/.test(file) && statSync(path.join(root, file)).isFile());

const PHOSPHOR_IMPORT = /import\s*{([^}]*)}\s*from\s*"@phosphor-icons\/react"/g;

// @phosphor-icons/react 2.1.x 에서 접미사 없는 이름(Play, X 등)은 @deprecated 별칭이다. *Icon 이름만 허용한다.
test("only non-deprecated *Icon exports are imported from Phosphor", () => {
  let count = 0;
  for (const file of files) {
    const text = readFileSync(path.join(root, file), "utf8");
    for (const match of text.matchAll(PHOSPHOR_IMPORT)) {
      const names = match[1].split(",").map((name) => name.trim()).filter(Boolean);
      for (const name of names) {
        count += 1;
        assert.match(name, /^[A-Z][A-Za-z]*Icon$/, `${file} imports deprecated alias ${name}`);
      }
    }
    assert.doesNotMatch(text, /@phosphor-icons\/react\/dist/, `${file} deep-imports Phosphor`);
  }
  assert.ok(count > 0, "the app uses Phosphor icons");
});

test("installed Phosphor exposes every imported *Icon name", () => {
  const csr = path.join(root, "node_modules/@phosphor-icons/react/dist/csr");
  for (const file of files) {
    const text = readFileSync(path.join(root, file), "utf8");
    for (const match of text.matchAll(PHOSPHOR_IMPORT)) {
      for (const name of match[1].split(",").map((item) => item.trim()).filter(Boolean)) {
        const base = name.replace(/Icon$/, "");
        const declaration = readFileSync(path.join(csr, `${base}.d.ts`), "utf8");
        assert.match(declaration, new RegExp(`as ${name}\\b`), `${name} must be exported by the installed package`);
      }
    }
  }
});
