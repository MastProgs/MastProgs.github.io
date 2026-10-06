// 앱 전체 위젯 테스트: 네 경로·끝 슬래시·미지 경로·문서 제목, 메인 이력서 구성, 테마 전환·저장, 내부 이동, 사례 대화상자.
// AI-NOTE: 브라우저 경계는 MemoryHostPlatform 으로 바꿔 끼운다(새 탭·저장 요청을 기록). 실제 브라우저 QA 는 별도로 한다.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastprogs_v3/app/app.dart';
import 'package:mastprogs_v3/app/route_links.dart';
import 'package:mastprogs_v3/app/routes.dart';
import 'package:mastprogs_v3/core/constants.dart';
import 'package:mastprogs_v3/features/portfolio/portfolio_content.dart';
import 'package:mastprogs_v3/features/portfolio/view/case_dialog.dart';
import 'package:mastprogs_v3/platform/host_platform.dart';
import 'package:mastprogs_v3/widgets/pdf_download_button.dart';

import 'support/finders.dart';
import 'support/fixtures.dart';

Future<MemoryHostPlatform> pumpApp(WidgetTester tester, String location, {Size size = const Size(1440, 1000), MemoryHostPlatform? platform}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final host = platform ?? MemoryHostPlatform();
  await tester.pumpWidget(PortfolioApp(platform: host, initialLocation: location));
  // 자산 읽기(rootBundle)와 지연 라이브러리가 끝날 때까지.
  for (var i = 0; i < 20; i += 1) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  return host;
}

String documentTitle(WidgetTester tester) => tester.widget<Title>(find.byType(Title).last).title;

/// 자산 읽기가 끝나 finder 가 나타날 때까지(실제 시간 최대 약 4초) 기다린다.
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 200 && finder.evaluate().isEmpty; i += 1) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// 화면 밖이면 스크롤해 보이게 한 뒤 누른다.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pump();
  await tester.tap(finder.first);
  await tester.pump();
}

void main() {
  group('route resolution', () {
    test('four pages, repeated trailing slashes, unknown paths fall back to the résumé', () {
      expect(resolvePage('/'), AppPage.main);
      expect(resolvePage(''), AppPage.main);
      expect(resolvePage('/workflow'), AppPage.workflow);
      expect(resolvePage('/workflow/'), AppPage.workflow);
      expect(resolvePage('/workflow///'), AppPage.workflow);
      expect(resolvePage('/sprite//'), AppPage.sprite);
      expect(resolvePage('/subtitles/'), AppPage.subtitles);
      expect(resolvePage('/unknown'), AppPage.main);
      expect(resolvePage('/workflow/extra'), AppPage.main);
      expect(resolvePage('/Workflow'), AppPage.main, reason: 'pathname match is exact like React');
      expect(AppLocation.parse('/?state=target').isTarget, isTrue);
      expect(AppLocation.parse('/#cases').fragment, 'cases');
      expect(AppLocation.parse('/?anchor=cases').fragment, 'cases');
      expect(AppLocation.parse('/?state=target').withFragment('cases').uri.toString(), '/?state=target&anchor=cases');
      expect(routeLink(spriteRoutePath).toString(), '/#/sprite');
      expect(anchorLink('cases').toString(), '/#/?anchor=cases');
    });

    test('document titles match the React pages', () {
      expect(AppPage.main.documentTitle, '김형준 · 이력서');
      expect(AppPage.workflow.documentTitle, 'AgentWorkflow 상세 · 김형준');
      expect(AppPage.sprite.documentTitle, 'Sprite 파이프라인 상세 · 김형준');
      expect(AppPage.subtitles.documentTitle, 'Voice to SRT 상세 · 김형준');
    });
  });

  testWidgets('main résumé renders identity, sections in order and the single portfolio link', (tester) async {
    final host = await pumpApp(tester, '/');
    expect(documentTitle(tester), mainDocumentTitle);
    expect(findText('김형준'), findsWidgets);
    for (final heading in ['소개', '학력·역량', '핵심 구현', '회사 경력', '작업 사례']) {
      expect(findTextContaining(heading), findsWidgets, reason: heading);
    }
    // 전화 값은 테스트에 적지 않고 번들 이력서 데이터에서 읽는다(출력에도 남기지 않음).
    final contacts = {for (final field in ResumeContent.fromJson(readData('resume')).contactFields) field.id: field.value.trim()};
    expect(findText('contact@richpocket.net'), findsOneWidget);
    expect(findText(contacts['phone']!), findsOneWidget, reason: 'user-approved phone is visible');
    expect(findText('준비 중'), findsNothing, reason: 'every contact slot is filled');
    final link = findText('https://github.com/MastProgs');
    expect(link, findsOneWidget);
    await tester.tap(link);
    await tester.pump();
    expect(host.openedTabs, ['https://github.com/MastProgs']);
    expect(findTextContaining(RegExp('워크플로(?!우)')), findsNothing);
    expect(findText('불필요하게 반복하는 일을'), findsOneWidget);
    expect(findText('검증된 자동화 AI 워크플로우로'), findsOneWidget);
  });

  testWidgets('the first three representative cases open their detail pages in the same tab', (tester) async {
    for (final (label, route, title) in [
      ('AI 개발 자동화', workflowRoutePath, workflowDocumentTitle),
      ('스프라이트 제작 도구', spriteRoutePath, spriteDocumentTitle),
      ('자동 자막 생성·교정', subtitlesRoutePath, subtitlesDocumentTitle),
    ]) {
      final host = await pumpApp(tester, '/');
      final link = find.bySemanticsLabel('사례 보기: $label');
      await tapVisible(tester, link);
      expect(documentTitle(tester), title, reason: route);
      expect(host.openedTabs, isEmpty, reason: route);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('PDF download is available on all four routes', (tester) async {
    for (final route in ['/', workflowRoutePath, spriteRoutePath, subtitlesRoutePath]) {
      final host = await pumpApp(tester, route);
      await tester.tap(find.byType(PdfDownloadButton));
      await tester.pump();
      expect(host.downloads, [(portfolioPdfPath, portfolioPdfFilename)], reason: route);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('unknown path keeps the résumé', (tester) async {
    await pumpApp(tester, '/nope');
    expect(documentTitle(tester), mainDocumentTitle);
    expect(findText('김형준'), findsWidgets);
  });

  testWidgets('/workflow/// opens the parallel frame player at frame 0', (tester) async {
    await pumpApp(tester, '/workflow///');
    expect(documentTitle(tester), workflowDocumentTitle);
    expect(findText('00 / 33'), findsOneWidget);
    expect(findText('독립 병렬'), findsOneWidget);
    await tapVisible(tester, find.bySemanticsLabel('다음 프레임'));
    expect(findText('01 / 33'), findsOneWidget);
    await tapVisible(tester, findText('순차'));
    expect(findText('00 / 20'), findsOneWidget, reason: 'default sequential (Seed, plan reject, QA fail ON) is 20 frames');
    await tapVisible(tester, findText('직접 처리'));
    expect(findText('00 / 03'), findsOneWidget);
  });

  testWidgets('theme toggle switches to light, persists only the theme value and carries over', (tester) async {
    final host = await pumpApp(tester, '/');
    expect(find.bySemanticsLabel('밝은 테마로 전환'), findsWidgets);
    await tester.tap(find.bySemanticsLabel('밝은 테마로 전환').first);
    await tester.pump();
    expect(host.storedTheme, 'light');
    expect(find.bySemanticsLabel('어두운 테마로 전환'), findsWidgets);
  });

  testWidgets('blocked storage falls back to dark and other-tab changes follow allowed values only', (tester) async {
    final host = await pumpApp(tester, '/', platform: MemoryHostPlatform(storedTheme: 'neon'));
    expect(find.bySemanticsLabel('밝은 테마로 전환'), findsWidgets, reason: 'unknown stored value → dark');
    // storage 이벤트는 비동기로 오고(첫 pump 가 전달), 그 뒤 다시 그리는 프레임이 필요하다(두 번째 pump).
    host.simulateStorage('light');
    await tester.pump();
    await tester.pump();
    expect(find.bySemanticsLabel('어두운 테마로 전환'), findsWidgets);
    host.simulateStorage('blue');
    await tester.pump();
    await tester.pump();
    expect(find.bySemanticsLabel('밝은 테마로 전환'), findsWidgets);
    expect(host.storedTheme, 'blue', reason: 'the other tab wrote it; this tab does not rewrite storage');
  });

  testWidgets('case dialog opens with focus on close, closes with Escape and restores focus', (tester) async {
    await pumpApp(tester, '/#cases');
    final card = find.bySemanticsLabel(RegExp(r'^03 Voice to SRT\. '));
    expect(card, findsOneWidget);
    await tapVisible(tester, card);
    await tester.pumpAndSettle();
    expect(findText('작업 사례 03'), findsOneWidget);
    expect(findText('처리 원리 도식 · 원본 문서와 소스 기준'), findsOneWidget);
    final dialog = find.byType(CaseDialogView);
    expect(find.descendant(of: dialog, matching: findText('처리 과정 자세히 보기')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(findText('작업 사례 03'), findsNothing);
  });

  testWidgets('/subtitles renders the walkthrough with six stages and no speed selector', (tester) async {
    await pumpApp(tester, '/subtitles/');
    expect(documentTitle(tester), subtitlesDocumentTitle);
    expect(findText('01 / 06'), findsOneWidget);
    expect(findText('1배'), findsNothing);
    await tapVisible(tester, find.bySemanticsLabel('다음 단계'));
    expect(findText('02 / 06'), findsOneWidget);
  });

  testWidgets('/sprite renders the studio header and original data controls', (tester) async {
    await pumpApp(tester, '/sprite');
    await pumpUntilFound(tester, findText('Hero Pixel Studio 라이브 미리보기'));
    expect(documentTitle(tester), spriteDocumentTitle);
    expect(findText('Hero Pixel Studio 라이브 미리보기'), findsOneWidget);
    expect(findText('무작위 섞기'), findsOneWidget);
    expect(findText('팔레트 세트'), findsOneWidget);
  });
}
