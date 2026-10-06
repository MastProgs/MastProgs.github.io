// 번들 JSON(assets/data) 을 읽는 작은 도우미.
// AI-NOTE: assets/data/*.json 은 React 원본 상수(demo/src/content/*.js)를 내보낸 값이다. 단, 사용자 후속 지시로 resume.json 의
// ABOUT 대표 사례(제목 "대표 사례", 스프라이트·자막 항목 추가, 첫 세 링크는 내부 상세 경로), subtitles.json 의 상태 문구(status) 삭제,
// site.json 사례 03 limits 의 "현재 개발 중인 도구" 첫 문장 삭제와 상세 링크의 같은 탭 안내, resume.json CONTACT 의 사용자 입력 이메일·전화 값이 React 와 다르다(포트폴리오에 개발 진행 고지를 두지 않는다). 여기서는 형 변환만 하고
// 값을 바꾸거나 기본값을 지어내지 않는다. 키가 없으면 형 변환 오류로 바로 드러나게 둔다(문구 누락을 숨기지 않음).

typedef Json = Map<String, Object?>;

Json asJson(Object? value) => (value as Map).cast<String, Object?>();

List<Json> asJsonList(Object? value) => [for (final item in value as List) asJson(item)];

List<String> asStrings(Object? value) => (value as List).cast<String>();

extension JsonRead on Json {
  String str(String key) => this[key] as String;

  String? strOrNull(String key) => this[key] as String?;

  int integer(String key) => (this[key] as num).toInt();

  double number(String key) => (this[key] as num).toDouble();

  bool flag(String key) => this[key] as bool;

  List<String> strings(String key) => asStrings(this[key]);

  Json obj(String key) => asJson(this[key]);

  Json? objOrNull(String key) => this[key] == null ? null : asJson(this[key]);

  List<Json> objs(String key) => asJsonList(this[key]);

  /// 문구 묶음 객체에서 문자열 값만 `Map<String, String>` 으로(목록 값은 strings 로 따로 읽는다).
  Map<String, String> texts(String key) => {
    for (final entry in asJson(this[key]).entries)
      if (entry.value is String) entry.key: entry.value as String,
  };
}
