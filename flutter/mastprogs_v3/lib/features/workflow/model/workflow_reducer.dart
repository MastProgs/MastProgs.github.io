// /workflow 상세 페이지 재생 리듀서(React src/workflow-detail/reducer.js 이식). 타이머 없이 cursor 만 움직인다
// (타이머는 WorkflowPlayerController).
// AI-NOTE: options 가 시나리오(route·seed·planReject·qaFail)를 정하고, 옵션·경로를 바꾸면 cursor·선택·기록이 처음으로 돌아간다.
// 프레임 조작: 이전·위치 이동·다음은 언제나 일시정지로 멈춘다. 화면·기록·원장은 모두 cursor 에서 다시 파생되므로
// 되감으면 미래 기록·지적이 남지 않고, 다시 앞으로 가도 중복되지 않는다. 끝(total)은 done, 0 은 idle, 그 사이는 paused.
// 재생 속도(speed)는 처음으로·옵션·경로 변경 뒤에도 유지한다(보는 사람의 선택).
import '../../../core/js_compat.dart';
import 'workflow_frames.dart';
import 'workflow_scenario.dart';

enum RunStatus {
  idle('대기'),
  running('재생 중'),
  paused('일시정지'),
  done('완료');

  const RunStatus(this.label);

  final String label;
}

class DetailState {
  const DetailState({
    required this.options,
    required this.status,
    required this.cursor,
    required this.selectedPath,
    required this.lastAction,
    required this.speed,
  });

  final ScenarioOptions options;
  final RunStatus status;
  final int cursor;
  final String? selectedPath;

  /// play | pause | hidden | reset | next | prev | seek | tick | options | route | null
  final String? lastAction;
  final double speed;

  DetailState copyWith({RunStatus? status, int? cursor, Object? selectedPath = _keep, Object? lastAction = _keep, double? speed}) => DetailState(
    options: options,
    status: status ?? this.status,
    cursor: cursor ?? this.cursor,
    selectedPath: identical(selectedPath, _keep) ? this.selectedPath : selectedPath as String?,
    lastAction: identical(lastAction, _keep) ? this.lastAction : lastAction as String?,
    speed: speed ?? this.speed,
  );
}

const Object _keep = Object();

sealed class DetailAction {
  const DetailAction();
}

class PlayAction extends DetailAction {
  const PlayAction();
}

class PauseAction extends DetailAction {
  const PauseAction({this.reason});

  /// 'hidden' 이면 탭이 가려져 멈춘 것(자동 재개 없음).
  final String? reason;
}

class ResetAction extends DetailAction {
  const ResetAction();
}

class NextAction extends DetailAction {
  const NextAction();
}

class PrevAction extends DetailAction {
  const PrevAction();
}

class SeekAction extends DetailAction {
  const SeekAction(this.cursor);

  /// 원본처럼 Number(cursor) 로 해석한다(유한한 수가 아니면 무시).
  final Object? cursor;
}

class TickAction extends DetailAction {
  const TickAction();
}

class SelectFileAction extends DetailAction {
  const SelectFileAction(this.path);

  final Object? path;
}

class FollowFilesAction extends DetailAction {
  const FollowFilesAction();
}

class SetOptionAction extends DetailAction {
  const SetOptionAction(this.key, this.value);

  final String key;
  final bool value;
}

class SetRouteAction extends DetailAction {
  const SetRouteAction(this.route);

  final String route;
}

class SetSpeedAction extends DetailAction {
  const SetSpeedAction(this.speed);

  final num speed;
}

/// 리듀서. 엔진(시나리오 캐시)을 받아 같은 옵션이면 같은 시나리오를 쓴다.
class DetailReducer {
  const DetailReducer(this.engine);

  final WorkflowEngine engine;

  DetailState create({String? route, bool? seed, bool? planReject, bool? qaFail, num cursor = 0, RunStatus status = RunStatus.idle, num? speed}) => _create(
    engine.normalize(route: route, seed: seed, planReject: planReject, qaFail: qaFail),
    cursor: cursor,
    status: status,
    speed: speed,
  );

  DetailState _create(ScenarioOptions options, {num cursor = 0, RunStatus status = RunStatus.idle, num? speed}) {
    final scenario = engine.scenario(options);
    final clamped = scenario.clamp(cursor);
    return DetailState(
      options: options,
      status: clamped == scenario.total ? RunStatus.done : status,
      cursor: clamped,
      selectedPath: null,
      lastAction: null,
      speed: normalizeSpeed(speed ?? defaultSpeed),
    );
  }

  WorkflowScenario scenarioOf(DetailState state) => engine.scenario(state.options);

  // 같은 시나리오로 처음 상태를 다시 만들되 재생 속도는 유지한다.
  DetailState _restart(DetailState state, ScenarioOptions options, String lastAction) => _create(options, speed: state.speed).copyWith(lastAction: lastAction);

  DetailState _advance(DetailState state, RunStatus status) {
    final total = scenarioOf(state).total;
    final cursor = state.cursor + 1 > total ? total : state.cursor + 1;
    return state.copyWith(cursor: cursor, status: cursor == total ? RunStatus.done : status);
  }

  // 수동 이동(이전·위치). 끝이면 done, 0 이면 idle, 그 사이는 paused.
  DetailState _moveTo(DetailState state, num target, String lastAction) {
    final scenario = scenarioOf(state);
    final cursor = scenario.clamp(target);
    var status = RunStatus.paused;
    if (cursor == scenario.total) {
      status = RunStatus.done;
    } else if (cursor == 0) {
      status = RunStatus.idle;
    }
    if (cursor == state.cursor && status == state.status) return state;
    return state.copyWith(cursor: cursor, status: status, lastAction: lastAction);
  }

  DetailState reduce(DetailState state, DetailAction action) {
    switch (action) {
      case PlayAction():
        if (state.status == RunStatus.running) return state;
        if (state.status == RunStatus.done) return _restart(state, state.options, 'play').copyWith(status: RunStatus.running);
        return state.copyWith(status: RunStatus.running, lastAction: 'play');
      case PauseAction(:final reason):
        if (state.status != RunStatus.running) return state;
        return state.copyWith(status: RunStatus.paused, lastAction: reason == 'hidden' ? 'hidden' : 'pause');
      case ResetAction():
        return _restart(state, state.options, 'reset');
      case NextAction():
        if (state.status == RunStatus.done) return state;
        return _advance(state, RunStatus.paused).copyWith(lastAction: 'next');
      case PrevAction():
        if (state.cursor == 0) return state;
        return _moveTo(state, state.cursor - 1, 'prev');
      case SeekAction(:final cursor):
        final value = jsNumber(cursor);
        if (!value.isFinite) return state;
        return _moveTo(state, value, 'seek');
      case TickAction():
        if (state.status != RunStatus.running) return state;
        return _advance(state, RunStatus.running).copyWith(lastAction: 'tick');
      case SelectFileAction(:final path):
        if (path is! String || path == state.selectedPath) return state;
        return state.copyWith(selectedPath: path);
      case FollowFilesAction():
        if (state.selectedPath == null) return state;
        return state.copyWith(selectedPath: null);
      case SetOptionAction(:final key, :final value):
        final current = state.options;
        final next = engine.normalize(
          route: current.route,
          seed: key == 'seed' ? value : current.seed,
          planReject: key == 'planReject' ? value : current.planReject,
          qaFail: key == 'qaFail' ? value : current.qaFail,
        );
        if (next == current) return state;
        return _restart(state, next, 'options');
      case SetRouteAction(:final route):
        // 경로를 바꾸면 그 경로의 기본 옵션으로 처음부터(순차의 실패 옵션 기본 켬 등). Seed 보기 선택만 이어 간다.
        final next = engine.normalize(route: route, seed: state.options.route == 'direct' ? null : state.options.seed);
        if (next.route == state.options.route) return state;
        return _restart(state, next, 'route');
      case SetSpeedAction(:final speed):
        // 목록(0.5·1·2배)에 없는 값은 무시한다. 재생 중이면 다음 타이머부터 새 간격을 쓴다.
        if (!speeds.contains(speed) || speed == state.speed) return state;
        return state.copyWith(speed: speed.toDouble());
    }
  }
}
