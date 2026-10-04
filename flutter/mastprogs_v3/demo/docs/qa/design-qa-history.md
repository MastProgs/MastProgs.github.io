# Demo design QA

- Source visual: `C:/Users/khjkh/.codex/generated_images/01a100c7-4ecd-7483-a935-58fcf88189ae/exec-c6500366-8988-468d-bbea-7321818bd06e.png` (1435 x 1096 pixels).
- Authoritative contract: `docs/design/claude-visual-contract.json`.
- Implementation: `http://127.0.0.1:5173/?state=target`.
- Desktop capture: `C:/WINDOWS/TEMP/v3-demo-qa/desktop-css1440-v1.jpg` (1426 x 1090 pixels).
- Combined source/implementation input: `C:/WINDOWS/TEMP/v3-demo-qa/comparison-v1.png`.
- CSS viewport: 1440 x 1100; browser density 1.1; source contained within 1440 x 1100, implementation resized to the same comparison pane. Browser capture excludes portions of scrollbar/surface; small scale differences are not classified as layout defects.
- State: paused sequential run, QA failure on, execution 05/10.
- Mobile capture: `C:/WINDOWS/TEMP/v3-demo-qa/mobile-v1.jpg`; CSS viewport 390 x 844, client width 376; document has no horizontal overflow. Offscreen lazy image appearance in a full-page capture is not evidence of a broken asset.

## Findings

- [P1] Direct route differs from the authored behavior. `DIRECT_PATH` currently runs development/review/integration. The contract specifies request -> Master AI direct handling -> response, without separate Author/Reviewer or QA. Update the route model, UI descriptions and independent tests through Claude.
- [P2] Parallel route differs from the authored topology and totals. Current model shares planning/review and has 7/10 ticks; the contract specifies independent lanes through planning/review/development/review/QA, a merge gate, then Wiki/integration, for 8/11 ticks. Claude must reconcile implementation with the contract and document any deliberate design change.
- [P2] Mobile timeline remains a wide horizontal strip while the authored contract specifies vertical phases. The selected QA phase is initially outside the mobile track viewport. Claude must correct this or author an explicit, usable revised interaction contract.

## Fidelity surfaces

- Typography: Korean Pretendard loaded; headline hierarchy and two-line presentation retained. Browser scale/capture normalization prevents pixel-level size assertions at this pass.
- Spacing/layout: dark header and hero, light workflow panel, seven phases, split detail/history and work index are present; desktop document does not overflow. Mobile topology requires correction above.
- Colors: dark/light contrast, orange current phase, green completed phases and pink defect are present.
- Assets: genuine local diagrams and original portrait reused; no third-party reference assets or contact documents shipped. Lazy profile image must be checked after scrolling into view.
- Copy: illustrative labels and safe contact copy are present. Direct/parallel route copy requires correction.

## Functional evidence so far

- Case detail dialog opens and Escape closes it; focus returns to the originating card.
- 21 unit/privacy/keyboard tests pass, but route assertions currently validate the wrong direct/parallel interpretation.
- Production build succeeds without warnings. Packaging test was initially run before build and failed for missing dist; rerun after final build.
- Final autoplay, pause, recovery, mode switch, mobile menu, reduced motion, console and header checks are pending.

## Comparison history

1. Initial capture and combined comparison above. The required contract was inaccessible to the author because the supervisor passed a file as an allowed directory. The contract has now been copied into the app. All design and motion fixes must be authored by Claude.

## Final result

final result: blocked

## Latest verification and intentional revisions

- The user explicitly changed the document to resume-first: introduction/name/photo/contact -> education/skills -> workflow description/interaction -> company history -> case studies. Original whole-first-screen mock is therefore superseded; its workflow visual language remains the reference.
- The requested UI notices and the invented display title were removed. AI-NOTE comments retain contextual history and are excluded from rendered-copy regression checks using parsed JS/JSX literals.
- All six company entries, two education entries, grouped skills and empty contact slots are present. Name and original portrait remain. Contact links jump to the visible on-page contact area without a modal.
- Initial direct-route, parallel-topology and mobile-timeline findings were corrected by Claude. Browser verification confirmed direct 3-step completion; sequential 10-step QA defect/rework completion; parallel 11-step B-only repair with A/C waiting before merge.
- Case detail/Escape/focus return, mobile menu, contact anchor and case next/detail interactions were exercised. Fresh final reload has no console errors/warnings. Historical HMR errors during in-progress cross-file edits are not final runtime failures.
- Final unit/policy tests: 42 pass. Packaging tests: 4 pass. Production build: pass, no warnings. Dev and production-preview HEAD both return HTTP200 with X-Robots-Tag noindex,noarchive.
- Photo alignment before/after input: C:/WINDOWS/TEMP/v3-demo-qa/alignment-comparison.png. Both underlying desktop images are1426x1090 at CSS1440x1100/density1.1. Before/after source captures: alignment-desktop-before.jpg/alignment-desktop-after.jpg.
- Desktop photo/name top difference=0; photo/contact bottom difference <0.001px; photo at section left edge, metadata column separated by40px. Mobile name/photo bottom difference <0.001px; contact remains in the first844px viewport; no horizontal document overflow.
- Latest mobile evidence: C:/WINDOWS/TEMP/v3-demo-qa/alignment-mobile-after.jpg (CSS390x844).
- Fonts/typography: local Pretendard loaded, original name is the only h1, long Korean text remains readable. Spacing/layout: shared identity/contact/photo grid and section edges confirmed. Colors: existing dark resume and light/orange workflow system retained. Assets: original portrait/diagrams, modern library icons, no third-party mock assets shipped. Copy: resume-grounded content, no actual contact values and no rejected notices/title.
- Reduced-motion CSS/hooks and fallback paths were reviewed; operating-system reduced-motion emulation was not exposed by the browser tool and remains a test gap.

## Pending user decision

The user requested removal of scroll, but has not yet answered whether this means hiding scrollbar chrome, removing internal scroll areas, or replacing page scrolling with section navigation. Do not guess or claim this requirement implemented. Photo alignment and copy changes are complete; scroll handling is pending clarification.

final result: blocked


## 2026-10-04 이전 보고서 보존

# Unified frame player QA — 2026-10-04

Latest scope: one direct/sequential/independent-parallel selector, parallel default, a shared rounded music-style player and frame navigation/following. All UI and motion were authored by Claude.

## Evidence

- Source: approved existing app plus the user's latest directed changes. Before: `C:/WINDOWS/TEMP/v3-demo-qa/unified-player-before.jpg`. Matching after: `unified-player-after-matched.jpg`; both 1265×712 pixels, CSS 1280×720, scrollY=0, parallel frame0, Seed visible. Equal capture dimensions; combined comparison contains each within a 1280×720 pane, with under 2% contain scaling, no crop.
- Full comparison opened: `docs/qa/unified-player-comparison.png` (2560×760). Focused transport comparison opened: `C:/WINDOWS/TEMP/v3-demo-qa/unified-player-focus-comparison.png` (2560×340).
- Final UI: `docs/qa/unified-player-final.jpg`; changed-frame proof: `docs/qa/unified-player-frame9.jpg`. Mobile proof: `C:/WINDOWS/TEMP/v3-demo-qa/unified-player-mobile.jpg`.
- Actual responsive checks: CSS 390×844 (client/scroll376), 768 (755), 1440×1100 (1426). No document overflow. Native capture/window scale changed when temporary tabs were closed, so viewport claims use measured CSS dimensions, not requested override numbers. Overrides reset.

## Findings, fixes and fidelity

- [P1 resolved] Redundant two-level navigation replaced with exactly one radio group, three choices and one player. Independent parallel is selected on initial load; direct/sequential use the same controls.
- [P2 resolved] Square lower edge replaced by one opaque rounded player card: radius28px desktop/tablet,24px mobile, including sticky state. The outer positioning wrapper is transparent; its zero radius does not draw a square edge.
- [P2 resolved] Generic frame titles replaced by the prioritized event description. Frame9 names C's planning-review rejection; tooltip/slider accessible value retain the full description.
- [P2 resolved] Explicit follow OFF→ON now clears manual-reading suspension and reveals the current primary, including paused playback. Keyboard focus stays on controls.
- Typography: local Pretendard, legible captions and phase labels; full title available accessibly when visually truncated. Spacing: single selector, options, rounded controls, conversation and existing diagram retained; frame0 layout shifts intentionally reflect requested removal/reordering. Colors: existing cream/black/orange/green/pink palette, clear current-frame outline. Assets: original portrait/case images unchanged, modern Phosphor icons/native slider only. Content: direct3, sequential20 default, parallel30; existing Master/Seed/review/QA/merge/Wiki semantics preserved.

## Functional results

- Previous/next and keyboard slider Home/End/Arrow keys pause/seek accurately, including stepping back from30/30. All three routes share the player; direct auto-play at2× completed3/3 and stopped.
- Actual QA rewind20→19 changed QF-001 resolved→open and removed both future attempt003 buttons. Forward state derives from the same cursor, with no duplicate records (regression tests).
- Frame9 highlights A review, B plan and C rejection simultaneously; C is primary. Actual follow settled with primary top654.27/bottom704.27 inside a720px viewport below the128px sticky bottom. Slider/next-button keyboard focus remained intact.
- Follow re-enable after manual scrolling restored primary visibility while paused. Wheel/touch suspension and reduced-motion guards covered by source/pure-helper checks; native touch/reduced-motion/hidden-document transitions remain environment gaps, not claimed as executed.
- Mobile controls measured44px (43.99 fractional capture rounding), primary play52px, slider44px high. Follow retains an accessible name when its text is visually clipped. Route/options reset and speed selection tested;0.5/1/2 timing/cleanup verified in tests.
- 82 unit/privacy/model tests +4 packaging tests passed; build succeeded, warnings0. Production `/workflow` entry/refresh rendered3 radios/1 player, HTTP200, noindex meta/header, console0. Final fresh dev reload and three-route interactions: console0. Transient partial-edit HMR errors were recorded during authoring and excluded only after a fresh post-edit reload proved stable.
- Final diff/source review: no source temporary files; v3 remains untracked agent work, original v2 image preserved. No commit/deployment.

final result: passed

## Previous assessment (historical)

This is the latest assessment. Claude authored all UI/model/motion changes; the host read the local AgentWorkflow parallel and sequential-seed documents and verified the running app.

## Evidence and source

- Source: user corrections, the existing approved app/Claude visual contract, and `F:/Devlop/AgentWorkflow/docs/wiki/features/{parallel-workflow,sequential-seed-workflow}.md` (read-only).
- Before: `C:/WINDOWS/TEMP/v3-demo-qa/{sequential-review-before,legacy-parallel-before}.jpg`, each 1006×1059. After: `docs/qa/master-seed-final.jpg` (1006×1059) and `docs/qa/master-seed-parallel-wait.jpg`.
- Full-view side-by-side comparison opened: `docs/qa/master-seed-comparison.png` (2012×1099). Focused Seed/return comparison opened: `C:/WINDOWS/TEMP/v3-demo-qa/master-seed-focus-comparison.png` (2012×690). Same default viewport/surface, no density rescaling. Before was idle; after is sequential 09/20 with review rejection: different states intentionally demonstrate the added feature, not a pixel-position match. Master/Seed controls did not exist in the baseline.
- Actual breakpoints checked: CSS 1440×1100, 768, 390×844; client/scroll widths 1426, 755, 376 respectively. No horizontal overflow or phase/Seed/spec text overflow. Mobile images: `C:/WINDOWS/TEMP/v3-demo-qa/master-seed-mobile-{parallel,sequential}.jpg` (sequential 376×813).

## Findings and iteration

- [P1 resolved] Second-tab parallel previously used lockstep A/B/C chips in one shared timeline. Both parallel surfaces now use the same WorkflowPlayer/scenario and three expanded complete pipelines. Actual A completes at 12/30; at 18/30 A/C wait while B alone repairs its twice-reproduced QF-001.
- [P2 resolved] Repeated rejection history left earlier rounds unresolved. All matching pending returns now connect to the actual approval/pass round, while each reason survives; C planning rounds 1/2 resolve at 3, B QA rounds 1/2 at 3.
- [P2 resolved] Parallel Seed visibility formerly changed process/lineage. Parallel Seeds and records now remain identical when panels are hidden. Sequential Seed remains optional. QA retries resume the same independent session and inherit no implementer/Seed context.
- [P2 resolved] Merge order was confused with READY arrival order. Completion remains A/C/B, while assembly follows the frozen A/B/C contract order after every lane passes.
- [P2 resolved] Direct showed duplicate QA switches; now one per option, all disabled. Cream-panel hint contrast corrected from light grey to the existing dark stage token, keeping direct dark-panel hints light.
- [P2 resolved] Single-lane diagram retained three-way connector arms. It now has one centered vertical connection; the actual screenshot confirms this and parallel branching is preserved.

## Fidelity surfaces

- Typography: local Pretendard and readable Korean labels retained; Source/current comparisons show legible Master specification, Seed family names and review state. Checked without phase/Seed/spec clipping at 390/768/1440.
- Spacing/layout: compact résumé summary unchanged; detail starts with human/Master intake and visible WORK SPEC before any planning. Seed pair and sibling branches precede the lane stages. Single lane is centered; three lanes span desktop and stack expanded on mobile. New sections are intentional user-authorized layout changes.
- Colors: existing cream/near-black/orange, green READY and pink rejection/QA failure retained, with explicit state text. Hint foreground follows background context.
- Assets: original portrait/case images and local fonts untouched; non-deprecated Phosphor icons and functional CSS connectors only.
- Content: read-only role Seeds produce no plan/code/verdict/TODO; Planning/Development are siblings and rework resumes the same child. Master freezes scope/criteria/owned paths. All-ready integration planning/assembly/dev/review/build/QA → Wiki → final local merge matches the documents. No fabricated savings, removed disclaimers/titles or real contact values reintroduced.

## Functional verification

- Sequential planning-review failure default ON, optional OFF; QA independent. Actual return marker `wfd-return-run`, one iteration, left position observed 136.236px → 0px. Reset/options clear cursor/files. Seed switch works with Space; mode radios with arrows; lineage.json selected with Enter and read successfully.
- Both parallel surfaces show the same A/C/B completion/wait behavior and no legacy shared timeline. Seed visibility off hides panels but retains 30 ticks. Direct completes 3/3, with each irrelevant option once and disabled.
- Actual autoplay completes sequential 20/20 and parallel 30/30, then stops; QA issue resolves after re-QA. Integration sequence checked from visible final cards.
- Latest tests: 69 unit/privacy/model tests + 4 packaging tests passed; production build passed with zero warnings. Fresh-session console warnings/errors: 0. `/workflow` responds HTTP 200 with X-Robots-Tag noindex/noarchive; noindex/privacy regression tests pass.
- Reduced-motion static marker/fork rules verified by source tests; native reduced-motion/hidden-document transitions remain unavailable on this browser surface and are not claimed as executed. This is a residual environment test gap.
- Final diff/check and direct authored-source review completed; no temporary source files remain. V3 is still untracked agent work; original v2 portrait untouched.

final result: passed

## Prior workflow QA (historical)

This assessment covers the latest requested workflow update. Earlier assessments below are historical; the unanswered scroll-removal preference is outside this scope and was not guessed.

## Source and comparison evidence

- Source: existing app, Claude's `docs/design/claude-visual-contract.json`, and the user's explicit request for a short main summary and separate detailed simulation. Claude authored all UI, copy and motion changes.
- Before: `C:/WINDOWS/TEMP/v3-demo-qa/workflow-before.jpg` (1265×712), `workflow-detail-first.jpg` (915×4158; first implementation, parallel 11/21).
- After: `docs/qa/workflow-detail-final.jpg`, `docs/qa/workflow-records-final.jpg`, `C:/WINDOWS/TEMP/v3-demo-qa/human-label-mobile-final.jpg`.
- Combined comparisons opened: `workflow-comparison-full.png` (1830×2240) and `workflow-comparison-focus.png` (1830×1260), in the same temporary evidence folder.
- Matching comparison state: CSS width 1020, paused parallel 11/21. Full-page before/after captures are 915 pixels wide; the after full-page capture has a right-edge/responsive capture artifact, excluded from layout judgment. Normal screenshot `workflow-detail-same-viewport.jpg` and DOM measurements confirm all three lanes fit and the integration grid has two columns at CSS 1020, client/scroll width 1006. No pixel-perfect density assertion.
- Additional actual viewport checks: CSS 1440×1100 (client/scroll 1426), 768 (755), 390×844 (376). Three stacked expanded lanes at 768/390, no horizontal document overflow. Temporary viewport overrides reset.

## Correction history and findings

1. [P2 resolved] Human-decision text exceeded available inner spacing. Claude enabled full readable wrapping; at CSS 1265 the 144.42px card has a 110.61px label and 14.90px right inset. At 390, text is static/unclipped, 84.96px wide, with positive right inset. Mobile legacy routes retain no document overflow.
2. [P1 resolved] Outer wrapper and phase rows shared `.wfd-stage`, inheriting cream background/margins and dark text. Claude separated `.wfd-run`; rows now have transparent backgrounds, zero outer margin and readable light labels. Backward connectors remain intact. Confirmed in combined comparison and normal final captures.
3. [P2 resolved] Queued lanes incorrectly showed stage `ready` in state.json. Unassigned stage is now null; every cursor is covered by a regression test.
4. [P3 resolved] Human intervention copy now refers to this example rather than an exact universal two-decision limit. QA finding uses lane-scoped QF-001; planning return reads `기획으로 되돌림`.

## Fidelity surfaces

- Typography: local Pretendard retained, readable Korean phase labels; human-decision text fully visible on mobile. No phase-label overflow at tested widths.
- Spacing/layout: résumé order and immediate contact unchanged; main has concise summary, separate page has conversation → Master dispatch → three complete pipelines → gate/integration → record viewer. Narrow screens stack expanded lanes.
- Colors/tokens: existing cream/near-black/orange retained; green completion and pink failures have text equivalents. Corrected labels have explicit light foreground.
- Asset quality: original portrait and case images unchanged; local fonts and non-deprecated Phosphor icons. Functional CSS connectors, no decorative replacement artwork.
- Copy/content: A re-plans after rejection, B fixes after development rejection, C repairs after QA failure; other lanes continue. Rejected records remain and QA ledger resolves only after re-QA. Removed disclaimers/titles stay absent; contacts empty and noindex retained.

## Functional results

- Main new-tab entry and backlink work. Production `/workflow` entry/refresh works; meta and dev/preview headers noindex, HTTP 200; existing worker fallback test passes.
- Fan-out delays 0.12/0.26/0.40 seconds observed. Planning/development/QA return notes, attempt counts and resolved history verified.
- Autoplay reaches 21/21 and stops; gate opens after all QA passes. QF-001 changes open→resolved after re-QA. Replay/reset clears conversation/files. Enter selects and pins a file; follow mode available.
- 61 unit/privacy/model tests + 4 packaging tests pass; production build warning count 0. Fresh-load console errors/warnings 0.
- Reduced-motion CSS and hidden-document pause handler reviewed. Native reduced-motion emulation unavailable; opening another tool tab leaves document.hidden=false, so actual hidden-document transition remains an environment test gap. These are not claimed as executed.
- Final git diff/check ran; v3 is untracked agent work, so authored files reviewed directly. Original v2 portrait preserved, no commit/deployment.

final result: passed

## Historical QA (superseded where the user changed scope)

- Source visual: `C:/Users/khjkh/.codex/generated_images/01a100c7-4ecd-7483-a935-58fcf88189ae/exec-c6500366-8988-468d-bbea-7321818bd06e.png` (1435 x 1096 pixels).
- Authoritative contract: `docs/design/claude-visual-contract.json`.
- Implementation: `http://127.0.0.1:5173/?state=target`.
- Desktop capture: `C:/WINDOWS/TEMP/v3-demo-qa/desktop-css1440-v1.jpg` (1426 x 1090 pixels).
- Combined source/implementation input: `C:/WINDOWS/TEMP/v3-demo-qa/comparison-v1.png`.
- CSS viewport: 1440 x 1100; browser density 1.1; source contained within 1440 x 1100, implementation resized to the same comparison pane. Browser capture excludes portions of scrollbar/surface; small scale differences are not classified as layout defects.
- State: paused sequential run, QA failure on, execution 05/10.
- Mobile capture: `C:/WINDOWS/TEMP/v3-demo-qa/mobile-v1.jpg`; CSS viewport 390 x 844, client width 376; document has no horizontal overflow. Offscreen lazy image appearance in a full-page capture is not evidence of a broken asset.

## Findings

- [P1] Direct route differs from the authored behavior. `DIRECT_PATH` currently runs development/review/integration. The contract specifies request -> Master AI direct handling -> response, without separate Author/Reviewer or QA. Update the route model, UI descriptions and independent tests through Claude.
- [P2] Parallel route differs from the authored topology and totals. Current model shares planning/review and has 7/10 ticks; the contract specifies independent lanes through planning/review/development/review/QA, a merge gate, then Wiki/integration, for 8/11 ticks. Claude must reconcile implementation with the contract and document any deliberate design change.
- [P2] Mobile timeline remains a wide horizontal strip while the authored contract specifies vertical phases. The selected QA phase is initially outside the mobile track viewport. Claude must correct this or author an explicit, usable revised interaction contract.

## Fidelity surfaces

- Typography: Korean Pretendard loaded; headline hierarchy and two-line presentation retained. Browser scale/capture normalization prevents pixel-level size assertions at this pass.
- Spacing/layout: dark header and hero, light workflow panel, seven phases, split detail/history and work index are present; desktop document does not overflow. Mobile topology requires correction above.
- Colors: dark/light contrast, orange current phase, green completed phases and pink defect are present.
- Assets: genuine local diagrams and original portrait reused; no third-party reference assets or contact documents shipped. Lazy profile image must be checked after scrolling into view.
- Copy: illustrative labels and safe contact copy are present. Direct/parallel route copy requires correction.

## Functional evidence so far

- Case detail dialog opens and Escape closes it; focus returns to the originating card.
- 21 unit/privacy/keyboard tests pass, but route assertions currently validate the wrong direct/parallel interpretation.
- Production build succeeds without warnings. Packaging test was initially run before build and failed for missing dist; rerun after final build.
- Final autoplay, pause, recovery, mode switch, mobile menu, reduced motion, console and header checks are pending.

## Comparison history

1. Initial capture and combined comparison above. The required contract was inaccessible to the author because the supervisor passed a file as an allowed directory. The contract has now been copied into the app. All design and motion fixes must be authored by Claude.

## Final result

final result: blocked

## Latest verification and intentional revisions

- The user explicitly changed the document to resume-first: introduction/name/photo/contact -> education/skills -> workflow description/interaction -> company history -> case studies. Original whole-first-screen mock is therefore superseded; its workflow visual language remains the reference.
- The requested UI notices and the invented display title were removed. AI-NOTE comments retain contextual history and are excluded from rendered-copy regression checks using parsed JS/JSX literals.
- All six company entries, two education entries, grouped skills and empty contact slots are present. Name and original portrait remain. Contact links jump to the visible on-page contact area without a modal.
- Initial direct-route, parallel-topology and mobile-timeline findings were corrected by Claude. Browser verification confirmed direct 3-step completion; sequential 10-step QA defect/rework completion; parallel 11-step B-only repair with A/C waiting before merge.
- Case detail/Escape/focus return, mobile menu, contact anchor and case next/detail interactions were exercised. Fresh final reload has no console errors/warnings. Historical HMR errors during in-progress cross-file edits are not final runtime failures.
- Final unit/policy tests: 42 pass. Packaging tests: 4 pass. Production build: pass, no warnings. Dev and production-preview HEAD both return HTTP200 with X-Robots-Tag noindex,noarchive.
- Photo alignment before/after input: C:/WINDOWS/TEMP/v3-demo-qa/alignment-comparison.png. Both underlying desktop images are1426x1090 at CSS1440x1100/density1.1. Before/after source captures: alignment-desktop-before.jpg/alignment-desktop-after.jpg.
- Desktop photo/name top difference=0; photo/contact bottom difference <0.001px; photo at section left edge, metadata column separated by40px. Mobile name/photo bottom difference <0.001px; contact remains in the first844px viewport; no horizontal document overflow.
- Latest mobile evidence: C:/WINDOWS/TEMP/v3-demo-qa/alignment-mobile-after.jpg (CSS390x844).
- Fonts/typography: local Pretendard loaded, original name is the only h1, long Korean text remains readable. Spacing/layout: shared identity/contact/photo grid and section edges confirmed. Colors: existing dark resume and light/orange workflow system retained. Assets: original portrait/diagrams, modern library icons, no third-party mock assets shipped. Copy: resume-grounded content, no actual contact values and no rejected notices/title.
- Reduced-motion CSS/hooks and fallback paths were reviewed; operating-system reduced-motion emulation was not exposed by the browser tool and remains a test gap.

## Pending user decision

The user requested removal of scroll, but has not yet answered whether this means hiding scrollbar chrome, removing internal scroll areas, or replacing page scrolling with section navigation. Do not guess or claim this requirement implemented. Photo alignment and copy changes are complete; scroll handling is pending clarification.

final result: blocked
