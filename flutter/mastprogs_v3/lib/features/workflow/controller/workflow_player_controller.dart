// /workflow 재생기 상태·타이머(React WorkflowPlayer.jsx 의 useReducer + useDetailPlayer 이식).
// AI-NOTE: 단계마다 타이머 하나만 예약하고 cursor/status/speed/경로가 바뀌면 정리한다. 간격은 frameDelay(speed)(0.5·1·2배 = 3000·1500·750ms).
// done 이면 더 예약하지 않아 무한 재실행이 없고, 탭이 가려지면 일시정지만 한다(자동 재개 없음). 이전·위치 이동·경로 변경은
// status 를 바꾸므로 예약된 타이머가 즉시 정리된다. 화면 값(대화·명세·레인·기록·프레임 강조)은 같은 (시나리오, cursor) 동안 한 번만 계산한다.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/workflow_content.dart';
import '../model/workflow_frames.dart';
import '../model/workflow_records.dart';
import '../model/workflow_reducer.dart';
import '../model/workflow_scenario.dart';

/// 한 프레임의 화면 값(모두 같은 시나리오·cursor 에서 파생).
class WorkflowFrame {
  WorkflowFrame(this.scenario, this.cursor)
    : messages = scenario.deriveConversation(cursor),
      spec = scenario.deriveSpec(cursor),
      taskPlan = scenario.deriveTaskPlan(cursor),
      lanes = scenario.deriveLanes(cursor),
      gate = scenario.deriveMergeGate(cursor),
      integration = scenario.deriveIntegration(cursor),
      direct = scenario.deriveDirect(cursor),
      records = deriveRecords(cursor, scenario),
      changes = deriveRecordChanges(cursor, scenario),
      targets = deriveFrameTargets(scenario, cursor),
      title = frameTitle(scenario, cursor),
      dispatched = scenario.isDispatched(cursor);

  final WorkflowScenario scenario;
  final int cursor;
  final List<ConversationMessage> messages;
  final SpecState? spec;
  final TaskPlanState? taskPlan;
  final List<LaneState> lanes;
  final MergeGateState? gate;
  final List<IntegrationStepState> integration;
  final List<DirectNodeState> direct;
  final WorkflowRecords records;
  final Map<String, String> changes;
  final FrameTargets targets;
  final String title;
  final bool dispatched;
}

typedef TimerFactory = Timer Function(Duration duration, void Function() callback);

class WorkflowPlayerController extends ChangeNotifier {
  WorkflowPlayerController({required WorkflowContent content, String route = 'parallel', ValueListenable<bool>? pageHidden, TimerFactory? timerFactory})
    : _engine = WorkflowEngine(content),
      _pageHidden = pageHidden,
      _timerFactory = timerFactory ?? Timer.new {
    _reducer = DetailReducer(_engine);
    _state = _reducer.create(route: route);
    _pageHidden?.addListener(_onVisibility);
  }

  final WorkflowEngine _engine;
  late final DetailReducer _reducer;
  final ValueListenable<bool>? _pageHidden;
  final TimerFactory _timerFactory;
  late DetailState _state;
  Timer? _timer;
  WorkflowFrame? _frame;
  bool _follow = true;
  bool _disposed = false;

  WorkflowContent get content => _engine.content;
  DetailState get state => _state;
  WorkflowScenario get scenario => _reducer.scenarioOf(_state);
  bool get follow => _follow;

  /// 현재 프레임 값(같은 시나리오·cursor 면 다시 계산하지 않음).
  WorkflowFrame get frame {
    final scenario = this.scenario;
    final cached = _frame;
    if (cached != null && identical(cached.scenario, scenario) && cached.cursor == _state.cursor) return cached;
    return _frame = WorkflowFrame(scenario, _state.cursor);
  }

  /// 타이머가 지금 예약되어 있는지(테스트·점검용).
  bool get hasPendingTimer => _timer?.isActive ?? false;

  void dispatch(DetailAction action) {
    if (_disposed) return;
    final next = _reducer.reduce(_state, action);
    if (identical(next, _state)) return;
    final previous = _state;
    _state = next;
    _reschedule(previous);
    notifyListeners();
  }

  void play() => dispatch(const PlayAction());
  void pause() => dispatch(const PauseAction());
  void reset() => dispatch(const ResetAction());
  void next() => dispatch(const NextAction());
  void prev() => dispatch(const PrevAction());
  void seek(num cursor) => dispatch(SeekAction(cursor));
  void setSpeed(num speed) => dispatch(SetSpeedAction(speed));
  void setRoute(String route) => dispatch(SetRouteAction(route));
  void setOption(String key, bool value) => dispatch(SetOptionAction(key, value));
  void selectFile(String path) => dispatch(SelectFileAction(path));
  void followFiles() => dispatch(const FollowFilesAction());

  void setFollow(bool value) {
    if (_follow == value) return;
    _follow = value;
    notifyListeners();
  }

  // 타이머는 status·cursor·speed·경로가 바뀔 때만 다시 건다(useDetailPlayer 의 effect 의존성과 같음).
  void _reschedule(DetailState previous) {
    final changed =
        previous.status != _state.status ||
        previous.cursor != _state.cursor ||
        previous.speed != _state.speed ||
        previous.options.route != _state.options.route;
    if (!changed && _timer != null) return;
    _timer?.cancel();
    _timer = null;
    if (_state.status != RunStatus.running) return;
    _timer = _timerFactory(Duration(milliseconds: frameDelay(_state.speed)), () {
      _timer = null;
      dispatch(const TickAction());
    });
  }

  void _onVisibility() {
    if (_pageHidden?.value ?? false) dispatch(const PauseAction(reason: 'hidden'));
  }

  /// 화면 낭독용 알림 문구(React announcementFor).
  String get announcement {
    final state = _state;
    switch (state.lastAction) {
      case 'hidden':
        return '탭이 가려져 일시정지했습니다.';
      case 'reset':
        return '처음으로 돌아갔습니다. 기록을 비웠습니다.';
      case 'options':
        return '옵션을 바꿔 처음으로 돌아갔습니다.';
      case 'route':
        return '경로를 바꿔 처음으로 돌아갔습니다.';
      case 'pause':
        return '일시정지';
    }
    final manual = const ['next', 'prev', 'seek'].contains(state.lastAction);
    if (manual && state.cursor == 0) return '시작 전 프레임';
    return scenario.stepAnnouncement(state.cursor, manual: manual);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _pageHidden?.removeListener(_onVisibility);
    super.dispose();
  }
}
