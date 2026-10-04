// 읽기 전용 글(기록 파일 내용·SRT 결과 등). 화면은 SelectableText 그대로(끌어 선택·복사 가능)다.
// AI-NOTE: SelectableText 는 접근성에서 읽기 전용 텍스트 필드가 되어, 웹에서는 값이 빈 비활성 입력칸으로 보였다(그린 글자를 읽을 수 없음).
// 원본 <pre aria-label> 처럼 이름(label)과 내용(value)을 가진 읽기 노드 하나로 내고, 안쪽 텍스트 필드 노드는 뺀다.
import 'package:flutter/material.dart';

class ReadableText extends StatelessWidget {
  const ReadableText(this.text, {super.key, required this.style, this.label});

  final String text;
  final TextStyle style;

  /// 접근성 이름(원본 aria-label). 없으면 글 자체를 이름으로 쓴다.
  final String? label;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label ?? text,
    value: label == null ? null : text,
    child: ExcludeSemantics(child: SelectableText(text, style: style)),
  );
}
