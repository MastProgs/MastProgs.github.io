// /workflow 상세 페이지의 순수 모델(React src/workflow-detail/model.js 이식).
// AI-NOTE: 브라우저·Flutter API 를 쓰지 않는다. 화면 상태(대화, WORK SPEC, Task Planning, Seed 계보, 레인, 병합 게이트, 통합, 기록)는
// 시나리오 하나의 steps 와 cursor 에서 파생된다. cursor = 적용된 단계 수(0..total). 타이머나 저장 상태가 없으므로
// 같은 시나리오·cursor 는 항상 같은 화면이다. WorkflowEngine.scenario(options) 가 직접 처리·순차·병렬 공용 엔진이다
// (직접 처리는 요청 → 직접 처리 → 응답 3단계). 결과는 test/fixtures/workflow-golden.json(원본이 만든 216개 상태)과 차등 비교한다.
import '../../../core/js_compat.dart';
import 'workflow_content.dart';

// AI-NOTE: 병렬 전용 전체 Task Planning 세 프레임(WORK SPEC 다음, 지시 배정·Seed·레인 기획 전).
// 제안(task-split) → 검토 승인(task-review) → 동결(task-freeze). 동결된(승인된) 계약만 레인 배정에 쓰인다.
const List<String> taskStages = ['task-split', 'task-review', 'task-freeze'];

class LaneStageDef {
  const LaneStageDef(this.id, this.label);

  final String id;
  final String label;
}

const List<LaneStageDef> laneStages = [
  LaneStageDef('plan', '기획'),
  LaneStageDef('plan-review', '기획 검수'),
  LaneStageDef('dev', '개발'),
  LaneStageDef('dev-review', '개발 검수'),
  LaneStageDef('qa', 'QA'),
  LaneStageDef('ready', '완료'),
];

// 반려·실패 시 되돌아가는 단계. QA 실패는 개발로 돌아가 개발 검수와 QA 를 다시 거친다.
const Map<String, String> returnTarget = {'plan-review': 'plan', 'dev-review': 'dev', 'qa': 'dev'};

const Map<String, String> verdictLabel = {'approved': '승인', 'rejected': '반려', 'passed': '통과', 'failed': '실패'};

// AI-NOTE: 세션 계보(sequential-seed-workflow.md). 단계마다 세션이 정해져 있고, Seed 를 쓰면 Author/Reviewer 계열 child 는
// 역할별 Seed 에서 sibling 으로 fork 된다. 같은 단계의 재작업은 같은 child 를 resume 하며 Seed 는 다시 만들지 않는다.
// QA 와 Wiki 는 부모가 없다(구현자·Seed 문맥 상속 없음). QA 재시도는 같은 레인 QA 세션을 resume 한다(매번 새로 만들지 않음).
// 병렬 레인 Seed 는 문서상 항상 있으므로 seeded = parallel || options.seed 다. 병렬의 seed 옵션은 화면 표시만 바꾼다.
const Map<String, String> sessionForStage = {
  'plan': 'plan-author',
  'plan-review': 'plan-reviewer',
  'dev': 'dev-author',
  'dev-review': 'dev-reviewer',
  'qa': 'qa',
};

const Map<String, String> seedParent = {
  'plan-author': 'author-seed',
  'dev-author': 'author-seed',
  'plan-reviewer': 'reviewer-seed',
  'dev-reviewer': 'reviewer-seed',
};

const List<String> seedChildren = ['plan-author', 'dev-author', 'plan-reviewer', 'dev-reviewer'];

final Map<String, String> _stageLabel = {for (final stage in laneStages) stage.id: stage.label};

String stageLabel(String stageId) => _stageLabel[stageId] ?? stageId;

// 기록 예시의 시각. 날짜 없이 HH:MM:SS 만 쓴다(개인정보 검사의 날짜 패턴과 겹치지 않게).
String _clockFor(int step, int offset) {
  final seconds = 9 * 3600 + 30 * 60 + step * 150 + offset * 20;
  return '${padZero(seconds ~/ 3600)}:${padZero((seconds % 3600) ~/ 60)}:${padZero(seconds % 60)}';
}

/// 시나리오 옵션(경로·Seed 보기·기획 검수 실패·QA 실패).
class ScenarioOptions {
  const ScenarioOptions._({required this.route, required this.seed, required this.planReject, required this.qaFail});

  /// 원본 normalizeScenario. 값이 null(undefined)이면 기본값, 경로가 순차·직접이 아니면 병렬.
  /// 병렬은 고정 예시라 실패 옵션을 쓰지 않는다(Seed 보기만 반영). 직접 처리에는 옵션이 하나도 없다.
  factory ScenarioOptions.normalize(WorkflowContent content, {String? route, bool? seed, bool? planReject, bool? qaFail}) {
    final resolved = route == 'sequential' || route == 'direct' ? route! : 'parallel';
    final sequential = resolved == 'sequential';
    bool pick(bool? value, String key) => value ?? content.defaultOption(key);
    return ScenarioOptions._(
      route: resolved,
      seed: resolved == 'direct' ? false : pick(seed, 'seed'),
      planReject: sequential ? pick(planReject, 'planReject') : false,
      qaFail: sequential ? pick(qaFail, 'qaFail') : false,
    );
  }

  final String route;
  final bool seed;
  final bool planReject;
  final bool qaFail;

  bool flag(String key) => switch (key) {
    'seed' => seed,
    'planReject' => planReject,
    'qaFail' => qaFail,
    _ => false,
  };

  String get cacheKey => '$route|$seed|$planReject|$qaFail';

  @override
  bool operator ==(Object other) => other is ScenarioOptions && other.cacheKey == cacheKey;

  @override
  int get hashCode => cacheKey.hashCode;

  Map<String, Object?> toJson() => {'route': route, 'seed': seed, 'planReject': planReject, 'qaFail': qaFail};
}

enum _EventShape { message, direct, spec, task, seed, lane, integration, synthetic }

/// 단계 안의 이벤트 하나. 원본 finalizeSteps 의 기본 키(lane·stage·attempt·verdict·reason·session·parentSession)에
/// 이벤트 고유 키가 덧붙고 seq·id·step·time 이 붙는다. toJson 은 원본 객체와 같은 키 집합을 낸다.
class WorkflowEvent {
  const WorkflowEvent._({
    required _EventShape shape,
    required this.type,
    required this.actor,
    required this.text,
    required this.seq,
    required this.id,
    required this.step,
    required this.time,
    this.lane,
    this.stage,
    this.attempt,
    this.verdict,
    this.reason,
    this.session,
    this.parentSession,
    this.decision,
    this.tasks,
    this.issueId,
    this.resolves,
    this.ready = false,
    this.resumed = false,
  }) : _shape = shape;

  final _EventShape _shape;
  final String type;
  final String actor;
  final String text;
  final int seq;
  final String id;
  final int step;
  final String time;
  final String? lane;
  final String? stage;
  final int? attempt;
  final String? verdict;
  final String? reason;
  final String? session;
  final String? parentSession;
  final String? decision;
  final List<String>? tasks;
  final String? issueId;
  final String? resolves;
  final bool ready;
  final bool resumed;

  bool get isFault => verdict == 'rejected' || verdict == 'failed';

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'lane': lane,
      'stage': stage,
      'attempt': attempt,
      'verdict': verdict,
      'reason': reason,
      'session': session,
      'parentSession': parentSession,
      'type': type,
      'actor': actor,
    };
    if (_shape == _EventShape.message && decision != null) json['decision'] = decision;
    if (tasks != null) json['tasks'] = [...tasks!];
    if (_shape == _EventShape.lane) {
      json['issueId'] = issueId;
      json['resolves'] = resolves;
      json['ready'] = ready;
      json['resumed'] = resumed;
    }
    json['text'] = text;
    json['seq'] = seq;
    json['id'] = id;
    json['step'] = step;
    json['time'] = time;
    return json;
  }
}

/// finalizeSteps 이전의 이벤트 초안(seq·id·시각 없음).
class _Draft {
  const _Draft(
    this.shape, {
    required this.type,
    required this.actor,
    required this.text,
    this.lane,
    this.stage,
    this.attempt,
    this.verdict,
    this.reason,
    this.session,
    this.parentSession,
    this.decision,
    this.tasks,
    this.issueId,
    this.resolves,
    this.ready = false,
    this.resumed = false,
  });

  final _EventShape shape;
  final String type;
  final String actor;
  final String text;
  final String? lane;
  final String? stage;
  final int? attempt;
  final String? verdict;
  final String? reason;
  final String? session;
  final String? parentSession;
  final String? decision;
  final List<String>? tasks;
  final String? issueId;
  final String? resolves;
  final bool ready;
  final bool resumed;

  WorkflowEvent finalize({required int seq, required int step, required int offset}) => WorkflowEvent._(
    shape: shape,
    type: type,
    actor: actor,
    text: text,
    seq: seq,
    id: 'ev-${padZero(seq, 3)}',
    step: step,
    time: _clockFor(step, offset),
    lane: lane,
    stage: stage,
    attempt: attempt,
    verdict: verdict,
    reason: reason,
    session: session,
    parentSession: parentSession,
    decision: decision,
    tasks: tasks,
    issueId: issueId,
    resolves: resolves,
    ready: ready,
    resumed: resumed,
  );
}

_Draft _messageDraft(WorkflowMessage message) =>
    _Draft(_EventShape.message, type: 'message', actor: message.actor, text: message.text, decision: message.decision);

class WorkflowStep {
  const WorkflowStep({required this.index, required this.id, required this.phase, required this.events});

  final int index;
  final String id;
  final String phase;
  final List<WorkflowEvent> events;

  Map<String, Object?> toJson() => {
    'index': index,
    'id': id,
    'phase': phase,
    'events': [for (final event in events) event.toJson()],
  };
}

class TaskStepMarks {
  const TaskStepMarks({required this.split, required this.review, required this.freeze});

  final int split;
  final int review;
  final int freeze;

  Map<String, Object?> toJson() => {'split': split, 'review': review, 'freeze': freeze};
}

class ConversationMessage {
  const ConversationMessage({required this.id, required this.actor, required this.text, required this.decision, required this.time});

  final String id;
  final String actor;
  final String text;
  final String? decision;
  final String time;

  Map<String, Object?> toJson() => {'id': id, 'actor': actor, 'text': text, 'decision': decision, 'time': time};
}

class SpecState {
  const SpecState({required this.status, required this.content, required this.splitBy, required this.lanes});

  /// idle | written | frozen
  final String status;
  final SpecContent content;
  final String? splitBy;
  final List<LaneMeta> lanes;

  List<String> get scope => content.scope;
  List<String> get criteria => content.criteria;
  String? get axisNote => content.axisNote;

  Map<String, Object?> toJson() => {
    'status': status,
    'scope': [...scope],
    'criteria': [...criteria],
    if (axisNote != null) 'axisNote': axisNote,
    'splitBy': splitBy,
    'lanes': [
      for (final lane in lanes) {'key': lane.key, 'title': lane.title, 'owns': lane.owns},
    ],
  };
}

class PlannedTask {
  const PlannedTask({required this.lane, required this.terms});

  final LaneMeta lane;
  final TaskTerms terms;

  String get id => lane.id;
  String get key => lane.key;
  String get title => lane.title;
  String get owns => lane.owns;

  Map<String, Object?> toJson() => {
    'id': id,
    'key': key,
    'title': title,
    'owns': owns,
    'interface': terms.interface,
    'acceptance': terms.acceptance,
    'dependsOnUnfinished': <String>[],
  };
}

class TaskPlanState {
  const TaskPlanState({
    required this.status,
    required this.tasks,
    required this.checks,
    required this.sharedOwner,
    required this.approvedRound,
    required this.mergeOrder,
  });

  /// idle | proposed | approved | frozen
  final String status;
  final List<PlannedTask> tasks;
  final List<String> checks;
  final String? sharedOwner;
  final int? approvedRound;
  final List<String>? mergeOrder;

  Map<String, Object?> toJson() => {
    'status': status,
    'tasks': [for (final task in tasks) task.toJson()],
    'checks': [...checks],
    'sharedOwner': sharedOwner,
    'approvedRound': approvedRound,
    'mergeOrder': mergeOrder == null ? null : [...mergeOrder!],
  };
}

class LaneIssue {
  LaneIssue({required this.id, required this.status, required this.text, required this.occurrences, required this.attempts, this.resolvedBy});

  final String id;
  String status;
  String? text;
  int occurrences;
  final List<int> attempts;
  String? resolvedBy;

  LaneIssue copy() => LaneIssue(id: id, status: status, text: text, occurrences: occurrences, attempts: [...attempts], resolvedBy: resolvedBy);

  Map<String, Object?> toJson() => {
    'id': id,
    'status': status,
    'text': text,
    'occurrences': occurrences,
    'attempts': [...attempts],
    'resolvedBy': resolvedBy,
  };
}

class StageState {
  StageState(this.def);

  final LaneStageDef def;

  /// pending | done | returned
  String status = 'pending';
  int attempts = 0;
  int rejections = 0;
  bool isActive = false;

  String get id => def.id;
  String get label => def.label;

  Map<String, Object?> toJson() => {'id': id, 'label': label, 'status': status, 'attempts': attempts, 'rejections': rejections, 'isActive': isActive};
}

class ReturnConnector {
  const ReturnConnector({
    required this.from,
    required this.to,
    required this.reason,
    required this.attempt,
    required this.issueId,
    required this.eventId,
    required this.fresh,
  });

  final String from;
  final String to;
  final String? reason;
  final int attempt;
  final String? issueId;
  final String eventId;

  /// 되돌림이 막 일어난 단계(움직이는 표시는 이때 한 번만 재생).
  final bool fresh;

  Map<String, Object?> toJson() => {'from': from, 'to': to, 'reason': reason, 'attempt': attempt, 'issueId': issueId, 'eventId': eventId, 'fresh': fresh};
}

class ReturnRecord {
  ReturnRecord(this.connector, this.verdict);

  final ReturnConnector connector;
  final String? verdict;
  String? resolvedBy;
  int? resolvedAttempt;
  String? supersededBy;

  String get from => connector.from;
  String get to => connector.to;
  String? get reason => connector.reason;
  int get attempt => connector.attempt;
  String get eventId => connector.eventId;

  Map<String, Object?> toJson() => {
    ...connector.toJson(),
    'verdict': verdict,
    'resolvedBy': resolvedBy,
    'resolvedAttempt': resolvedAttempt,
    'supersededBy': supersededBy,
  };
}

class LineageChild {
  const LineageChild({required this.id, required this.parent, required this.runs});

  final String id;
  final String parent;
  final int runs;

  Map<String, Object?> toJson() => {'id': id, 'parent': parent, 'runs': runs};
}

class LaneLineage {
  const LaneLineage({required this.seeded, required this.seedReady, required this.children, required this.qaRuns});

  final bool seeded;
  final bool seedReady;
  final List<LineageChild> children;
  final int qaRuns;

  Map<String, Object?> toJson() => {
    'seeded': seeded,
    'seedReady': seedReady,
    'children': [for (final child in children) child.toJson()],
    'qaRuns': qaRuns,
  };
}

class LaneCurrent {
  const LaneCurrent({required this.stage, required this.attempt, required this.label});

  final String stage;
  final int attempt;
  final String label;

  Map<String, Object?> toJson() => {'stage': stage, 'attempt': attempt, 'label': label};
}

class LaneCounts {
  const LaneCounts({required this.planReview, required this.devReview, required this.qa});

  final int planReview;
  final int devReview;
  final int qa;

  Map<String, Object?> toJson() => {'planReview': planReview, 'devReview': devReview, 'qa': qa};
}

/// 한 레인의 현재 모습. status: queued | seeding | running | returned | ready | merged | done.
class LaneState {
  const LaneState({
    required this.meta,
    required this.status,
    required this.stages,
    required this.connector,
    required this.returns,
    required this.issues,
    required this.lineage,
    required this.readyAt,
    required this.current,
    required this.lastEvent,
    required this.counts,
  });

  final LaneMeta meta;
  final String status;
  final List<StageState> stages;
  final ReturnConnector? connector;
  final List<ReturnRecord> returns;
  final List<LaneIssue> issues;
  final LaneLineage lineage;
  final int? readyAt;
  final LaneCurrent? current;
  final WorkflowEvent? lastEvent;
  final LaneCounts counts;

  String get id => meta.id;
  String get key => meta.key;
  String get title => meta.title;
  String get owns => meta.owns;

  Map<String, Object?> toJson() => {
    ...meta.toJson(),
    'status': status,
    'stages': [for (final stage in stages) stage.toJson()],
    'connector': connector?.toJson(),
    'returns': [for (final item in returns) item.toJson()],
    'issues': [for (final issue in issues) issue.toJson()],
    'lineage': lineage.toJson(),
    'readyAt': readyAt,
    'current': current?.toJson(),
    'lastEvent': lastEvent?.toJson(),
    'counts': counts.toJson(),
  };
}

class MergeGateState {
  const MergeGateState({required this.status, required this.readyLanes, required this.waitingFor});

  /// locked | open | merged
  final String status;
  final List<String> readyLanes;
  final List<String> waitingFor;

  Map<String, Object?> toJson() => {
    'status': status,
    'readyLanes': [...readyLanes],
    'waitingFor': [...waitingFor],
  };
}

class IntegrationStepState {
  const IntegrationStepState({required this.step, required this.status, required this.isActive});

  final TailStep step;
  final String status;
  final bool isActive;

  String get id => step.id;
  String get label => step.label;
  String get text => step.text;

  Map<String, Object?> toJson() => {'id': id, 'label': label, 'text': text, 'status': status, 'isActive': isActive};
}

class DirectNodeState {
  const DirectNodeState({required this.node, required this.step, required this.status, required this.isActive});

  final DirectFlowNode node;
  final int step;
  final String status;
  final bool isActive;

  String get id => node.id;
  String get label => node.label;

  Map<String, Object?> toJson() => {'id': id, 'label': label, 'step': step, 'status': status, 'isActive': isActive};
}

class _Built {
  const _Built({
    required this.steps,
    required this.seeded,
    required this.dispatchStep,
    required this.specStep,
    required this.seedStep,
    required this.taskSteps,
    required this.lanes,
    required this.tail,
    required this.spec,
  });

  final List<WorkflowStep> steps;
  final bool seeded;
  final int dispatchStep;
  final int specStep;
  final int seedStep;
  final TaskStepMarks? taskSteps;
  final List<LaneMeta> lanes;
  final List<TailStep> tail;
  final SpecContent? spec;
}

/// 순차 레인 일정. 반려·실패는 옵션마다 한 번이며 다음 회차에서 통과한다.
List<LaneScriptItem> sequentialScript(WorkflowContent content, {required bool planReject, required bool qaFail}) {
  final t = content.sequentialText;
  final items = <LaneScriptItem>[];
  void push(String stage, String textKey, {String? verdict, String? reasonKey, String? issueId, String? resolves}) {
    items.add(
      LaneScriptItem(
        at: items.length,
        stage: stage,
        text: t[textKey]!,
        verdict: verdict,
        reason: reasonKey == null ? null : t[reasonKey]!,
        issueId: issueId,
        resolves: resolves,
      ),
    );
  }

  push('plan', 'plan');
  if (planReject) {
    push('plan-review', 'planRejected', verdict: 'rejected', reasonKey: 'planRejectReason');
    push('plan', 'planRevise');
    push('plan-review', 'planReApproved', verdict: 'approved');
  } else {
    push('plan-review', 'planApproved', verdict: 'approved');
  }
  push('dev', 'dev');
  push('dev-review', 'devApproved', verdict: 'approved');
  if (qaFail) {
    push('qa', 'qaFailed', verdict: 'failed', reasonKey: 'qaFailReason', issueId: 'QF-001');
    push('dev', 'devFix');
    push('dev-review', 'devReApproved', verdict: 'approved');
    push('qa', 'qaRePassed', verdict: 'passed', resolves: 'QF-001');
  } else {
    push('qa', 'qaPassed', verdict: 'passed');
  }
  return items;
}

/// 같은 옵션이면 같은 시나리오 객체를 돌려주는 엔진(원본 getScenario 의 캐시).
class WorkflowEngine {
  WorkflowEngine(this.content);

  final WorkflowContent content;
  final Map<String, WorkflowScenario> _cache = {};

  ScenarioOptions normalize({String? route, bool? seed, bool? planReject, bool? qaFail}) =>
      ScenarioOptions.normalize(content, route: route, seed: seed, planReject: planReject, qaFail: qaFail);

  WorkflowScenario scenario(ScenarioOptions options) => _cache.putIfAbsent(options.cacheKey, () => WorkflowScenario._(content, options));

  WorkflowScenario get defaultScenario => scenario(normalize());
}

class WorkflowScenario {
  WorkflowScenario._(this.content, this.options) : parallel = options.route == 'parallel' {
    final built = _buildSteps();
    _built = built;
    steps = built.steps;
    lanes = built.lanes;
    total = steps.length;
    mergeStep = steps.indexWhere((step) => step.events.any((event) => event.type == 'integration' && event.stage == 'merge'));
    final allEvents = [for (final step in steps) ...step.events];
    _stageEventsByLane = {
      for (final lane in lanes)
        lane.id: [
          for (final event in allEvents)
            if (event.lane == lane.id && event.stage != null) event,
        ],
    };
  }

  final WorkflowContent content;
  final ScenarioOptions options;
  final bool parallel;
  late final _Built _built;
  late final List<WorkflowStep> steps;
  late final List<LaneMeta> lanes;
  late final int total;
  late final int mergeStep;
  late final Map<String, List<WorkflowEvent>> _stageEventsByLane;

  bool get seeded => _built.seeded;
  int get dispatchStep => _built.dispatchStep;
  int get specStep => _built.specStep;
  int get seedStep => _built.seedStep;
  TaskStepMarks? get taskSteps => _built.taskSteps;
  List<TailStep> get tail => _built.tail;
  bool get isDirect => options.route == 'direct';

  // ── 단계 만들기 ─────────────────────────────────────────

  List<WorkflowStep> _finalize(List<(String, List<_Draft>)> drafts) {
    var seq = 0;
    final out = <WorkflowStep>[];
    for (final (index, (phase, events)) in drafts.indexed) {
      final finalized = <WorkflowEvent>[];
      for (final (offset, draft) in events.indexed) {
        seq += 1;
        finalized.add(draft.finalize(seq: seq, step: index, offset: offset));
      }
      out.add(WorkflowStep(index: index, id: 'detail-${index + 1}', phase: phase, events: List.unmodifiable(finalized)));
    }
    return List.unmodifiable(out);
  }

  // AI-NOTE: 직접 처리: 요청 → Master 직접 처리 → 응답 세 단계. 명세·배정·Seed·레인·통합이 없어 해당 단계 번호는 -1 이다.
  _Built _buildDirect() {
    final drafts = <(String, List<_Draft>)>[
      for (final message in content.directIntake) ('intake', [_messageDraft(message)]),
      ('direct', [_Draft(_EventShape.direct, type: 'direct', actor: 'master', stage: 'direct', text: content.directWorkText)]),
      for (final message in content.directClosing) ('closing', [_messageDraft(message)]),
    ];
    return _Built(
      steps: _finalize(drafts),
      seeded: false,
      dispatchStep: -1,
      specStep: -1,
      seedStep: -1,
      taskSteps: null,
      lanes: const [],
      tail: const [],
      spec: null,
    );
  }

  // 병렬 Task Planning 이벤트. 레인 id 는 계약 안 작업 목록(tasks)에만 있고 이벤트의 lane 은 비워 둔다(레인은 아직 배정 전).
  List<List<_Draft>> _taskPlanningDrafts(List<LaneMeta> lanes) {
    final t = content.taskPlanning.texts;
    final laneIds = [for (final lane in lanes) lane.id];
    return [
      [_Draft(_EventShape.task, type: 'task', actor: 'task-author', stage: 'task-split', session: 'task-planning-author', tasks: laneIds, text: t['split']!)],
      [
        _Draft(
          _EventShape.task,
          type: 'task',
          actor: 'task-reviewer',
          stage: 'task-review',
          session: 'task-planning-reviewer',
          verdict: 'approved',
          attempt: 1,
          text: t['review']!,
        ),
      ],
      [_Draft(_EventShape.task, type: 'task', actor: 'master', stage: 'task-freeze', tasks: laneIds, text: t['freeze']!)],
    ];
  }

  _Built _buildSteps() {
    if (options.route == 'direct') return _buildDirect();
    final lanes = parallel ? content.detailLanes : [content.sequentialLane];
    final scripts = parallel
        ? content.laneScripts
        : {content.sequentialLane.id: sequentialScript(content, planReject: options.planReject, qaFail: options.qaFail)};
    final intake = parallel ? content.intakeMessages : content.sequentialIntake;
    final tail = parallel ? content.integrationSteps : content.sequentialTail;
    final closing = parallel ? content.closingMessages : content.sequentialClosing;
    final seeded = parallel || options.seed;

    final drafts = <(String, List<_Draft>)>[];

    // Master 가 요청을 해석해 WORK SPEC 을 쓴 뒤에야 지시·배정 메시지를 보낸다.
    // 병렬은 그 사이에 전체 Task Planning(제안 → 검토 승인 → 동결)을 거친다. 순차는 하나의 의존 작업축이라 이 단계가 없다.
    var specStep = -1;
    TaskStepMarks? taskSteps;
    for (final message in intake) {
      if (message.decision == 'dispatch') {
        specStep = drafts.length;
        drafts.add((
          'spec',
          [_Draft(_EventShape.spec, type: 'spec', actor: 'master', text: parallel ? 'WORK SPEC 작성: 요청 범위·완료 기준' : 'WORK SPEC 작성: 범위·완료 기준·작업축 1개·소유 경로')],
        ));
        if (parallel) {
          final marks = <int>[];
          for (final events in _taskPlanningDrafts(lanes)) {
            marks.add(drafts.length);
            drafts.add(('task', events));
          }
          taskSteps = TaskStepMarks(split: marks[0], review: marks[1], freeze: marks[2]);
        }
      }
      drafts.add(('intake', [_messageDraft(message)]));
    }
    final dispatchStep = drafts.length - 1;

    var seedStep = -1;
    if (seeded) {
      seedStep = drafts.length;
      drafts.add((
        'seed',
        [
          for (final lane in lanes) ...[
            _Draft(_EventShape.seed, type: 'seed', actor: 'seed', lane: lane.id, session: 'author-seed', text: 'Author Seed 준비(읽기 전용)'),
            _Draft(_EventShape.seed, type: 'seed', actor: 'seed', lane: lane.id, session: 'reviewer-seed', text: 'Reviewer Seed 준비(읽기 전용)'),
          ],
        ],
      ));
    }

    final laneTicks =
        [
          for (final items in scripts.values)
            for (final item in items) item.at,
        ].reduce((a, b) => a > b ? a : b) +
        1;
    final attempts = <String, int>{};
    for (var tick = 0; tick < laneTicks; tick += 1) {
      final events = <_Draft>[];
      for (final lane in lanes) {
        for (final item in scripts[lane.id]!.where((entry) => entry.at == tick)) {
          final key = '${lane.id}:${item.stage}';
          final attempt = (attempts[key] ?? 0) + 1;
          attempts[key] = attempt;
          final session = sessionForStage[item.stage]!;
          events.add(
            _Draft(
              _EventShape.lane,
              type: item.verdict != null ? 'verdict' : 'author',
              actor: item.stage.endsWith('review') ? 'reviewer' : (item.stage == 'qa' ? 'qa' : 'author'),
              lane: lane.id,
              stage: item.stage,
              attempt: attempt,
              verdict: item.verdict,
              reason: item.reason,
              issueId: item.issueId,
              resolves: item.resolves,
              ready: item.stage == 'qa' && item.verdict == 'passed',
              session: session,
              parentSession: seeded ? seedParent[session] : null,
              // 같은 단계의 두 번째 이후 실행은 같은 세션을 resume 한다(독립 QA 도 같은 레인 QA 세션을 resume).
              resumed: attempt > 1,
              text: item.text,
            ),
          );
        }
      }
      drafts.add(('lanes', events));
    }

    for (final item in tail) {
      drafts.add((
        'integration',
        [
          _Draft(
            _EventShape.integration,
            type: 'integration',
            actor: 'integration',
            stage: item.id,
            text: item.text,
            session: item.id == 'wiki' ? 'wiki' : null,
          ),
        ],
      ));
    }
    for (final message in closing) {
      drafts.add(('closing', [_messageDraft(message)]));
    }

    return _Built(
      steps: _finalize(drafts),
      seeded: seeded,
      dispatchStep: dispatchStep,
      specStep: specStep,
      seedStep: seedStep,
      taskSteps: taskSteps,
      lanes: lanes,
      tail: tail,
      spec: parallel ? content.parallelSpec : content.sequentialSpec,
    );
  }

  // ── 커서 도우미 ─────────────────────────────────────────

  /// 원본 clamp: Math.min(Math.max(0, Math.trunc(cursor) || 0), total).
  int clamp(num cursor) {
    if (cursor.isNaN) return 0;
    if (cursor.isInfinite) return cursor > 0 ? total : 0;
    final value = cursor.truncate();
    return value < 0 ? 0 : (value > total ? total : value);
  }

  List<WorkflowEvent> eventsUpTo(num cursor) => [for (final step in steps.take(clamp(cursor))) ...step.events];

  bool isDispatched(num cursor) => clamp(cursor) > dispatchStep;

  String laneKey(String laneId) {
    for (final lane in lanes) {
      if (lane.id == laneId) return lane.key;
    }
    return laneId;
  }

  // ── 파생 ───────────────────────────────────────────────

  List<ConversationMessage> deriveConversation(num cursor) => [
    for (final event in eventsUpTo(cursor))
      if (event.type == 'message') ConversationMessage(id: event.id, actor: event.actor, text: event.text, decision: event.decision, time: event.time),
  ];

  // WORK SPEC 카드. 작성 단계 전에는 idle, 작성 후 written, 지시 배정 후 frozen.
  // 병렬 명세는 레인을 정하지 않는다(lanes 빈 배열, splitBy: "task-planning"). 작업축별 소유 경로는 deriveTaskPlan 에 있다.
  SpecState? deriveSpec(num cursor) {
    final spec = _built.spec;
    if (spec == null) return null;
    final at = clamp(cursor);
    var status = 'idle';
    if (at > dispatchStep) {
      status = 'frozen';
    } else if (at > specStep) {
      status = 'written';
    }
    return SpecState(status: status, content: spec, splitBy: parallel ? 'task-planning' : null, lanes: parallel ? const [] : lanes);
  }

  // 전체 Task Planning 카드(병렬만, 그 외 null). status: idle → proposed → approved → frozen.
  // 검토 승인 전에는 checks 가 비어 있고, 동결 전에는 mergeOrder 가 null 이다(되감으면 미래의 승인·동결이 남지 않음).
  TaskPlanState? deriveTaskPlan(num cursor) {
    final marks = taskSteps;
    if (marks == null) return null;
    final at = clamp(cursor);
    var status = 'idle';
    if (at > marks.freeze) {
      status = 'frozen';
    } else if (at > marks.review) {
      status = 'approved';
    } else if (at > marks.split) {
      status = 'proposed';
    }
    final reviewed = status == 'approved' || status == 'frozen';
    final planning = content.taskPlanning;
    return TaskPlanState(
      status: status,
      tasks: status == 'idle' ? const [] : [for (final lane in lanes) PlannedTask(lane: lane, terms: planning.tasks[lane.id]!)],
      checks: reviewed ? [...planning.checks] : const [],
      sharedOwner: reviewed ? planning.sharedOwner : null,
      approvedRound: reviewed ? 1 : null,
      mergeOrder: status == 'frozen' ? [...content.mergeOrder] : null,
    );
  }

  // 레인별 QA 지적 원장. 같은 지적 번호가 다시 실패하면 새 항목 없이 그 항목의 재현 횟수만 늘린다.
  // 해결은 독립 QA 통과(resolves)로만 바뀐다(작성자 자기 선언으로 닫지 않음).
  List<LaneIssue> deriveIssues(String laneId, num cursor) {
    final issues = <LaneIssue>[];
    for (final event in eventsUpTo(cursor)) {
      if (event.lane != laneId || event.stage != 'qa') continue;
      if (event.issueId != null) {
        final found = issues.where((issue) => issue.id == event.issueId).firstOrNull;
        if (found != null) {
          found.occurrences += 1;
          found.status = 'open';
          found.text = event.reason;
          found.attempts.add(event.attempt!);
        } else {
          issues.add(LaneIssue(id: event.issueId!, status: 'open', text: event.reason, occurrences: 1, attempts: [event.attempt!]));
        }
      }
      if (event.resolves != null) {
        for (final issue in issues) {
          if (issue.id == event.resolves) {
            issue.status = 'resolved';
            issue.resolvedBy = 'qa:${event.attempt}';
          }
        }
      }
    }
    return [for (final issue in issues) issue.copy()];
  }

  // 레인의 세션 계보. seeded 는 실제 Seed 유무(병렬은 항상), 패널 표시 여부는 화면이 options.seed 로 정한다.
  LaneLineage _deriveLineage(List<WorkflowEvent> seen, int at) {
    int runs(String session) => seen.where((event) => event.session == session).length;
    return LaneLineage(
      seeded: seeded,
      seedReady: seeded && at > seedStep,
      children: [for (final id in seedChildren) LineageChild(id: id, parent: seedParent[id]!, runs: runs(id))],
      qaRuns: runs('qa'),
    );
  }

  // 한 레인의 현재 모습. stages 의 status: pending | done | returned, isActive 는 지금 진행 중인 단계.
  LaneState deriveLane(String laneId, num cursor) {
    final at = clamp(cursor);
    final meta = lanes.firstWhere((lane) => lane.id == laneId);
    final all = _stageEventsByLane[laneId]!;
    final seen = [
      for (final event in all)
        if (event.step < at) event,
    ];
    final upcoming = all.where((event) => event.step >= at).firstOrNull;
    final dispatched = isDispatched(at);
    final seeding = seeded && at <= seedStep;
    final stages = [for (final stage in laneStages) StageState(stage)];
    final byId = {for (final stage in stages) stage.id: stage};
    final returns = <ReturnRecord>[];
    ReturnConnector? connector;
    var ready = false;

    for (final event in seen) {
      final stage = byId[event.stage]!;
      stage.attempts = event.attempt!;
      if (event.type == 'author') {
        stage.status = 'done';
        continue;
      }
      if (event.verdict == 'approved' || event.verdict == 'passed') {
        stage.status = 'done';
        // 같은 검수·QA 단계가 최종 승인·통과하면 그 단계의 미해결 되돌림을 모두 해결로 남긴다(각 사유·회차 보존).
        for (final item in returns) {
          if (item.from == event.stage && item.resolvedBy == null) {
            item.resolvedBy = event.id;
            item.resolvedAttempt = event.attempt;
          }
        }
        if (connector != null && connector.from == event.stage) connector = null;
      } else {
        stage.status = 'returned';
        stage.rejections += 1;
        // 같은 단계에서 다시 반려·실패하면 앞 되돌림은 "다시 반려됨"으로 남기고 새 되돌림이 이어진다.
        if (connector != null && connector.from == event.stage) returns.last.supersededBy = event.id;
        final next = ReturnConnector(
          from: event.stage!,
          to: returnTarget[event.stage]!,
          reason: event.reason,
          attempt: event.attempt!,
          issueId: event.issueId,
          eventId: event.id,
          fresh: event.step == at - 1,
        );
        connector = next;
        returns.add(ReturnRecord(next, event.verdict));
        // 되돌아간 뒤에는 대상 단계부터 다시 거치므로 그 사이 단계 표시도 다시 대기로 돌린다.
        final fromIndex = laneStages.indexWhere((item) => item.id == event.stage);
        final toIndex = laneStages.indexWhere((item) => item.id == next.to);
        for (var index = toIndex; index < fromIndex; index += 1) {
          stages[index].status = 'pending';
        }
      }
      if (event.ready) ready = true;
    }

    final live = dispatched && !seeding;
    if (ready) byId['ready']!.status = 'done';
    if (live && upcoming != null) byId[upcoming.stage]!.isActive = true;

    final merged = mergeStep != -1 && at > mergeStep;
    var status = 'running';
    if (!dispatched) {
      status = 'queued';
    } else if (seeding) {
      status = 'seeding';
    } else if (ready && !parallel) {
      status = 'done';
    } else if (merged && ready) {
      status = 'merged';
    } else if (ready) {
      status = 'ready';
    } else if (connector != null) {
      status = 'returned';
    }

    return LaneState(
      meta: meta,
      status: status,
      stages: stages,
      connector: connector,
      returns: returns,
      issues: deriveIssues(laneId, at),
      lineage: _deriveLineage(seen, at),
      readyAt: all.where((event) => event.ready).firstOrNull?.step,
      current: upcoming != null && live ? LaneCurrent(stage: upcoming.stage!, attempt: upcoming.attempt!, label: stageLabel(upcoming.stage!)) : null,
      lastEvent: seen.lastOrNull,
      counts: LaneCounts(planReview: byId['plan-review']!.attempts, devReview: byId['dev-review']!.attempts, qa: byId['qa']!.attempts),
    );
  }

  List<LaneState> deriveLanes(num cursor) => [for (final lane in lanes) deriveLane(lane.id, cursor)];

  // AI-NOTE: 병합 게이트는 병렬에만 있다. 모든 레인이 QA 를 통과(ready)해야 열리고, 먼저 끝난 레인은 READY 로 기다린다.
  MergeGateState? deriveMergeGate(num cursor) {
    if (!parallel) return null;
    final current = deriveLanes(cursor);
    final readyLanes = [
      for (final lane in current)
        if (lane.status == 'ready' || lane.status == 'merged') lane.key,
    ];
    final waitingFor = [
      for (final lane in current)
        if (!readyLanes.contains(lane.key)) lane.key,
    ];
    var status = 'locked';
    if (clamp(cursor) > mergeStep) {
      status = 'merged';
    } else if (waitingFor.isEmpty) {
      status = 'open';
    }
    return MergeGateState(status: status, readyLanes: readyLanes, waitingFor: waitingFor);
  }

  List<IntegrationStepState> deriveIntegration(num cursor) {
    final at = clamp(cursor);
    final done = {
      for (final event in eventsUpTo(at))
        if (event.type == 'integration') event.stage,
    };
    final next = at < steps.length ? steps[at].events.where((event) => event.type == 'integration').firstOrNull?.stage : null;
    return [for (final item in tail) IntegrationStepState(step: item, status: done.contains(item.id) ? 'done' : 'pending', isActive: item.id == next)];
  }

  // 직접 처리 흐름 노드(요청·직접 처리·응답). 노드 i 는 단계 i 에 대응한다. 다른 경로는 빈 배열.
  List<DirectNodeState> deriveDirect(num cursor) {
    if (!isDirect) return const [];
    final at = clamp(cursor);
    return [
      for (final (index, node) in content.directFlow.indexed)
        DirectNodeState(node: node, step: index, status: index < at ? 'done' : 'pending', isActive: index == at),
    ];
  }

  String describeEvent(WorkflowEvent event) {
    if (event.type == 'message') return '${event.actor == 'human' ? '사람' : 'Master AI'}: ${event.text}';
    if (event.type == 'spec' || event.type == 'task' || event.type == 'integration' || event.type == 'direct') return event.text;
    if (event.type == 'seed') return '${laneKey(event.lane!)} ${event.text}';
    final head = '${laneKey(event.lane!)} ${stageLabel(event.stage!)} ${event.attempt}회차';
    if (event.verdict != null) return '$head ${verdictLabel[event.verdict]}${event.reason != null ? ' — ${event.reason}' : ''}';
    return '$head — ${event.text}';
  }

  // 진행 문구. 자동 재생 중에는 명세·Seed·반려·실패·READY·병합처럼 눈에 띄는 단계만 알린다.
  String stepAnnouncement(num cursor, {bool manual = false}) {
    final at = clamp(cursor);
    if (at == 0) return '';
    final events = steps[at - 1].events;
    final notable = <WorkflowEvent>[
      for (final event in events)
        if (event.type == 'spec' ||
            event.type == 'task' ||
            event.type == 'direct' ||
            event.isFault ||
            event.ready ||
            event.stage == 'merge' ||
            event.stage == 'final-merge')
          event,
    ];
    if (events.first.type == 'seed') {
      notable.add(
        const WorkflowEvent._(
          shape: _EventShape.synthetic,
          type: 'spec',
          actor: 'master',
          text: '레인별 Author·Reviewer Seed 준비',
          seq: 0,
          id: '',
          step: 0,
          time: '',
        ),
      );
    }
    final picked = manual ? events : notable;
    final texts = [for (final event in picked) describeEvent(event)];
    if (at == total) texts.add('전체 진행 완료');
    if (texts.isEmpty) return '';
    return '$at단계, ${texts.join(' · ')}';
  }

  String describeStep(num cursor) {
    final at = clamp(cursor);
    if (at == 0) return '시작 전';
    final step = steps[at - 1];
    switch (step.phase) {
      case 'spec':
        return 'WORK SPEC 작성';
      case 'task':
        return 'Task Planning';
      case 'seed':
        return 'Seed 준비';
      case 'direct':
        return 'Master AI 직접 처리';
      case 'intake':
        return at - 1 == dispatchStep ? '지시 배정' : '요청 접수';
      case 'lanes':
        return parallel ? '레인 병렬 진행' : '단계 진행';
      case 'integration':
        return parallel ? '통합' : 'Wiki';
    }
    return at == total ? '완료' : '결과 보고';
  }

  bool canMerge(num cursor) {
    final gate = deriveMergeGate(cursor);
    return gate != null && gate.waitingFor.isEmpty;
  }

  Map<String, Object?> toJson() => {
    'options': options.toJson(),
    'parallel': parallel,
    'seeded': seeded,
    'lanes': [for (final lane in lanes) lane.toJson()],
    'steps': [for (final step in steps) step.toJson()],
    'total': total,
    'dispatchStep': dispatchStep,
    'specStep': specStep,
    'seedStep': seedStep,
    'taskSteps': taskSteps?.toJson(),
    'mergeStep': mergeStep,
  };
}
