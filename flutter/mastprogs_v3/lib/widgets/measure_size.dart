// 자식의 배치 크기가 바뀌면 알려 준다(고정 재생기 높이·머리 높이 측정용). 크기 변화 때만 다음 프레임에 한 번 부른다.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class MeasureSize extends SingleChildRenderObjectWidget {
  const MeasureSize({super.key, required this.onChange, super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderMeasureSize(onChange);

  @override
  void updateRenderObject(BuildContext context, RenderMeasureSize renderObject) => renderObject.onChange = onChange;
}

class RenderMeasureSize extends RenderProxyBox {
  RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    final current = size;
    if (current == _last) return;
    _last = current;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onChange(current);
    });
  }
}
