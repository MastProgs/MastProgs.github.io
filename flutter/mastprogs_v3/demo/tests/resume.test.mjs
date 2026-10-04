import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { parse } from "@babel/parser";
import { stripComments } from "./strip-comments.mjs";
import { ABOUT, CAREER, CONTACT, PHOTO, PORTFOLIO_URL, SKILLS, contactHref, contactValue, formatPeriod, isCurrentEntry } from "../src/content/resume.js";
import { CASES, IDENTITY, NAV_LINKS, RESUME_LINKS, SECTION_IDS } from "../src/content/site.js";

const resumeSource = readFileSync(new URL("../src/content/resume.js", import.meta.url), "utf8");

// 소스 배치 검사용: AI-NOTE 등 주석을 파서 기준으로 비워 실제로 실행되는 코드만 본다.
const readCode = (path) => stripComments(readFileSync(new URL(`../src/${path}`, import.meta.url), "utf8"));

test("identity keeps the original name and portrait", () => {
  assert.equal(IDENTITY.name, "김형준");
  assert.equal(PHOTO.src, "/profile/myface4.png");
});

test("career lists all six companies newest first with source periods and roles", () => {
  const rows = CAREER.entries.map((entry) => [entry.company, entry.start, entry.end, entry.role]);
  assert.deepEqual(rows, [
    ["리치포켓", "2023.07", null, "1인 창업 · 서비스 개발"],
    ["알레프리서치코리아", "2024.04", "2024.07", "블록체인 코어 개발"],
    ["위메이드플러스", "2021.09", "2023.06", "게임 서버 · 웹 서버 개발"],
    ["조이시티", "2020.09", "2021.04", "라이브 게임 서버 개발"],
    ["한빛소프트", "2020.02", "2020.05", "게임 서버 개발"],
    ["모아이게임즈", "2017.08", "2019.12", "MMORPG 서버 개발"],
  ]);
  for (const entry of CAREER.entries) {
    assert.ok(entry.duties.length > 0, `${entry.company} needs responsibilities`);
    assert.ok(entry.duties.every((duty) => duty.trim().length > 0));
  }
});

test("periods format with 현재 for the ongoing entry and never sum years", () => {
  assert.equal(formatPeriod(CAREER.entries[0]), "2023.07 – 현재");
  assert.equal(formatPeriod(CAREER.entries[5]), "2017.08 – 2019.12");
  assert.deepEqual(
    CAREER.entries.filter(isCurrentEntry).map((entry) => entry.id),
    ["richpocket"],
  );
  assert.doesNotMatch(resumeSource, /\d+\s*년\s*(차|경력)|총\s*경력/, "no summed tenure");
});

test("education and grouped skills carry no self-ratings", () => {
  assert.deepEqual(
    SKILLS.education.map((item) => [item.date, item.school, item.degree]),
    [
      ["2023.02", "국민대학교 소프트웨어융합대학원", "석사 졸업"],
      ["2018.02", "한국공학대학교", "학사 졸업"],
    ],
  );
  assert.deepEqual(
    SKILLS.groups.map((group) => group.label),
    ["AI", "프로그래밍", "프론트엔드", "서버·데이터", "OS·클라우드", "형상관리·배포"],
  );
  for (const group of SKILLS.groups) {
    assert.deepEqual(Object.keys(group).sort(), ["id", "items", "label"], `${group.label} has only names`);
    assert.ok(group.items.every((item) => typeof item === "string" && !/%|★|☆/.test(item)));
  }
});

test("email/phone stay empty; only the exact portfolio URL becomes a link", () => {
  assert.deepEqual(
    CONTACT.fields.map((field) => [field.id, field.label]),
    [["email", "이메일"], ["phone", "전화"], ["profile", "포트폴리오"]],
  );
  assert.equal(PORTFOLIO_URL, "https://github.com/MastProgs");
  const [email, phone, profile] = CONTACT.fields;
  for (const field of [email, phone]) {
    assert.equal(field.value, "", `${field.label} must stay empty until the owner fills it`);
    assert.equal(contactValue(field), null);
    assert.equal(contactHref(field), null);
  }
  assert.equal(contactValue(profile), PORTFOLIO_URL);
  assert.equal(contactHref(profile), PORTFOLIO_URL);
  // 다른 주소나 다른 칸에 같은 주소가 들어와도 링크가 되지 않는다(일반 텍스트).
  assert.equal(contactHref({ id: "profile", value: "https://example.com" }), null);
  assert.equal(contactHref({ id: "profile", value: `${PORTFOLIO_URL}/other` }), null);
  assert.equal(contactHref({ id: "email", value: PORTFOLIO_URL }), null);
  assert.equal(contactValue({ value: "  " }), null);
  assert.equal(contactValue({ value: " x " }), "x");
  assert.ok(CONTACT.emptyValue.length > 0);
});

test("contact slot link opens in a new tab safely and only through contactHref", () => {
  const slots = readCode("components/resume/ContactSlots.jsx");
  const anchors = slots.match(/<a\b[^>]*>/g) ?? [];
  assert.equal(anchors.length, 1, "exactly one link element");
  assert.match(anchors[0], /href=\{href\}/);
  assert.match(anchors[0], /target="_blank"/);
  assert.match(anchors[0], /rel="noopener noreferrer"/);
  assert.match(slots, /const href = contactHref\(field\)/);
  assert.match(slots, /href !== null \?/);
});

test("résumé data omits personal and application-specific details", () => {
  // 주석(AI-NOTE 의 포트폴리오 주소 설명)은 빼고 실제 이력 데이터·코드만 본다. 허용된 포트폴리오 URL 상수는 이 단어들에 걸리지 않는다.
  assert.doesNotMatch(readCode("content/resume.js"), /생년월일|성별|병역|주소|크래프톤|KRAFTON|FDE/);
});

test("self-introduction covers the career arc and values", () => {
  const story = ABOUT.story.join(" ");
  for (const keyword of ["QA", "서버", "인공지능", "창업"]) assert.match(story, new RegExp(keyword));
  assert.equal(ABOUT.values.length, 3);
});

test("in-page links point at sections and case cards that exist", () => {
  const anchors = new Set([...Object.values(SECTION_IDS), ...CASES.map((item) => item.id)].map((id) => `#${id}`));
  for (const item of ABOUT.highlights) assert.ok(anchors.has(item.href), `${item.href} must exist`);
  for (const link of [...RESUME_LINKS, ...NAV_LINKS]) assert.ok(anchors.has(link.href), `${link.href} must exist`);
  assert.deepEqual(
    RESUME_LINKS.map((link) => link.href),
    ["#about", "#skills", "#career"],
  );
});

// 사용자 지시: 소개 → 학력·역량 → 핵심 구현(워크플로우·스프라이트·Voice to SRT 요약) → 회사 경력 → 작업 사례. 유일한 h1 은 이름.
// (갱신) 예전 03 워크플로우·04 스프라이트 섹션은 03 핵심 구현 하나로 묶였다. 하위 구성은 이 파일 끝의 구문 트리 검사가 본다.
test("page order follows the résumé order and the only h1 is the person", async () => {
  const { CORE, CASES_RAIL } = await import("../src/content/site.js");
  const app = readCode("App.jsx");
  const main = app.slice(app.indexOf("<main>"));
  const order = ["<ProfileSection", "<SkillsSection", "<CoreSection", "<CareerSection", "<CasesSection"].map((tag) => main.indexOf(tag));
  // 사용자 최신 지시: 학력·역량과 핵심 구현 사이의 독립 히어로는 없다.
  assert.doesNotMatch(app, /<Hero\b|<ProfileTheme\b|components\/Hero\.jsx/, "no standalone hero is mounted in App");
  assert.match(main, /<SkillsSection[^>]*\/>\s*<CoreSection\b/, "핵심 구현 follows Skills directly");
  assert.doesNotMatch(main, /<WorkflowSummary|<SpriteBrief|<SubtitlesBrief/, "no separate top-level workflow/sprite/subtitles sections");
  assert.doesNotMatch(app, /<WorkflowStage/, "the full stage is no longer mounted on the main page");
  assert.doesNotMatch(main, /<PixelStudioPreview|<SpritePage/, "the full studio is not mounted on the main page");
  assert.ok(order.every((pos) => pos > 0), "all sections are rendered");
  assert.deepEqual([...order].sort((a, b) => a - b), order);
  assert.deepEqual([ABOUT.index, SKILLS.index, CORE.index, CAREER.index, CASES_RAIL.index], ["01", "02", "03", "04", "05"]);
  assert.deepEqual(
    NAV_LINKS.map((link) => [link.href, link.label]),
    [["#about", "소개"], ["#skills", "학력·역량"], ["#core", "핵심 구현"], ["#career", "회사 경력"], ["#cases", "작업 사례"]],
  );

  const sources = ["Hero", "ProfileSection", "SiteHeader", "StickyBar", "SiteFooter", "ContactDialog", "sprite/SpriteBrief", "core/CoreSection", "core/CoreItem", "workflow/WorkflowSummary", "subtitles/SubtitlesBrief"].map((name) =>
    readCode(`components/${name}.jsx`),
  );
  const h1Count = sources.reduce((sum, text) => sum + (text.match(/<h1[\s>]/g) ?? []).length, 0);
  assert.equal(h1Count, 1);
  assert.match(sources[1], /<h1 id="about-title" className="profile__name">\s*\{IDENTITY\.name\}/);
});

// 사용자 최신 지시: 워크플로우 주제 두 줄은 소개 안의 대표 주제(h2)이고, 본문 중간의 이력 바로가기 묶음은 없다.
test("the representative theme lives inside 소개 without the inline résumé jump links", async () => {
  const { HERO } = await import("../src/content/site.js");
  // 사용자 최신 문구(문장부호 추가 없음). 두 줄은 실제 공백 하나로 이어 읽힌다.
  assert.deepEqual(HERO.lines, ["불필요하게 반복하는 일을", "검증된 자동화 AI 워크플로우로"]);
  assert.equal(HERO.lines.join(" "), "불필요하게 반복하는 일을 검증된 자동화 AI 워크플로우로");
  const theme = readCode("components/Hero.jsx");
  assert.match(theme, /export function ProfileTheme\b/);
  assert.match(theme, /<h2 id="profile-theme-title"[^>]*>[\s\S]*HERO\.lines/);
  assert.match(theme, /index > 0 && " "/, "the line break carries a real JSX whitespace, not only a CSS pseudo element");
  // CSS 는 Babel 로 파싱할 수 없으므로 블록 주석만 지운다(CSS 에는 문자열 안 주석 기호가 없다).
  const css = readFileSync(new URL("../src/styles/header-hero.css", import.meta.url), "utf8").replace(/\/\*[\s\S]*?\*\//g, "");
  assert.doesNotMatch(css, /profile-theme__line[^{]*::before/, "no pseudo-element spacing");
  assert.doesNotMatch(theme, /<nav\b|RESUME_LINKS|RESUME_NAV_HEADING|<section\b|<h1[\s>]/, "no inline résumé nav, own section or h1");
  assert.match(readCode("components/SiteHeader.jsx"), /RESUME_LINKS\.map/, "header résumé column stays");
});

// 사용자 지시: "연락처는 바로 보여야지". 연락처 칸은 이름 다음, 긴 소개 글 앞에 항상 보인다.
// 사용자 최신 지시: 왼쪽 위 이름과 "연락" 내비게이션(헤더·모바일 메뉴·고정 바)은 없앤다. 이름·사진·연락처 칸은 소개에, 이름은 푸터에 남는다.
test("contact slots stay right after the name in 소개 while chrome has no name or 연락 navigation", () => {
  const read = (name) => readFileSync(new URL(`../src/components/${name}.jsx`, import.meta.url), "utf8");
  const profile = stripComments(read("ProfileSection"));
  const positions = ['className="profile__name"', "id={SECTION_IDS.contact}", "<ContactSlots", "profile__photo", "<ProfileTheme", "ABOUT.headline", "ABOUT.story"].map((token) =>
    profile.indexOf(token),
  );
  assert.ok(positions.every((pos) => pos > 0), "name, contact anchor, slots, photo and story are rendered");
  assert.deepEqual([...positions].sort((a, b) => a - b), positions, "name → contact → photo → theme → QA headline → story");
  assert.equal(SECTION_IDS.contact, "contact");
  for (const name of ["SiteHeader", "StickyBar"]) {
    const source = read(name).replace(/^\s*\/\/.*$/gm, "");
    assert.doesNotMatch(source, /SECTION_IDS\.contact|#contact|CONTACT\.buttonLabel|"연락"/, `${name} has no contact navigation`);
    assert.doesNotMatch(source, /IDENTITY\.name|__name/, `${name} does not show the name in the chrome`);
    assert.doesNotMatch(source, /aria-haspopup="dialog"/, `${name} must not hide contact behind a dialog`);
    assert.match(source, /<ThemeToggle\b/, `${name} carries the theme control`);
  }
  assert.ok(NAV_LINKS.every((link) => link.href !== "#contact" && link.label !== "연락"));
  assert.match(read("SiteFooter"), /\{IDENTITY\.name\}/, "footer keeps identity");
  assert.doesNotMatch(readFileSync(new URL("../src/App.jsx", import.meta.url), "utf8"), /<ContactDialog/);
});

// ── 03 핵심 구현 묶음(구문 트리 기준) ────────────────────────
// 사용자 최신 지시: "3 4 번이 별도로 있는데, 차라리 3번으로 핵심 구현 … 하위 항목으로 … srt 도 추가하자".
// 주석은 파서가 따로 모으므로 주석 속 단어가 코드로 잡히지 않는다.

const readTree = (path) => {
  const source = readFileSync(new URL(`../src/${path}`, import.meta.url), "utf8");
  return { source, program: parse(source, { sourceType: "module", plugins: ["jsx"] }).program };
};

// JSX 요소를 소스 순서대로 모은다. 속성 값은 소스 그대로(예: "{SECTION_IDS.workflow}", "\"_blank\"").
const jsxElements = (path) => {
  const { source, program } = readTree(path);
  const found = [];
  const visit = (node) => {
    if (!node || typeof node.type !== "string") return;
    if (node.type === "JSXElement") {
      const opening = node.openingElement;
      const attrs = {};
      for (const attr of opening.attributes) {
        if (attr.type === "JSXAttribute") attrs[attr.name.name] = attr.value ? source.slice(attr.value.start, attr.value.end) : true;
      }
      found.push({ name: source.slice(opening.name.start, opening.name.end), attrs, start: node.start });
    }
    for (const [key, value] of Object.entries(node)) {
      if (key === "loc" || key === "leadingComments" || key === "trailingComments" || key === "innerComments") continue;
      if (Array.isArray(value)) value.forEach(visit);
      else if (value && typeof value.type === "string") visit(value);
    }
  };
  visit(program);
  return found.sort((a, b) => a.start - b.start);
};

const importSources = (path) =>
  readTree(path).program.body.filter((node) => node.type === "ImportDeclaration").map((node) => node.source.value);

test("03 핵심 구현 groups AgentWorkflow → Sprite → Voice to SRT under one h2 with h3 children and their anchors", async () => {
  const { CORE, SECTION_IDS: ids } = await import("../src/content/site.js");
  assert.deepEqual(
    CORE.items.map((item) => [item.id, item.index, item.label]),
    [["workflow", "01", "AgentWorkflow"], ["sprite", "02", "Sprite 파이프라인"], ["subtitles", "03", "Voice to SRT"]],
  );
  assert.equal(CORE.title, "핵심 구현");
  assert.deepEqual([ids.core, ids.workflow, ids.sprite, ids.subtitles], ["core", "workflow", "sprite", "subtitles"]);

  const group = jsxElements("components/core/CoreSection.jsx");
  const names = group.map((el) => el.name);
  assert.equal(group[0].name, "section");
  assert.equal(group[0].attrs.id, "{SECTION_IDS.core}");
  assert.equal(names.filter((name) => name === "h2").length, 1, "one parent heading");
  assert.ok(!names.includes("h3") && !names.includes("h1"));
  const children = ["WorkflowSummary", "SpriteBrief", "SubtitlesBrief"].map((name) => names.indexOf(name));
  assert.ok(children.every((pos) => pos > 0), "all three children are mounted");
  assert.deepEqual([...children].sort((a, b) => a - b), children, "child order");
  assert.ok(names.indexOf("nav") < children[0], "group sub-navigation precedes the children");
  assert.ok(!names.some((name) => /tab|Accordion|details/i.test(name)), "children are stacked, never tabs or accordions");

  const shell = jsxElements("components/core/CoreItem.jsx");
  assert.equal(shell[0].name, "article");
  assert.equal(shell[0].attrs.id, "{id}");
  assert.deepEqual(shell.filter((el) => /^h\d$/.test(el.name)).map((el) => el.name), ["h3"], "children use h3 only");

  const routes = { workflow: "{DETAIL_ROUTE}", sprite: "{SPRITE_ROUTE}", subtitles: "{SUBTITLES_ROUTE}" };
  for (const [file, id] of [["workflow/WorkflowSummary", "workflow"], ["sprite/SpriteBrief", "sprite"], ["subtitles/SubtitlesBrief", "subtitles"]]) {
    const elements = jsxElements(`components/${file}.jsx`);
    assert.equal(elements[0].name, "CoreItem", `${file} renders inside the shared child shell`);
    assert.equal(elements[0].attrs.id, `{SECTION_IDS.${id}}`, `${file} keeps #${id}`);
    assert.ok(!elements.some((el) => /^(section|h1|h2|h3)$/.test(el.name)), `${file} has no own section or heading`);
    const link = elements.find((el) => el.name === "a");
    assert.deepEqual([link.attrs.href, link.attrs.target, link.attrs.rel], [routes[id], '"_blank"', '"noopener noreferrer"'], `${file} opens its detail in a new tab`);
  }
});

test("main page core summaries import no heavy detail data, studio runtime or subtitle walkthrough", async () => {
  const { SRT_BRIEF } = await import("../src/content/site.js");
  const forbidden = /content\/subtitles\.js|subtitles\/model|SubtitleWalkthrough|SubtitlesPage|pixel\/assets\.js|pixel-layers|usePixelPreview|PixelStudioPreview/;
  for (const file of ["App.jsx", "components/core/CoreSection.jsx", "components/core/CoreItem.jsx", "components/subtitles/SubtitlesBrief.jsx", "components/cases/CaseDiagram.jsx", "components/workflow/WorkflowSummary.jsx", "components/sprite/SpriteBrief.jsx"]) {
    for (const source of importSources(file)) assert.doesNotMatch(source, forbidden, `${file} imports ${source}`);
  }
  assert.ok(importSources("components/subtitles/SubtitlesBrief.jsx").includes("../cases/CaseDiagram.jsx"), "SRT principle reuses the case diagram");
  assert.deepEqual(SRT_BRIEF.points.map((point) => point.label), ["시간", "AI 역할", "사람 승인"]);
  for (const value of [SRT_BRIEF.title, SRT_BRIEF.lede, ...SRT_BRIEF.points.map((point) => point.text)]) {
    assert.doesNotMatch(value, /\p{Extended_Pictographic}|설명용|데모|%|배 빠|정확도/u);
  }
});
