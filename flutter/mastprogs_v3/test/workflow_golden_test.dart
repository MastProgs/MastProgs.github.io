// /workflow 순수 모델 ↔ React 기준(test/fixtures/workflow-golden.json, fcdfc01) 차등 비교.
// 11개 옵션 조합의 모든 cursor(216개 상태)에서 대화·명세·Task Planning·레인·원장·계보·게이트·통합·직접 처리·
// 기록 파일 내용·프레임 강조·제목·알림 문구를 원본과 한 글자도 다르지 않게 맞춘다.
import 'package:flutter_test/flutter_test.dart';
import 'package:mastprogs_v3/core/json.dart';
import 'package:mastprogs_v3/features/workflow/model/workflow_content.dart';
import 'package:mastprogs_v3/features/workflow/model/workflow_frames.dart';
import 'package:mastprogs_v3/features/workflow/model/workflow_records.dart';
import 'package:mastprogs_v3/features/workflow/model/workflow_scenario.dart';

import 'support/fixtures.dart';

void main() {
  final content = WorkflowContent.fromJson(readData('workflowDetail'));
  final engine = WorkflowEngine(content);
  final golden = asJsonList(readFixture('workflow-golden'));

  test('fixture covers 11 scenarios and 216 cursor states', () {
    expect(golden, hasLength(11));
    expect(golden.fold<int>(0, (sum, s) => sum + (s['states'] as List).length), 216);
  });

  for (final expected in golden) {
    final options = expected.obj('options');
    final label = '${options['route']} seed=${options['seed']} planReject=${options['planReject']} qaFail=${options['qaFail']}';

    group(label, () {
      final scenario = engine.scenario(
        engine.normalize(route: options.str('route'), seed: options.flag('seed'), planReject: options.flag('planReject'), qaFail: options.flag('qaFail')),
      );

      test('scenario steps, events and step marks', () {
        final actual = scenario.toJson();
        for (final key in actual.keys) {
          expect(actual[key], equals(expected[key]), reason: key);
        }
      });

      final states = expected.objs('states');
      for (final (index, state) in states.indexed) {
        final cursor = state.integer('cursor');
        test('cursor $cursor', () {
          expect(cursor, index);
          expect([for (final m in scenario.deriveConversation(cursor)) m.toJson()], equals(state['conversation']), reason: 'conversation');
          expect(scenario.deriveSpec(cursor)?.toJson(), equals(state['spec']), reason: 'spec');
          expect(scenario.deriveTaskPlan(cursor)?.toJson(), equals(state['taskPlan']), reason: 'taskPlan');
          final lanes = [for (final lane in scenario.deriveLanes(cursor)) lane.toJson()];
          final expectedLanes = state['lanes'] as List;
          expect(lanes.length, expectedLanes.length);
          for (var i = 0; i < lanes.length; i += 1) {
            expect(lanes[i], equals(expectedLanes[i]), reason: 'lane $i');
          }
          expect(scenario.deriveMergeGate(cursor)?.toJson(), equals(state['mergeGate']), reason: 'mergeGate');
          expect([for (final s in scenario.deriveIntegration(cursor)) s.toJson()], equals(state['integration']), reason: 'integration');
          expect([for (final n in scenario.deriveDirect(cursor)) n.toJson()], equals(state['direct']), reason: 'direct');
          final records = deriveRecords(cursor, scenario).toJson();
          final expectedRecords = state.obj('records');
          expect(records['root'], expectedRecords['root']);
          expect(records['latestPath'], expectedRecords['latestPath']);
          final files = records['files'] as List;
          final expectedFiles = expectedRecords['files'] as List;
          expect([for (final f in files) (f as Map)['path']], equals([for (final f in expectedFiles) (f as Map)['path']]), reason: 'file order');
          for (var i = 0; i < files.length; i += 1) {
            expect((files[i] as Map)['content'], equals((expectedFiles[i] as Map)['content']), reason: (files[i] as Map)['path'] as String);
          }
          expect(deriveFrameTargets(scenario, cursor).toJson(), equals(state['targets']), reason: 'targets');
          expect(frameTitle(scenario, cursor), state['title']);
          expect(scenario.describeStep(cursor), state['description']);
          expect(scenario.stepAnnouncement(cursor, manual: true), state['announcement']);
        });
      }

      // 기준 fixture 의 recordChanges 는 원본 Map 이 JSON 으로 {} 가 되어 비어 있다. 같은 fixture 의 앞뒤 기록 내용에서
      // 새 파일·갱신을 직접 계산해 deriveRecordChanges 와 비교한다(기준을 약하게 만들지 않고 같은 원본 데이터에서 파생).
      test('record changes follow consecutive golden records', () {
        for (var cursor = 0; cursor < states.length; cursor += 1) {
          final expectedChanges = <String, String>{};
          if (cursor > 0) {
            final before = {for (final f in states[cursor - 1].obj('records').objs('files')) f.str('path'): f.str('content')};
            for (final f in states[cursor].obj('records').objs('files')) {
              final path = f.str('path');
              if (!before.containsKey(path)) {
                expectedChanges[path] = 'new';
              } else if (before[path] != f.str('content')) {
                expectedChanges[path] = 'updated';
              }
            }
          }
          expect(deriveRecordChanges(cursor, scenario), equals(expectedChanges), reason: 'cursor $cursor');
        }
      });
    });
  }
}
