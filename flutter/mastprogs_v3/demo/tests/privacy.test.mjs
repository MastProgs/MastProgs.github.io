import assert from "node:assert/strict";
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import path from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import { parse } from "@babel/parser";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (relative) => readFileSync(path.join(root, relative), "utf8");

function listFiles(dir) {
  const absolute = path.join(root, dir);
  return readdirSync(absolute, { recursive: true })
    .map((name) => path.join(dir, String(name)))
    .filter((relative) => statSync(path.join(root, relative)).isFile());
}

const sourceFiles = listFiles("src").filter((file) => /\.(jsx?|css)$/.test(file));
// AI-NOTE: 외부 주소 금지의 유일한 예외는 사용자가 직접 준 포트폴리오 주소 하나다. resume.js 의 이 정확한 상수 선언 한 줄만
// 검사 전에 지우고, 나머지 파일·나머지 줄의 외부 주소·소셜 링크·이메일·전화 검사는 그대로 둔다.
const PORTFOLIO_FILE = path.join("src", "content", "resume.js");
const PORTFOLIO_DECLARATION = 'export const PORTFOLIO_URL = "https://github.com/MastProgs";';
const withoutPortfolioException = (file, text) => (file === PORTFOLIO_FILE ? text.replace(PORTFOLIO_DECLARATION, "") : text);

const shippedText = [...sourceFiles, "index.html", "vite.config.mjs", "public/_headers"].map((file) => ({
  file,
  text: withoutPortfolioException(file, read(file)),
}));

test("portfolio URL exception is exactly one declaration in resume.js", () => {
  const resume = read(PORTFOLIO_FILE);
  assert.equal(resume.split(PORTFOLIO_DECLARATION).length - 1, 1, "declared exactly once");
  for (const file of sourceFiles) {
    assert.equal(read(file).includes("github.com/MastProgs") && file !== PORTFOLIO_FILE, false, `${file} repeats the URL literal`);
  }
});

const EMAIL = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i;
const KOREAN_PHONE = /\b0\d{1,2}[-. ]?\d{3,4}[-. ]?\d{4}\b/;
const DATE_LIKE = /\b(19|20)\d{2}[-./]\d{1,2}[-./]\d{1,2}\b/;

// AI-NOTE: OKLab 계수 같은 소수 숫자 리터럴(예: 0.0259040371)이 전화번호 정규식에 걸리지 않도록,
// JS/JSX 는 NumericLiteral 토큰 자리만 같은 길이의 공백으로 지운 뒤 검사한다. 문자열·템플릿·JSX 텍스트·주석은 그대로 검사된다.
function withoutNumericLiterals(code) {
  const ast = parse(code, { sourceType: "module", plugins: ["jsx"], tokens: true });
  let result = code;
  for (const token of ast.tokens) {
    if (token.type?.label !== "num" && token.type !== "NumericLiteral") continue;
    result = result.slice(0, token.start) + " ".repeat(token.end - token.start) + result.slice(token.end);
  }
  return result;
}
const phoneScanText = (file, text) => (/\.jsx?$/.test(file) ? withoutNumericLiterals(text) : text);

test("no public contact details, birthdates or contact links in shipped source", () => {
  for (const { file, text } of shippedText) {
    assert.doesNotMatch(text, /mailto:|tel:|sms:/i, `${file} has a contact link`);
    assert.doesNotMatch(text, EMAIL, `${file} has an email address`);
    assert.doesNotMatch(phoneScanText(file, text), KOREAN_PHONE, `${file} has a phone number`);
    assert.doesNotMatch(text, DATE_LIKE, `${file} has a date that could be a birthdate`);
    assert.doesNotMatch(text, /\bdownload\b/i, `${file} offers a download`);
  }
  // 이메일·전화는 칸만 있고 값은 비어 있어야 한다(본인이 나중에 채울 때 이 검사도 함께 고친다).
  // 포트폴리오 칸만 문자열이 아닌 PORTFOLIO_URL 상수를 값으로 쓴다.
  const resume = read("src/content/resume.js");
  const values = [...resume.matchAll(/id: "(\w+)", label: "[^"]+", value: ("[^"]*"|PORTFOLIO_URL)/g)].map((match) => [match[1], match[2]]);
  assert.deepEqual(values, [["email", '""'], ["phone", '""'], ["profile", "PORTFOLIO_URL"]]);
});

test("phone scan ignores numeric math but still catches real phone numbers", () => {
  const math = "export const M = [0.0259040371, -0.2034445015, 0.4122214708];";
  assert.match(math, KOREAN_PHONE, "raw text would be a false positive");
  assert.doesNotMatch(phoneScanText("math.js", math), KOREAN_PHONE);
  const leaks = [
    'export const phone = "010-1234-5678";',
    "export const phone = `010 1234 5678`;",
    "export const n = 0.5; export const phone = '01012345678';",
    "export const C = () => <p>010.1234.5678</p>;",
    "// 연락처 010-1234-5678\nexport const x = 1;",
  ];
  for (const code of leaks) assert.match(phoneScanText("leak.jsx", code), KOREAN_PHONE, code);
  // JSON 데이터의 문자열 값도 같은 기준으로 본다.
  for (const file of listFiles("src").filter((name) => /\.json$/.test(name))) {
    const strings = [];
    JSON.stringify(JSON.parse(read(file)), (key, value) => {
      if (typeof key === "string") strings.push(key);
      if (typeof value === "string") strings.push(value);
      return value;
    });
    for (const value of strings) {
      assert.doesNotMatch(value, KOREAN_PHONE, `${file} has a phone number`);
      assert.doesNotMatch(value, EMAIL, `${file} has an email address`);
    }
  }
});

test("no source résumé PDF or document is shipped", () => {
  const publicFiles = listFiles("public");
  assert.ok(publicFiles.every((file) => !/\.(pdf|docx?|hwp)$/i.test(file)), "public/ must not contain résumé documents");
  for (const file of sourceFiles) assert.doesNotMatch(read(file), /\.pdf\b/i, `${file} references a PDF`);
});

test("no external requests, analytics, remote fonts or social links", () => {
  for (const { file, text } of shippedText) {
    assert.doesNotMatch(text, /https?:\/\//i, `${file} references an external URL`);
    assert.doesNotMatch(text, /googletagmanager|gtag\(|analytics|fonts\.googleapis|fonts\.gstatic|sendBeacon|XMLHttpRequest/i, file);
    assert.doesNotMatch(text, /linkedin|github\.com|instagram|facebook|twitter|kakao/i, `${file} has a social link`);
  }
  for (const file of sourceFiles) {
    assert.doesNotMatch(read(file), /\bfetch\(/, `${file} performs a network call`);
  }
});

test("index.html is Korean, noindex and carries no SEO or OG metadata", () => {
  const html = read("index.html");
  assert.match(html, /<html lang="ko">/);
  assert.match(html, /<meta name="robots" content="noindex, noarchive"/);
  assert.doesNotMatch(html, /og:|twitter:|name="description"|name="keywords"|rel="canonical"|application\/ld\+json/i);
});

test("servers bind locally and send noindex headers; no robots.txt or sitemap", () => {
  const config = read("vite.config.mjs");
  assert.match(config, /"X-Robots-Tag": "noindex, noarchive"/);
  assert.match(config, /server:\s*{[^}]*host: LOCAL_HOST/s);
  assert.match(config, /preview:\s*{[^}]*host: LOCAL_HOST[^}]*headers: NO_INDEX_HEADERS/s);
  assert.match(config, /LOCAL_HOST = "127\.0\.0\.1"/);
  assert.doesNotMatch(config, /0\.0\.0\.0/);
  assert.match(read("public/_headers"), /X-Robots-Tag: noindex, noarchive/);
  assert.equal(existsSync(path.join(root, "public/robots.txt")), false);
  assert.equal(existsSync(path.join(root, "public/sitemap.xml")), false);
});

// AI-NOTE: 사용자 명시 요청으로 데모 안내 문구·"(설명용)" 꼬리표·직함을 뺐다. 다시 들어오지 않게 막는다.
// 주석(AI-NOTE 등)은 화면에 나오지 않으므로 문자열·템플릿·JSX 텍스트 값만 모아 검사한다.
function renderableStrings(code) {
  const ast = parse(code, { sourceType: "module", plugins: ["jsx"] });
  const values = [];
  const visit = (node) => {
    if (Array.isArray(node)) return node.forEach(visit);
    if (!node || typeof node.type !== "string") return;
    if (node.type === "StringLiteral" || node.type === "JSXText" || node.type === "DirectiveLiteral") values.push(node.value);
    if (node.type === "TemplateElement") values.push(node.value.cooked ?? node.value.raw);
    for (const [key, child] of Object.entries(node)) {
      if (/^(leading|trailing|inner)Comments$|^comments$|^loc$/.test(key)) continue;
      if (child && typeof child === "object") visit(child);
    }
  };
  visit(ast.program);
  return values;
}

test("UI does not render removed disclaimers or display title", () => {
  // 직함은 예전 표기("워크플로")와 표준 표기("워크플로우") 둘 다 막는다. 용어 통일이 예전 직함을 허용하는 구멍이 되면 안 된다.
  const phrases = ["설명용", "실제 AI 실행 아님", "실제 AI를 호출하지", "미리 정한 시나리오", "AI 워크플로 엔지니어", "AI 워크플로우 엔지니어"];
  const check = (file, text) => {
    for (const phrase of phrases) assert.ok(!text.includes(phrase), `${file} must not render "${phrase}"`);
  };
  for (const file of listFiles("src").filter((name) => /\.jsx?$/.test(name))) {
    for (const value of renderableStrings(read(file))) check(file, value);
  }
  for (const file of ["index.html", ...listFiles("src").filter((name) => /\.html$/.test(name))]) {
    check(file, read(file).replace(/<!--[\s\S]*?-->/g, ""));
  }
});

// AI-NOTE: 사용자 지시("자꾸 워크플로 라고 하지말고 워크플로우 라고 해")로 한국어 표기는 "워크플로우"로 통일한다.
// 화면 문자열(JS/JSX 는 구문 트리의 문자열·템플릿·JSX 텍스트, aria-label 포함)과 함께, 주석·CSS·JSON·HTML·worker·public 텍스트의
// 원문 전체도 검사한다. CSS 는 JS 파서에 넣지 않고 원문만 본다. 영어 식별자(workflow, AgentWorkflow)·경로는 대상이 아니다.
// 외부 참고 문서(docs/reference, docs/design 계약)는 출처 보존을 위해 검사하지 않는다.
const OLD_WORKFLOW_TERM = /워크플로(?!우)/;
const TEXT_EXT = /\.(jsx?|mjs|css|json|html|txt|md|svg)$|(^|[\\/])_headers$/;

test("Korean wording always uses 워크플로우, never 워크플로", () => {
  assert.match("AI 워크플로 설계", OLD_WORKFLOW_TERM, "regex catches the old term");
  assert.doesNotMatch("AI 워크플로우 설계 · 워크플로우와", OLD_WORKFLOW_TERM, "regex keeps correct words");
  for (const file of listFiles("src").filter((name) => /\.jsx?$/.test(name))) {
    for (const value of renderableStrings(read(file))) assert.doesNotMatch(value, OLD_WORKFLOW_TERM, `${file} renders "${value}"`);
  }
  const rawFiles = [
    "index.html",
    ...listFiles("src").filter((name) => TEXT_EXT.test(name)),
    ...listFiles("public").filter((name) => TEXT_EXT.test(name)),
    ...(existsSync(path.join(root, "worker")) ? listFiles("worker").filter((name) => TEXT_EXT.test(name)) : []),
  ];
  for (const file of rawFiles) assert.doesNotMatch(read(file), OLD_WORKFLOW_TERM, `${file} uses 워크플로 instead of 워크플로우`);
});

test("UI ships only local images", () => {
  const content = read("src/content/site.js");
  const imageSource = content + read("src/content/resume.js");
  const imagePaths = [...imageSource.matchAll(/src: "([^"]+)"/g)].map((match) => match[1]);
  assert.ok(imagePaths.length >= 5);
  for (const imagePath of imagePaths) {
    assert.ok(existsSync(path.join(root, "public", imagePath)), `${imagePath} must be a bundled local asset`);
  }
});
