// 테스트 공용: 번들 데이터(assets/data)와 React 기준 fixture(test/fixtures)를 파일에서 직접 읽는다.
// AI-NOTE: fixture 는 기대 출력일 뿐이다. 런타임 코드는 이 값을 읽지 않고 Dart 순수 모델이 직접 계산한다.
import 'dart:convert';
import 'dart:io';

import 'package:mastprogs_v3/core/json.dart';

Object? readJsonFile(String path) => jsonDecode(File(path).readAsStringSync());

Json readData(String name) => asJson(readJsonFile('assets/data/$name.json'));

Object? readFixture(String name) => readJsonFile('test/fixtures/$name.json');
