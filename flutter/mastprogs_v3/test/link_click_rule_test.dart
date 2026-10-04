// 접근성 링크 클릭 규칙: 보통 클릭은 기본 이동만 막고(앱이 한 번 처리), 수정 키·보조 버튼은 브라우저 기본 동작을 두고
// 엔진(Flutter tap)으로 전달하지 않는다. 링크 밖 클릭은 건드리지 않는다.
import 'package:flutter_test/flutter_test.dart';
import 'package:mastprogs_v3/platform/link_click_rule.dart';

LinkClickAction rule({bool link = true, int button = 0, bool ctrl = false, bool meta = false, bool shift = false, bool alt = false}) =>
    semanticLinkClickAction(onSemanticLink: link, button: button, ctrl: ctrl, meta: meta, shift: shift, alt: alt);

void main() {
  test('plain primary click on a semantic link: preventDefault only (Flutter tap still forwarded once)', () {
    expect(rule(), LinkClickAction.preventDefault);
  });

  test('modified clicks keep native new tab/window and are not forwarded to Flutter', () {
    expect(rule(ctrl: true), LinkClickAction.stopPropagation);
    expect(rule(meta: true), LinkClickAction.stopPropagation);
    expect(rule(shift: true), LinkClickAction.stopPropagation);
    expect(rule(alt: true), LinkClickAction.stopPropagation);
    expect(rule(ctrl: true, shift: true), LinkClickAction.stopPropagation);
  });

  test('middle/right buttons keep native behaviour and are not forwarded to Flutter', () {
    expect(rule(button: 1), LinkClickAction.stopPropagation);
    expect(rule(button: 2), LinkClickAction.stopPropagation);
  });

  test('anything outside semantic anchors is untouched, modifiers or not', () {
    expect(rule(link: false), LinkClickAction.ignore);
    expect(rule(link: false, ctrl: true), LinkClickAction.ignore);
    expect(rule(link: false, button: 1), LinkClickAction.ignore);
  });
}
