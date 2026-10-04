// React 원본(JavaScript) 순수 함수의 결과를 바이트·문자열 단위로 맞추기 위한 작은 호환 도우미.
// AI-NOTE: 모델 이식은 원본과 같은 출력(문자열·JSON 텍스트·정렬 순서)을 내야 한다(test/fixtures 차등 비교).
// - JSON.stringify(value, null, 2) + "\n" 은 Dart JsonEncoder.withIndent('  ') 와 같은 모양이다(빈 배열 `[]`, 비ASCII 그대로).
// - Array.prototype.sort 는 안정 정렬이고 Dart List.sort 는 아니므로, 같은 값끼리 순서가 중요한 곳은 stableSorted 를 쓴다.
// - Number(x) 의 변환 규칙(null → 0, '' → 0, 숫자 문자열 → 값, 그 밖 → NaN)은 jsNumber 가 맡는다.
import 'dart:convert';

const JsonEncoder _pretty = JsonEncoder.withIndent('  ');

/// JSON.stringify(value, null, 2) + "\n".
String jsonPretty(Object? value) => '${_pretty.convert(value)}\n';

/// JSON.stringify(value) (공백 없음).
String jsonCompact(Object? value) => jsonEncode(value);

/// String(value).padStart(width, "0").
String padZero(Object value, [int width = 2]) => value.toString().padLeft(width, '0');

/// JavaScript Number(value) 와 같은 변환. 해석할 수 없으면 double.nan.
num jsNumber(Object? value) {
  if (value == null) return 0;
  if (value is num) return value;
  if (value is bool) return value ? 1 : 0;
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 0;
    return num.tryParse(trimmed) ?? double.nan;
  }
  return double.nan;
}

/// Number.isInteger(value).
bool jsIsInteger(Object? value) => value is int || (value is double && value.isFinite && value == value.truncateToDouble());

/// 원본 Array.prototype.sort(안정 정렬)와 같은 순서를 내는 정렬. 입력은 바꾸지 않는다.
List<T> stableSorted<T>(Iterable<T> items, int Function(T a, T b) compare) {
  final indexed = [for (final (index, item) in items.indexed) (index, item)];
  indexed.sort((a, b) {
    final result = compare(a.$2, b.$2);
    return result != 0 ? result : a.$1.compareTo(b.$1);
  });
  return [for (final entry in indexed) entry.$2];
}
