// 범위 입력(슬라이더) 접근성 회귀: 이름 붙은 패널(팔레트·어니언·타임라인) 안에서도 슬라이더가 자기 노드로 남아
// 자기 이름·값·44px 높이를 갖고, 프레임·불투명도가 바뀌면 값(aria-valuetext)도 바로 바뀐다.
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/finders.dart';
import 'widget_test.dart' show pumpApp, pumpUntilFound;

List<SemanticsNode> _sliders(WidgetTester tester) {
  final out = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    if (node.getSemanticsData().flagsCollection.isSlider) out.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!);
  return out;
}

void main() {
  testWidgets('sprite sliders are separately named leaves with 44px bounds and live values', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, '/sprite', size: const Size(1440, 5000));
    await pumpUntilFound(tester, findText('Hero Pixel Studio 라이브 미리보기'));

    SemanticsNode byLabel(String part) => _sliders(tester).singleWhere((node) => node.getSemanticsData().label.contains(part));
    final sliders = _sliders(tester);
    expect(sliders.length, greaterThanOrEqualTo(3), reason: 'frame, onion opacity, palette ratio');
    for (final node in sliders) {
      final data = node.getSemanticsData();
      expect(data.label.trim(), isNotEmpty, reason: 'slider has its own name');
      expect(data.label.contains('\n'), isFalse, reason: 'not merged with the panel text: "${data.label}"');
      expect(data.value.trim(), isNotEmpty);
      expect(node.childrenCount, 0, reason: 'leaf control');
      expect(node.rect.height, inInclusiveRange(44, 60), reason: '44px control, not the whole panel (${node.rect})');
    }

    // 프레임: 증가 동작 → 값(캡션)이 같이 바뀐다.
    final frame = sliders.firstWhere((node) => node.getSemanticsData().value.contains('ms'));
    final before = frame.getSemanticsData().value;
    tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(frame.id, SemanticsAction.increase);
    await tester.pump();
    final frameAfter = _sliders(tester).firstWhere((node) => node.getSemanticsData().value.contains('ms')).getSemanticsData().value;
    expect(frameAfter, isNot(before));
    expect(findTextContaining(RegExp(r'\d+/\d+')), findsWidgets);

    // 어니언 불투명도: 35% → 증가 후 다른 값.
    final onion = sliders.firstWhere((node) => node.getSemanticsData().value.endsWith('%') && node.getSemanticsData().value == '35%');
    final onionLabel = onion.getSemanticsData().label;
    tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(onion.id, SemanticsAction.increase);
    await tester.pump();
    expect(byLabel(onionLabel).getSemanticsData().value, isNot('35%'));
    handle.dispose();
  });

  testWidgets('pause → 걷기 → frame 6: slider value and neighbours use the same text; ends report no further step', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, '/sprite', size: const Size(1440, 5000));
    await pumpUntilFound(tester, findText('Hero Pixel Studio 라이브 미리보기'));
    final owner = tester.binding.renderViews.first.owner!.semanticsOwner!;
    SemanticsData slider(String label) => _sliders(tester).singleWhere((node) => node.getSemanticsData().label == label).getSemanticsData();

    // 원래 순서: 일시정지 → 걷기 선택 → 프레임 머리칸 '걷기 6'.
    await tester.tap(find.bySemanticsLabel('일시정지').first);
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('걷기').first);
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('걷기 6').first);
    await tester.pump();
    expect(findTextContaining('6/8 · 110ms · walk-05'), findsOneWidget, reason: 'visible caption');
    var frame = slider('프레임 위치');
    expect(frame.value, '걷기 6/8 · 110ms');
    expect(frame.increasedValue, '걷기 7/8 · 120ms');
    expect(frame.decreasedValue, '걷기 5/8 · 130ms');
    // 증가 동작 뒤에도 값이 지금 캡션과 같다.
    owner.performAction(_sliders(tester).singleWhere((node) => node.getSemanticsData().label == '프레임 위치').id, SemanticsAction.increase);
    await tester.pump();
    frame = slider('프레임 위치');
    expect(frame.value, '걷기 7/8 · 120ms');
    expect(findTextContaining('7/8 · 120ms · walk-06'), findsOneWidget);

    var onion = slider('어니언 불투명도');
    expect([onion.value, onion.increasedValue, onion.decreasedValue], ['35%', '40%', '30%']);
    var ratio = slider('팔레트 적용 비율');
    expect([ratio.value, ratio.increasedValue, ratio.decreasedValue], ['AAP-64 100%', '', 'AAP-64 99%'], reason: 'at max nothing further');
    // 어니언을 끝(100%)까지: 더 올릴 값이 없다.
    final onionNode = _sliders(tester).singleWhere((node) => node.getSemanticsData().label == '어니언 불투명도');
    for (var i = 0; i < 20; i += 1) {
      owner.performAction(onionNode.id, SemanticsAction.increase);
      await tester.pump();
    }
    onion = slider('어니언 불투명도');
    expect([onion.value, onion.increasedValue, onion.decreasedValue], ['100%', '', '95%']);
    ratio = slider('팔레트 적용 비율');
    expect(ratio.value, 'AAP-64 100%');
    handle.dispose();
  });
}
