// 한국어 낱말 단위 줄바꿈(keep-all)을 지키는 글자 위젯. 화면 낭독은 원문을 쓴다.
import 'package:flutter/widgets.dart';

import '../app/theme/typography.dart';

class KText extends StatelessWidget {
  const KText(this.text, {super.key, this.style, this.textAlign, this.maxLines, this.overflow, this.softWrap, this.semanticsLabel});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => Text(
    keepAll(text),
    style: style,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
    softWrap: softWrap,
    semanticsLabel: semanticsLabel ?? text,
  );
}

/// 여러 모양이 섞인 한 문단(<b>, <code> 등). 각 조각에 keep-all 을 적용한다.
class KRich extends StatelessWidget {
  const KRich(this.spans, {super.key, this.style, this.textAlign});

  final List<InlineSpan> spans;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(style: style, children: spans),
    textAlign: textAlign,
  );
}

/// keep-all 이 적용된 글자 조각.
TextSpan kSpan(String text, [TextStyle? style]) => TextSpan(text: keepAll(text), style: style, semanticsLabel: text);
