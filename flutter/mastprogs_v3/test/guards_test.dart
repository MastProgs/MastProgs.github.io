// 이식 경계·개인정보·용어 보호 검사와 원본 상수 일치, 작은 순수 도우미(레일·로빙·테마·keep-all·경로) 검사.
// AI-NOTE: React tests/privacy.test.mjs·rail.test.mjs·roving.test.mjs·theme.test.mjs 의 의미를 Flutter 소스·번들 데이터에 그대로 건다.
// 원본 모델 상수는 test/fixtures 가 아닌 assets/data/constants.json(원본 모듈의 내보낸 값)과 비교한다.
import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastprogs_v3/app/theme/theme_controller.dart';
import 'package:mastprogs_v3/app/theme/typography.dart';
import 'package:mastprogs_v3/core/json.dart';
import 'package:mastprogs_v3/core/public_assets.dart';
import 'package:mastprogs_v3/features/portfolio/portfolio_content.dart';
import 'package:mastprogs_v3/features/portfolio/view/cases_section.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_outline.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_playback.dart';
import 'package:mastprogs_v3/features/sprite/model/pixel_timeline.dart';
import 'package:mastprogs_v3/features/subtitles/model/subtitles_model.dart';
import 'package:mastprogs_v3/features/workflow/model/workflow_frames.dart';
import 'package:mastprogs_v3/features/workflow/model/workflow_reducer.dart';
import 'package:mastprogs_v3/features/workflow/model/workflow_scenario.dart';
import 'package:mastprogs_v3/features/workflow/view/route_controls.dart';
import 'package:mastprogs_v3/platform/host_platform.dart';

import 'support/fixtures.dart';

Iterable<File> filesUnder(String dir, bool Function(String path) accept) =>
    Directory(dir).listSync(recursive: true).whereType<File>().where((file) => accept(file.path.replaceAll('\\', '/')));

void main() {
  final shippedText = <String, String>{
    for (final file in filesUnder('lib', (path) => path.endsWith('.dart'))) file.path: file.readAsStringSync(),
    for (final file in filesUnder('web', (path) => path.endsWith('.html') || path.endsWith('.js'))) file.path: file.readAsStringSync(),
    for (final file in filesUnder('assets/data', (path) => path.endsWith('.json'))) file.path: file.readAsStringSync(),
  };

  group('privacy and boundary guards', () {
    test('the only external URL anywhere in shipped code/data is the exact portfolio link', () {
      final url = RegExp(
        r'https?://[^\s"'
        "'"
        r'`)\]]+',
      );
      final found = <String>{};
      for (final entry in shippedText.entries) {
        for (final match in url.allMatches(entry.value)) {
          found.add('${entry.key.replaceAll('\\', '/')}: ${match.group(0)}');
        }
      }
      expect(found, {'assets/data/resume.json: https://github.com/MastProgs'});
    });

    test('no analytics, remote fonts, network calls, mailto/tel or social links in shipped code', () {
      for (final entry in shippedText.entries.where((entry) => entry.key.endsWith('.dart') || entry.key.endsWith('.html') || entry.key.endsWith('.js'))) {
        expect(
          entry.value,
          isNot(matches(RegExp(r'googletagmanager|gtag\(|analytics|fonts\.googleapis|sendBeacon|XMLHttpRequest|mailto:|tel:', caseSensitive: false))),
          reason: entry.key,
        );
        expect(entry.value, isNot(matches(RegExp(r'linkedin|instagram|facebook|twitter|kakao', caseSensitive: false))), reason: entry.key);
        expect(entry.value, isNot(contains('package:http')), reason: entry.key);
      }
    });

    test('no deprecated web/Flutter APIs, iframes, WebViews or JS model runtime', () {
      for (final entry in shippedText.entries.where((entry) => !entry.key.endsWith('.json'))) {
        expect(entry.value, isNot(contains('dart:html')), reason: entry.key);
        expect(entry.value, isNot(contains('withOpacity(')), reason: entry.key);
        expect(entry.value, isNot(contains('loadEntrypoint')), reason: entry.key);
        expect(entry.value, isNot(matches(RegExp(r'<iframe|HtmlElementView|WebView|evalJs|js\.context', caseSensitive: false))), reason: entry.key);
      }
    });

    test('Korean wording always uses 워크플로우 and removed disclaimers/titles never ship', () {
      final oldTerm = RegExp('워크플로(?!우)');
      expect(oldTerm.hasMatch('AI 워크플로 설계'), isTrue);
      expect(oldTerm.hasMatch('AI 워크플로우 설계'), isFalse);
      const banned = ['설명용', '실제 AI 실행 아님', '실제 AI를 호출하지', '미리 정한 시나리오', 'AI 워크플로 엔지니어', 'AI 워크플로우 엔지니어'];
      for (final entry in shippedText.entries) {
        // 용어는 주석까지 원문 전체를 본다(원본 규칙). 안내 문구 금지는 화면에 나올 수 있는 값만 본다(주석 줄 제외).
        expect(oldTerm.hasMatch(entry.value), isFalse, reason: '${entry.key} uses 워크플로');
        final renderable = entry.key.endsWith('.dart') ? entry.value.split('\n').where((line) => !line.trimLeft().startsWith('//')).join('\n') : entry.value;
        for (final phrase in banned) {
          expect(renderable.contains(phrase), isFalse, reason: '${entry.key} contains "$phrase"');
        }
      }
    });

    test('no emoji in shipped code or data', () {
      final emoji = RegExp('[\u{1F000}-\u{1FAFF}\u{2700}-\u{27BF}\u{2600}-\u{26FF}]', unicode: true);
      for (final entry in shippedText.entries) {
        expect(emoji.hasMatch(entry.value), isFalse, reason: entry.key);
      }
    });

    test('index.html is Korean, noindex, exact title and carries no SEO/OG metadata or manifest', () {
      final html = File('web/index.html').readAsStringSync();
      expect(html, contains('<html lang="ko">'));
      expect(html, contains('<meta name="robots" content="noindex, noarchive">'));
      expect(html, contains('<title>김형준 · 이력서</title>'));
      expect(html, isNot(matches(RegExp(r'og:|twitter:|name="description"|name="keywords"|rel="canonical"|ld\+json|manifest', caseSensitive: false))));
      final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();
      expect(bootstrap, contains("fontFallbackBaseUrl: '/fonts/'"));
      expect(File('web/manifest.json').existsSync(), isFalse);
    });

    test('portfolio PDF exists and matches the current source data', () {
      final pdf = File('web/portfolio.pdf');
      expect(pdf.existsSync(), isTrue);
      final bytes = pdf.readAsBytesSync();
      expect(latin1.decode(bytes.take(5).toList()), '%PDF-');
      final source = <int>[];
      for (final name in ['resume.json', 'site.json', 'workflowDetail.json', 'pixelStudio.json', 'subtitles.json', 'pixel-palette-sets.json']) {
        source
          ..addAll(utf8.encode(name))
          ..addAll(File('assets/data/$name').readAsBytesSync());
      }
      expect(latin1.decode(bytes).contains('${sha256.convert(source)}'), isTrue, reason: 'regenerate the PDF after source data changes');
      expect(File('web/robots.txt').readAsStringSync(), contains('Disallow: /portfolio.pdf'));
    });

    test('contact: user-supplied email/phone stay plain text, only the exact portfolio URL becomes a link', () {
      final resume = ResumeContent.fromJson(readData('resume'));
      final byId = {for (final field in resume.contactFields) field.id: field};
      expect(resume.contactValue(byId['email']!), 'contact@richpocket.net');
      expect(resume.contactValue(byId['phone']!), isNotNull, reason: 'user-approved phone is present');
      expect(resume.contactHref(byId['email']!), isNull);
      expect(resume.contactHref(byId['phone']!), isNull);
      expect(resume.contactValue(const ContactField(id: 'email', label: 'x', value: '')), isNull);
      expect(resume.contactValue(const ContactField(id: 'phone', label: 'x', value: '  ')), isNull);
      expect(resume.contactHref(byId['profile']!), 'https://github.com/MastProgs');
      expect(resume.contactHref(const ContactField(id: 'profile', label: 'x', value: 'https://github.com/other')), isNull);
      expect(resume.contactHref(const ContactField(id: 'email', label: 'x', value: 'https://github.com/MastProgs')), isNull);
      expect(resume.formatPeriod(resume.careerEntries.first), '2023.07 – 현재');
      expect(resume.careerEntries.map((entry) => entry.company), ['리치포켓', '알레프리서치코리아', '위메이드플러스', '조이시티', '한빛소프트', '모아이게임즈']);
    });

    test('all bundled media paths exist as original files (no placeholders)', () {
      final site = SiteContent.fromJson(readData('site'));
      final resume = ResumeContent.fromJson(readData('resume'));
      final paths = [resume.photoSrc, for (final item in site.cases) ?item.image?.src];
      expect(paths, hasLength(5));
      for (final path in paths) {
        expect(File(publicAsset(path)).existsSync(), isTrue, reason: path);
      }
      expect(site.cases.map((item) => item.id), ['case-agentworkflow', 'case-pixel', 'case-subtitles', 'case-keti', 'case-intake']);
      expect(site.navLinks.map((link) => link.label), ['소개', '학력·역량', '핵심 구현', '회사 경력', '작업 사례']);
      expect(site.coreItems.map((item) => item.id), ['workflow', 'sprite', 'subtitles']);
      expect(site.heroLines, ['불필요하게 반복하는 일을', '검증된 자동화 AI 워크플로우로']);
    });
  });

  group('model constants equal the original module exports (constants.json)', () {
    final constants = readData('constants');
    final detail = constants.obj('detail');
    final frames = constants.obj('frames');

    test('workflow detail', () {
      expect([
        for (final stage in laneStages) {'id': stage.id, 'label': stage.label},
      ], detail['LANE_STAGES']);
      expect(returnTarget, detail['RETURN_TARGET']);
      expect(seedChildren, detail['SEED_CHILDREN']);
      expect(seedParent, detail['SEED_PARENT']);
      expect(sessionForStage, detail['SESSION_FOR_STAGE']);
      expect(taskStages, detail['TASK_STAGES']);
      expect(verdictLabel, detail['VERDICT_LABEL']);
      expect([detail['DETAIL_TOTAL'], detail['DISPATCH_STEP'], detail['MERGE_STEP']], [33, 8, 24]);
      expect(detailStepMs, frames['DETAIL_STEP_MS']);
      expect(defaultSpeed, frames['DEFAULT_SPEED']);
      expect(speeds, frames['SPEEDS']);
      expect({
        'fault': FrameTier.fault,
        'master': FrameTier.master,
        'lane': FrameTier.lane,
        'integration': FrameTier.integration,
        'conversation': FrameTier.conversation,
      }, frames['FRAME_TIER']);
    });

    test('route selector and run status', () {
      final workflow = constants.obj('workflow');
      expect([
        for (final mode in routeModes) {'id': mode.id, 'label': mode.label, 'hint': mode.hint},
      ], workflow['MODES']);
      expect({for (final status in RunStatus.values) status.name.toUpperCase(): status.name}, workflow['RUN_STATUS']);
    });

    test('pixel timeline, outline and subtitles', () {
      expect(motionLoop, constants.obj('timeline')['MOTION_LOOP']);
      expect({'prev': onionTintPrev, 'next': onionTintNext}, constants.obj('timeline')['ONION_TINT']);
      expect(outlinePad, constants.obj('outline')['OUTLINE_PAD']);
      final subtitle = constants.obj('subtitle');
      expect(
        [levelStepMs, maxDisplayPadMs, pauseMarkMs, stageIntervalMs],
        [subtitle['LEVEL_STEP_MS'], subtitle['MAX_DISPLAY_PAD_MS'], subtitle['PAUSE_MARK_MS'], subtitle['STAGE_INTERVAL_MS']],
      );
      expect(proposalFields, subtitle['PROPOSAL_FIELDS']);
      expect(turnCycles, {'walk': 2, 'run': 2, 'attack': 1});
    });
  });

  group('pure helpers', () {
    // 레일 폭 1376, 카드 600, 간격 24, 좌우 여백 388(원본 rail.test.mjs 와 같은 수치).
    final items = [for (var i = 0; i < 4; i += 1) RailItem(left: 388 + i * 624.0, width: 600)];
    RailViewport viewport(double scrollLeft) => RailViewport(scrollLeft: scrollLeft, clientWidth: 1376, scrollWidth: 388 * 2 + 4 * 600 + 3 * 24);

    test('case rail: centred index, tilt, centring target and prev/next bounds', () {
      expect(centeredIndex(viewport(0), items), 0);
      expect(centeredIndex(viewport(624), items), 1);
      expect(centeredIndex(viewport(624 * 3), items), 3);
      expect(centeredIndex(viewport(300), items), 0);
      expect(centeredIndex(viewport(330), items), 1);
      expect(centeredIndex(viewport(0), const []), -1);
      expect(tiltRatio(items[0], viewport(0)), 0);
      expect(tiltRatio(items[1], viewport(0)), greaterThan(0));
      expect(tiltRatio(items[0], viewport(624)), lessThan(0));
      expect(tiltRatio(items[3], viewport(0)), 1);
      expect(tiltRatio(const RailItem(left: 388.0001, width: 600), viewport(0)).isNegative, isFalse, reason: 'no negative zero');
      expect(tiltRatio(items[0], const RailViewport(scrollLeft: 0, clientWidth: 0, scrollWidth: 0)), 0);
      expect(scrollLeftToCenter(items[0], viewport(0)), 0);
      expect(scrollLeftToCenter(items[2], viewport(0)), 1248);
      expect(scrollLeftToCenter(items[3], viewport(0)), 1872);
      expect(scrollLeftToCenter(const RailItem(left: 99999, width: 600), viewport(0)), viewport(0).scrollWidth - 1376);
      expect(scrollLeftToCenter(const RailItem(left: -500, width: 100), viewport(0)), 0);
      expect([stepIndex(0, -1, 4), stepIndex(0, 1, 4), stepIndex(3, 1, 4), stepIndex(3, -1, 4)], [null, 1, null, 2]);
    });

    test('roving radio keys', () {
      expect(nextRovingIndex(LogicalKeyboardKey.arrowRight, 6, 7), 0);
      expect(nextRovingIndex(LogicalKeyboardKey.arrowLeft, 0, 7), 6);
      expect(nextRovingIndex(LogicalKeyboardKey.home, 4, 7), 0);
      expect(nextRovingIndex(LogicalKeyboardKey.end, 1, 7), 6);
      expect(nextRovingIndex(LogicalKeyboardKey.arrowDown, 1, 7), isNull);
      expect(nextRovingIndex(LogicalKeyboardKey.enter, 1, 7), isNull);
      expect(nextRovingIndex(LogicalKeyboardKey.arrowDown, 2, 3, both: true), 0);
      expect(nextRovingIndex(LogicalKeyboardKey.arrowUp, 0, 3, both: true), 2);
      expect(nextRovingIndex(LogicalKeyboardKey.arrowRight, 0, 0), isNull);
    });

    test('theme helpers: dark default, only dark|light, one storage key, blocked storage → dark', () {
      expect([normalizeTheme(null), normalizeTheme('light'), normalizeTheme('LIGHT'), normalizeTheme('neon')], ['dark', 'light', 'dark', 'dark']);
      expect([toggledTheme('dark'), toggledTheme('light'), toggledTheme('x')], ['light', 'dark', 'light']);
      final blocked = MemoryHostPlatform(storedTheme: 'light', storageThrows: true);
      final controller = ThemeController(blocked);
      expect(controller.theme, 'dark');
      controller.toggle();
      expect(controller.theme, 'light', reason: 'still toggles in memory when storage is unavailable');
      expect(blocked.storedTheme, 'light', reason: 'nothing was written (storage throws)');
      controller.dispose();
      final memory = MemoryHostPlatform();
      final second = ThemeController(memory)
        ..setTheme('light')
        ..setTheme('purple');
      expect([second.theme, memory.storedTheme], ['dark', 'dark']);
      second.dispose();
    });

    test('keep-all joins Korean word characters only and leaves spaces as break points', () {
      expect(keepAll('김형준'), '김⁠형⁠준');
      expect(keepAll('QA에서 개발'), 'QA⁠에⁠서 개⁠발');
      expect(keepAll('AgentWorkflow'), 'AgentWorkflow');
      expect(keepAll('a b'), 'a b');
      expect(keepAll(''), '');
    });
  });

  test('resume.json is valid JSON in the asset bundle (lazy loading reads the same file)', () {
    expect(asJson(readJsonFile('assets/data/resume.json'))['PORTFOLIO_URL'], 'https://github.com/MastProgs');
  });
}
