// 크기·간격·반응형 기준(React src/styles/base.css 의 :root 토큰과 각 CSS 의 @media 기준).
// AI-NOTE: CSS 미디어 쿼리 너비를 같은 숫자로 쓴다(뷰포트 너비 기준). 바꾸면 모든 화면이 함께 바뀐다.
import 'package:flutter/widgets.dart';

abstract final class Breakpoints {
  static const double wide = 1340;
  static const double desktop = 1100;
  static const double tablet = 960;
  static const double narrow = 860;
  static const double mobile = 760;
  static const double phone = 600;
  static const double compact = 520;
}

abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration med = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 640);

  /// cubic-bezier(0.2, 0.8, 0.2, 1).
  static const Curve easeOut = Cubic(0.2, 0.8, 0.2, 1);
}

/// 뷰포트 너비에서 정해지는 공통 간격(--pad, --stage-inset, --sticky-bar-h).
class ScreenMetrics {
  const ScreenMetrics(this.width);

  factory ScreenMetrics.of(BuildContext context) => ScreenMetrics(MediaQuery.sizeOf(context).width);

  final double width;

  bool get mobile => width <= Breakpoints.mobile;
  bool atMost(double breakpoint) => width <= breakpoint;

  double get pad => mobile ? 20 : 46;
  double get stageInset => mobile ? 12 : 28;
  double get stickyBarHeight => mobile ? 52 : 56;

  /// 앵커 이동 시 고정 바에 제목이 가리지 않게 하는 여백([id] scroll-margin-top).
  double get anchorMargin => stickyBarHeight + 16;
}

/// .shell 의 max-width 1440 가운데 정렬.
const double shellMaxWidth = 1440;
