// /workflow 재생 리듀서·컨트롤러 동작(React tests/workflow-detail.test.mjs 의 재생 규칙 이식 + 타이머·탭 가림 검사).
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastprogs_v3/features/workflow/controller/workflow_player_controller.dart';
import 'package:mastprogs_v3/features/workflow/model/workflow_content.dart';
import 'package:mastprogs_v3/features/workflow/model/workflow_frames.dart';
import 'package:mastprogs_v3/features/workflow/model/workflow_records.dart';
import 'package:mastprogs_v3/features/workflow/model/workflow_reducer.dart';
import 'package:mastprogs_v3/features/workflow/model/workflow_scenario.dart';

import 'support/fake_timers.dart';
import 'support/fixtures.dart';

void main() {
  final content = WorkflowContent.fromJson(readData('workflowDetail'));
  final engine = WorkflowEngine(content);
  final reducer = DetailReducer(engine);
  DetailState run(DetailState state, List<DetailAction> actions) => actions.fold(state, reducer.reduce);
  List<DetailAction> ticks(int count) => List.filled(count, const TickAction());

  group('reducer', () {
    test('play, pause, next, reset are deterministic and reset clears records and selection', () {
      var state = reducer.create();
      expect([state.options.route, state.options.seed, scenarioTotal(reducer, state)], ['parallel', true, 33]);
      state = run(state, [const PlayAction(), ...ticks(2), const PauseAction()]);
      expect(state.cursor, 2);
      expect(run(state, ticks(1)).cursor, 2, reason: 'ticks while paused are ignored');
      state = run(state, [const NextAction(), const SelectFileAction('current.md')]);
      expect([state.status, state.cursor, state.selectedPath], [RunStatus.paused, 3, 'current.md']);
      state = run(state, [const ResetAction()]);
      expect([state.cursor, state.status, state.selectedPath, state.lastAction], [0, RunStatus.idle, null, 'reset']);
      expect(deriveRecords(state.cursor, reducer.scenarioOf(state)).files, isEmpty);
    });

    test('ends in done without rerunning; play from done restarts; seek and prev pause', () {
      for (final route in ['parallel', 'sequential', 'direct']) {
        final start = reducer.create(route: route);
        final total = scenarioTotal(reducer, start);
        var state = run(start, [const PlayAction(), ...ticks(total + 5)]);
        expect([state.status, state.cursor], [RunStatus.done, total]);
        state = run(state, [const PlayAction(), ...ticks(2)]);
        expect([state.cursor, state.status], [2, RunStatus.running]);
        state = run(state, [const PrevAction()]);
        expect([state.cursor, state.status, state.lastAction], [1, RunStatus.paused, 'prev']);
        state = run(state, [const PlayAction(), const SeekAction(2)]);
        expect([state.cursor, state.status, state.lastAction], [2, RunStatus.paused, 'seek']);
        state = run(state, [SeekAction(total + 9)]);
        expect([state.cursor, state.status], [total, RunStatus.done]);
        expect(identical(run(state, [const NextAction()]), state), isTrue, reason: 'next is unavailable at the end');
        state = run(state, [const PrevAction()]);
        expect([state.cursor, state.status], [total - 1, RunStatus.paused]);
        state = run(state, [const SeekAction(1.7)]);
        expect([state.cursor, state.status], [1, RunStatus.paused], reason: 'integer frames (trunc)');
        expect(identical(run(state, [const SeekAction('x')]), state), isTrue, reason: 'Number("x") is NaN → ignored');
        expect(identical(run(state, [const SeekAction(double.infinity)]), state), isTrue, reason: 'non-finite seek ignored');
        expect(run(state, [const SeekAction(null)]).cursor, 0, reason: 'Number(null) is 0 like React');
        expect(run(state, [const SeekAction('2')]).cursor, 2, reason: 'numeric strings convert like Number()');
        state = run(state, [const SeekAction(0)]);
        expect([state.cursor, state.status], [0, RunStatus.idle]);
        expect(identical(run(state, [const PrevAction()]), state), isTrue, reason: 'previous unavailable at frame 0');
        state = run(state, [SeekAction(total), const PlayAction()]);
        expect([state.cursor, state.status], [0, RunStatus.running], reason: 'replay restarts once from frame 0');
        state = run(state, ticks(total + 4));
        expect([state.cursor, state.status], [total, RunStatus.done], reason: 'no auto loop');
      }
    });

    test('route and option changes reset progress and stop playback; speed is kept; Seed carries outside direct', () {
      var state = run(reducer.create(), [const SetSpeedAction(2), const PlayAction(), ...ticks(2)]);
      state = run(state, [const SetRouteAction('sequential')]);
      expect([state.cursor, state.status, state.lastAction, state.speed], [0, RunStatus.idle, 'route', 2.0]);
      expect(state.options.toJson(), {'route': 'sequential', 'seed': true, 'planReject': true, 'qaFail': true});
      expect(identical(run(state, [const SetRouteAction('sequential')]), state), isTrue);
      state = run(state, [const PlayAction(), ...ticks(1), const SetOptionAction('qaFail', false)]);
      expect([state.cursor, state.status, state.speed, state.lastAction], [0, RunStatus.idle, 2.0, 'options']);
      // Seed 끔은 직접 처리 밖에서 경로를 바꿔도 이어 간다.
      state = run(state, [const SetOptionAction('seed', false), const SetRouteAction('parallel')]);
      expect(state.options.seed, isFalse);
      state = run(state, [const NextAction(), const SetRouteAction('direct')]);
      expect([scenarioTotal(reducer, state), state.cursor, state.status], [3, 0, RunStatus.idle]);
      // 직접 처리에서 나올 때는 경로 기본값(Seed 켬)을 다시 쓴다.
      state = run(state, [const SetRouteAction('sequential')]);
      expect(state.options.toJson(), {'route': 'sequential', 'seed': true, 'planReject': true, 'qaFail': true});
      expect(identical(run(state, [const SetSpeedAction(3)]), state), isTrue, reason: 'unknown speeds are ignored');
      expect(run(state, [const ResetAction()]).speed, 2.0);
      expect(run(state, [const SetRouteAction('nonsense')]).options.route, 'parallel', reason: 'unknown routes normalise to parallel');
    });

    test('options: same value is a no-op, failure options do not apply to parallel, parallel Seed keeps 33 frames', () {
      var state = reducer.create(route: 'sequential');
      state = run(state, [const PlayAction(), ...ticks(2), const SelectFileAction('current.md'), const SetOptionAction('planReject', false)]);
      expect([state.cursor, state.status, state.selectedPath, state.lastAction], [0, RunStatus.idle, null, 'options']);
      expect(scenarioTotal(reducer, state), 18);
      expect(identical(run(state, [const SetOptionAction('planReject', false)]), state), isTrue);
      final par = reducer.create();
      expect(identical(run(par, [const SetOptionAction('qaFail', true)]), par), isTrue);
      final noSeed = run(par, [const SetOptionAction('seed', false)]);
      expect(scenarioTotal(reducer, noSeed), 33, reason: 'parallel Seed switch is display-only');
      expect(identical(reducer.scenarioOf(noSeed), engine.scenario(engine.normalize(seed: false))), isTrue);
      expect(reducer.scenarioOf(noSeed).seeded, isTrue);
      expect(identical(run(par, [const SetOptionAction('unknown', true)]), par), isTrue);
    });

    test('file pin: SELECT_FILE pins, FOLLOW_FILES returns to the latest change, invalid paths are ignored', () {
      var state = run(reducer.create(), [const NextAction()]);
      expect(identical(run(state, [const SelectFileAction(42)]), state), isTrue);
      state = run(state, [const SelectFileAction('00-request/request.md')]);
      expect(identical(run(state, [const SelectFileAction('00-request/request.md')]), state), isTrue);
      state = run(state, [const NextAction(), const NextAction()]);
      expect(state.selectedPath, '00-request/request.md', reason: 'pin survives later frames');
      state = run(state, [const FollowFilesAction()]);
      expect(state.selectedPath, isNull);
      expect(identical(run(state, [const FollowFilesAction()]), state), isTrue);
    });

    test('frame delays: 0.5x = 3000ms, 1x = 1500ms, 2x = 750ms; unknown speeds fall back to 1x', () {
      expect(speeds, [0.5, 1, 2]);
      expect(speeds.map(frameDelay).toList(), [3000, 1500, 750]);
      expect(frameDelay(3), 1500);
      expect(frameDelay(null), 1500);
    });

    test('follow scroll delta: no move when visible, align top below the bar, bottom when overflowing', () {
      expect(followScrollDelta(top: 200, bottom: 300, safeTop: 120, viewportHeight: 900), isNull);
      expect(followScrollDelta(top: 50, bottom: 100, safeTop: 120, viewportHeight: 900), -86);
      expect(followScrollDelta(top: 850, bottom: 950, safeTop: 120, viewportHeight: 900), 66);
      expect(followScrollDelta(top: 400, bottom: 2000, safeTop: 120, viewportHeight: 900), 264, reason: 'taller than the view → top aligns');
    });
  });

  group('player controller', () {
    test('one timer per frame at the selected speed; play from done replays once; hidden pauses without auto-resume', () {
      final timers = FakeTimers();
      final hidden = ValueNotifier(false);
      final controller = WorkflowPlayerController(content: content, pageHidden: hidden, timerFactory: timers.call);
      addTearDown(controller.dispose);
      expect(controller.hasPendingTimer, isFalse, reason: 'no autoplay on load');
      controller.play();
      expect(timers.single.duration, const Duration(milliseconds: 1500));
      timers.fireActive();
      expect(controller.state.cursor, 1);
      controller.setSpeed(2);
      expect(timers.single.duration, const Duration(milliseconds: 750), reason: 'speed change re-arms with the new interval');
      controller.setSpeed(0.5);
      expect(timers.single.duration, const Duration(milliseconds: 3000));
      controller.selectFile('index.md');
      expect(timers.active, hasLength(1), reason: 'file pin does not re-arm or duplicate timers');
      controller.next();
      expect(timers.active, isEmpty, reason: 'next pauses');
      controller.play();
      hidden.value = true;
      expect(controller.state.status, RunStatus.paused);
      expect(controller.state.lastAction, 'hidden');
      expect(controller.announcement, '탭이 가려져 일시정지했습니다.');
      expect(timers.active, isEmpty);
      hidden.value = false;
      expect(controller.state.status, RunStatus.paused, reason: 'no auto resume');
      controller.seek(controller.scenario.total);
      expect(controller.state.status, RunStatus.done);
      controller.play();
      expect([controller.state.cursor, controller.state.status], [0, RunStatus.running]);
      for (var i = 0; i < controller.scenario.total; i += 1) {
        timers.fireActive();
      }
      expect(controller.state.status, RunStatus.done);
      expect(timers.active, isEmpty, reason: 'done arms nothing');
    });

    test('route change stops timers and resets records; frame values are memoised per cursor', () {
      final timers = FakeTimers();
      final controller = WorkflowPlayerController(content: content, timerFactory: timers.call);
      addTearDown(controller.dispose);
      controller.play();
      timers.fireActive();
      final frame = controller.frame;
      expect(identical(controller.frame, frame), isTrue);
      controller.setRoute('direct');
      expect(timers.active, isEmpty);
      expect(controller.frame.records.files, isEmpty);
      expect(controller.announcement, '경로를 바꿔 처음으로 돌아갔습니다.');
      controller.next();
      expect(controller.frame.direct.first.status, 'done');
    });

    test('dispose cancels the pending timer', () {
      final timers = FakeTimers();
      final controller = WorkflowPlayerController(content: content, timerFactory: timers.call);
      controller.play();
      final timer = timers.single;
      controller.dispose();
      expect(timer.isActive, isFalse);
    });
  });
}

int scenarioTotal(DetailReducer reducer, DetailState state) => reducer.scenarioOf(state).total;
