// 접근성(Semantics) 충실도 회귀: 실제 접근성 트리를 돌며 원본 React 마크업의 의미와 맞는지 본다.
// 링크 목적지(href=linkUrl)와 한 번만 실행, 제목 단계(h1/h2/h3), 사례 대화상자 역할(dialog), 실행 경로 radiogroup/radio,
// 조작 이름의 중복·중첩 없음(보조 설명이 떠 있을 때 포함), 읽기 전용 글의 이름·값.
import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastprogs_v3/app/route_links.dart';
import 'package:mastprogs_v3/core/constants.dart';

import 'support/finders.dart';
import 'widget_test.dart' show documentTitle, pumpApp, pumpUntilFound, tapVisible;

const _tall = Size(1440, 16000);
const portfolioUrl = 'https://github.com/MastProgs';

SemanticsOwner _owner(WidgetTester tester) => tester.binding.renderViews.first.owner!.semanticsOwner!;

/// 트리 전체(부모 → 자식 순서). 각 노드와 조상 노드 목록.
List<(SemanticsNode, List<SemanticsNode>)> _walk(WidgetTester tester) {
  final out = <(SemanticsNode, List<SemanticsNode>)>[];
  void visit(SemanticsNode node, List<SemanticsNode> ancestors) {
    out.add((node, ancestors));
    final next = [...ancestors, node];
    node.visitChildren((child) {
      visit(child, next);
      return true;
    });
  }

  visit(_owner(tester).rootSemanticsNode!, const []);
  return out;
}

List<SemanticsNode> _nodes(WidgetTester tester, bool Function(SemanticsData data) test) => [
  for (final (node, _) in _walk(tester))
    if (test(node.getSemanticsData())) node,
];

bool _interactive(SemanticsData d) => d.hasAction(SemanticsAction.tap) || d.flagsCollection.isButton || d.flagsCollection.isLink;

void _activate(WidgetTester tester, SemanticsNode node) => _owner(tester).performAction(node.id, SemanticsAction.tap);

/// 조작 노드: 이름이 있고, 'X X' 처럼 겹치지 않고, 다른 조작 노드 안에 들어 있지 않다.
void _expectCleanControls(WidgetTester tester, String where, {int atLeast = 4}) {
  var count = 0;
  for (final (node, ancestors) in _walk(tester)) {
    final data = node.getSemanticsData();
    if (!_interactive(data)) continue;
    count += 1;
    final label = data.label.trim();
    expect(
      label,
      isNotEmpty,
      reason: '$where: nameless control ${node.toStringDeep()} under ${ancestors.map((a) => a.getSemanticsData().label).where((l) => l.isNotEmpty).toList()}',
    );
    expect(RegExp(r'^(.+) \1$').hasMatch(label), isFalse, reason: '$where: duplicated name "$label"');
    final nestedIn = ancestors.where((a) => _interactive(a.getSemanticsData())).map((a) => a.getSemanticsData().label).toList();
    expect(nestedIn, isEmpty, reason: '$where: control "$label" nested inside $nestedIn');
  }
  expect(count, greaterThanOrEqualTo(atLeast), reason: '$where: controls were found');
}

void main() {
  group('links expose real destinations and activate once', () {
    testWidgets('main page: portfolio, anchors and detail CTAs carry href; every link has one', (tester) async {
      final handle = tester.ensureSemantics();
      final host = await pumpApp(tester, '/?state=target', size: _tall);
      final links = _nodes(tester, (d) => d.flagsCollection.isLink);
      expect(links, isNotEmpty);
      final urls = <String>{};
      for (final link in links) {
        final data = link.getSemanticsData();
        expect(data.linkUrl, isNotNull, reason: 'link "${data.label}" has no href');
        final url = data.linkUrl.toString();
        expect(url.startsWith('#') || url.startsWith('/') || url == portfolioUrl, isTrue, reason: 'unexpected href $url');
        urls.add(url);
      }
      expect(
        urls,
        containsAll(<String>[
          portfolioUrl,
          anchorLink('workflow').toString(),
          anchorLink('sprite').toString(),
          anchorLink('subtitles').toString(),
          routeLink(workflowRoutePath).toString(),
          routeLink(spriteRoutePath).toString(),
          routeLink(subtitlesRoutePath).toString(),
        ]),
      );
      expect(urls.where((url) => url.startsWith('http')), [portfolioUrl], reason: 'the only external href');

      // 포트폴리오만 새 탭, 내부 상세 링크는 같은 탭의 라우터에서 한 번 실행한다.
      final portfolio = links.firstWhere((node) => node.getSemanticsData().linkUrl.toString() == portfolioUrl);
      _activate(tester, portfolio);
      await tester.pump();
      expect(host.openedTabs, [portfolioUrl]);
      final workflowCta = links.firstWhere((node) => node.getSemanticsData().linkUrl.toString() == routeLink(workflowRoutePath).toString());
      _activate(tester, workflowCta);
      await tester.pump();
      expect(host.openedTabs, [portfolioUrl]);
      expect(documentTitle(tester), workflowDocumentTitle);
      handle.dispose();
    });

    testWidgets('detail back link points to / and navigates once', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, '/workflow');
      final back = _nodes(tester, (d) => d.flagsCollection.isLink && d.linkUrl == Uri.parse('/'));
      expect(back, hasLength(1));
      _activate(tester, back.single);
      for (var i = 0; i < 10; i += 1) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(documentTitle(tester), mainDocumentTitle);
      handle.dispose();
    });
  });

  group('heading levels follow the React h1/h2/h3 outline', () {
    Map<int, List<String>> levels(WidgetTester tester) {
      final out = <int, List<String>>{};
      for (final node in _nodes(tester, (d) => d.flagsCollection.isHeader || d.headingLevel > 0)) {
        final data = node.getSemanticsData();
        expect(data.headingLevel, inInclusiveRange(1, 3), reason: 'heading "${data.label}" has explicit level');
        out.putIfAbsent(data.headingLevel, () => []).add(data.label);
      }
      return out;
    }

    testWidgets('main: name is the only h1, sections h2, blocks/items h3', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, '/?state=target', size: _tall);
      final map = levels(tester);
      expect(map[1], ['김형준']);
      expect(map[2], containsAll(<Matcher>[startsWith('02 '), startsWith('03 '), startsWith('04 '), startsWith('05 ')]));
      expect(map[2]!.any((label) => label.startsWith('01 ')), isFalse, reason: '01 소개 is a paragraph in React');
      expect(map[3], contains('연락처'));
      expect(map[3]!.length, greaterThanOrEqualTo(6), reason: 'block titles, core items, companies');
      handle.dispose();
    });

    testWidgets('/workflow: one h1, block h2, lane h3', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, '/workflow', size: const Size(1440, 6000));
      final map = levels(tester);
      expect(map[1], hasLength(1));
      expect(map[2], isNotEmpty);
      expect(map[3]!.where((label) => label.startsWith('레인 ')), hasLength(3));
      handle.dispose();
    });

    testWidgets('/subtitles: one h1, section h2, stage/boundary h3', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, '/subtitles', size: const Size(1440, 6000));
      final map = levels(tester);
      expect(map[1], hasLength(1));
      expect(map[2], containsAll(<String>['처리 흐름', '과정 따라가기']));
      expect(map[3], isNotEmpty);
      handle.dispose();
    });

    testWidgets('/sprite: one h1, studio h2', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, '/sprite', size: const Size(1440, 6000));
      await pumpUntilFound(tester, findText('Hero Pixel Studio 라이브 미리보기'));
      final map = levels(tester);
      expect(map[1], hasLength(1));
      expect(map[2], contains('Hero Pixel Studio 라이브 미리보기'));
      handle.dispose();
    });
  });

  testWidgets('case dialog is a named dialog with an h2 title and a single close button', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, '/#cases');
    await tapVisible(tester, find.bySemanticsLabel(RegExp(r'^03 Voice to SRT\. ')));
    await tester.pumpAndSettle();
    final dialogs = _nodes(tester, (d) => d.role == SemanticsRole.dialog);
    expect(dialogs, hasLength(1));
    final dialog = dialogs.single.getSemanticsData();
    expect(dialog.label, 'Voice to SRT');
    expect(dialog.flagsCollection.scopesRoute && dialog.flagsCollection.namesRoute, isTrue);

    final inside = <SemanticsData>[];
    void collect(SemanticsNode node) => node.visitChildren((child) {
      inside.add(child.getSemanticsData());
      collect(child);
      return true;
    });
    collect(dialogs.single);
    expect(inside.where((d) => d.headingLevel == 2).map((d) => d.label), ['Voice to SRT']);
    final closers = _nodes(tester, (d) => d.label == '사례 닫기');
    expect(closers, hasLength(1), reason: 'no barrier button wrapping the dialog');
    expect(closers.single.getSemanticsData().flagsCollection.isButton, isTrue);
    expect(closers.single.childrenCount, 0, reason: 'no nested nameless tap node');
    // 모달 뒤 페이지는 가려지므로 대화상자 안의 조작(닫기·상세 링크)만 남는다.
    _expectCleanControls(tester, 'case dialog', atLeast: 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_nodes(tester, (d) => d.role == SemanticsRole.dialog), isEmpty);
    handle.dispose();
  });

  testWidgets('route mode switch is a radiogroup of mutually exclusive radios with keyboard roving', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, '/workflow');
    final groups = _nodes(tester, (d) => d.role == SemanticsRole.radioGroup);
    expect(groups, hasLength(1));
    expect(groups.single.getSemanticsData().label, '실행 경로');

    List<SemanticsData> radios() => [for (final node in _nodes(tester, (d) => d.flagsCollection.isInMutuallyExclusiveGroup)) node.getSemanticsData()];
    expect(radios(), hasLength(3));
    for (final radio in radios()) {
      expect(radio.flagsCollection.isToggled, Tristate.none, reason: 'not a switch');
      expect(radio.flagsCollection.isButton, isFalse);
    }
    final checked = radios().where((d) => d.flagsCollection.isChecked == CheckedState.isTrue).toList();
    expect(checked, hasLength(1));

    // 보조 기술의 포커스 → 방향키로 다음 경로가 선택된다(로빙 유지).
    final checkedNode = _nodes(tester, (d) => d.flagsCollection.isInMutuallyExclusiveGroup && d.flagsCollection.isChecked == CheckedState.isTrue).single;
    _owner(tester).performAction(checkedNode.id, SemanticsAction.focus);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    final after = radios().where((d) => d.flagsCollection.isChecked == CheckedState.isTrue).toList();
    expect(after, hasLength(1));
    expect(after.single.label, isNot(checked.single.label));
    handle.dispose();
  });

  group('control names are unique and not nested', () {
    testWidgets('workflow transport: visible tooltip does not repeat the button name', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, '/workflow');
      final next = find.bySemanticsLabel('다음 프레임');
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(next.first));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 300));
      expect(findText('다음 프레임'), findsOneWidget, reason: 'the hover tooltip is visible');
      final named = _nodes(tester, (d) => d.label.contains('다음 프레임'));
      expect(named, hasLength(1));
      expect(named.single.getSemanticsData().label, '다음 프레임');
      _expectCleanControls(tester, '/workflow (tooltip shown)');
      handle.dispose();
    });

    for (final path in ['/?state=target', '/subtitles', '/sprite']) {
      testWidgets('$path controls', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpApp(tester, path, size: path.startsWith('/?') ? _tall : const Size(1440, 6000));
        if (path == '/sprite') await pumpUntilFound(tester, findText('Hero Pixel Studio 라이브 미리보기'));
        _expectCleanControls(tester, path);
        handle.dispose();
      });
    }
  });

  testWidgets('speed selector: one node named "재생 속도" with the current speed as its value, opening the menu', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, '/workflow');
    final named = _nodes(tester, (d) => d.label.contains('재생 속도') || d.value.contains('재생 속도'));
    expect(named, hasLength(1));
    final data = named.single.getSemanticsData();
    expect(data.label, '재생 속도');
    expect(data.value, '1배');
    expect(data.flagsCollection.isButton, isTrue);
    expect(named.single.childrenCount, 0, reason: 'no nested tooltip/text duplicates');
    expect(_nodes(tester, (d) => d.label == '1배'), isEmpty, reason: 'value is read once, as the value');
    _activate(tester, named.single);
    await tester.pumpAndSettle();
    expect(findText('0.5배'), findsOneWidget, reason: 'menu opened through the single node');
    expect(findText('2배'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('single-lane board: lane heading stays an h3 of its own and the body stays a separate group', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, '/workflow', size: const Size(1440, 6000));
    final sequential = _nodes(tester, (d) => d.flagsCollection.isInMutuallyExclusiveGroup && d.label == '순차');
    _activate(tester, sequential.single);
    await tester.pump();
    for (var i = 0; i < 12; i += 1) {
      await tapVisible(tester, find.bySemanticsLabel('다음 프레임'));
    }
    final laneHeadings = [
      for (final (node, ancestors) in _walk(tester))
        if (node.getSemanticsData().headingLevel == 3 && node.getSemanticsData().label.startsWith('레인 ')) (node, ancestors),
    ];
    expect(laneHeadings, hasLength(1), reason: 'sequential route has one lane');
    final (heading, ancestors) = laneHeadings.single;
    final data = heading.getSemanticsData();
    expect(data.label, matches(RegExp(r'^레인 \S+, [^\n]+$')), reason: 'heading is only the lane title, not the pipeline body');
    expect(heading.childrenCount, 0);
    final group = ancestors.last;
    final groupData = group.getSemanticsData();
    expect(groupData.flagsCollection.isHeader, isFalse);
    expect(groupData.headingLevel, 0, reason: 'the lane body is a group, not a heading');
    final siblings = <String>[];
    group.visitChildren((child) {
      siblings.add(child.getSemanticsData().label);
      return true;
    });
    expect(siblings.length, greaterThan(1), reason: 'heading and body are separate child nodes');
    expect(siblings.any((label) => label.endsWith(' 단계')), isTrue, reason: 'stage list group remains');
    handle.dispose();
  });

  group('read-only text is readable (not an empty disabled text field)', () {
    testWidgets('SRT result exposes its label and cue text', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, '/subtitles', size: const Size(1440, 6000));
      for (var i = 0; i < 5; i += 1) {
        await tapVisible(tester, find.bySemanticsLabel('다음 단계'));
      }
      expect(findText('06 / 06'), findsOneWidget);
      final srt = _nodes(tester, (d) => d.label == 'SRT 결과');
      expect(srt, hasLength(1));
      expect(srt.single.getSemanticsData().value, allOf(contains('-->'), startsWith('1\n')));
      expect(_nodes(tester, (d) => d.flagsCollection.isTextField), isEmpty);
      handle.dispose();
    });

    testWidgets('workflow record viewer exposes path label and file content, focusable but not a button', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, '/workflow', size: const Size(1440, 6000));
      for (var i = 0; i < 6; i += 1) {
        await tapVisible(tester, find.bySemanticsLabel('다음 프레임'));
      }
      final viewers = _nodes(tester, (d) => d.label.endsWith(' 내용') && d.value.isNotEmpty);
      expect(viewers, hasLength(1));
      final data = viewers.single.getSemanticsData();
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.flagsCollection.isFocused, isNot(Tristate.none), reason: 'keyboard focusable like <pre tabIndex=0>');
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(_nodes(tester, (d) => d.flagsCollection.isTextField), isEmpty);
      handle.dispose();
    });
  });
}
