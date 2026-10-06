// 메인 이력서 안의 앵커·스크롤 공용 상태(섹션 위치 키, 앵커 이동, 등장 효과 여부).
// AI-NOTE: 앵커 링크는 해시 경로 안의 ?anchor 값을 바꾸고(브라우저 기록), 페이지가 그 섹션으로 스크롤한다.
// 고정 바(56/52px)에 제목이 가리지 않게 [id] scroll-margin-top 과 같은 여백을 둔다. 사례 카드 앵커(#case-…)는
// 사례 레일까지 내려간 뒤 레일 안에서 그 카드를 가운데로 옮긴다(페이지 가로 스크롤은 건드리지 않음).
import 'package:flutter/widgets.dart';

class PortfolioScope extends InheritedWidget {
  const PortfolioScope({super.key, required this.anchors, required this.onAnchor, required this.revealEnabled, required super.child});

  final AnchorRegistry anchors;
  final ValueChanged<String> onAnchor;
  final bool revealEnabled;

  static PortfolioScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<PortfolioScope>()!;

  static PortfolioScope read(BuildContext context) => context.getInheritedWidgetOfExactType<PortfolioScope>()!;

  @override
  bool updateShouldNotify(PortfolioScope oldWidget) => revealEnabled != oldWidget.revealEnabled || anchors != oldWidget.anchors;
}

class AnchorRegistry {
  final Map<String, GlobalKey> _keys = {};

  /// 사례 레일이 등록하는 카드 이동 함수(사례 id → 레일 안에서 가운데로).
  void Function(String caseId)? revealCase;

  GlobalKey keyFor(String id) => _keys.putIfAbsent(id, () => GlobalKey(debugLabel: 'anchor-$id'));

  BuildContext? contextOf(String id) => _keys[id]?.currentContext;
}
