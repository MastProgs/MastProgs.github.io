// /workflow 상세 페이지의 문구·예시 데이터(assets/data/workflowDetail.json = React src/content/workflowDetail.js).
// AI-NOTE: 요청·레인·대화·기록은 모두 예시 데이터(사내 요청 대시보드)다. 실제 사용자 로그를 옮기지 않고,
// 방문자 디스크 쓰기·AI 호출·외부 API·저장을 하지 않는다. 화면 문구에 데모 안내 문구나 "(설명용)" 꼬리표를 넣지 않는다.
// 이 파일은 JSON 을 형 있는 값으로 옮기기만 한다(값 변경 없음). 순수 모델(workflow_scenario.dart)이 이 값을 받는다.
import '../../../core/json.dart';

class WorkflowMessage {
  const WorkflowMessage({required this.actor, required this.text, this.decision});

  factory WorkflowMessage.fromJson(Json json) => WorkflowMessage(actor: json.str('actor'), text: json.str('text'), decision: json.strOrNull('decision'));

  final String actor;
  final String text;
  final String? decision;
}

class LaneMeta {
  const LaneMeta({required this.id, required this.key, required this.title, required this.owns});

  factory LaneMeta.fromJson(Json json) => LaneMeta(id: json.str('id'), key: json.str('key'), title: json.str('title'), owns: json.str('owns'));

  final String id;
  final String key;
  final String title;
  final String owns;

  Json toJson() => {'id': id, 'key': key, 'title': title, 'owns': owns};
}

/// 레인 일정 한 줄(at = 배정·Seed 이후 레인 틱).
class LaneScriptItem {
  const LaneScriptItem({required this.at, required this.stage, required this.text, this.verdict, this.reason, this.issueId, this.resolves});

  factory LaneScriptItem.fromJson(Json json) => LaneScriptItem(
    at: json.integer('at'),
    stage: json.str('stage'),
    text: json.str('text'),
    verdict: json.strOrNull('verdict'),
    reason: json.strOrNull('reason'),
    issueId: json.strOrNull('issueId'),
    resolves: json.strOrNull('resolves'),
  );

  final int at;
  final String stage;
  final String text;
  final String? verdict;
  final String? reason;
  final String? issueId;
  final String? resolves;
}

/// 통합·Wiki 단계(병렬 INTEGRATION_STEPS, 순차 SEQUENTIAL_TAIL).
class TailStep {
  const TailStep({required this.id, required this.label, required this.text});

  factory TailStep.fromJson(Json json) => TailStep(id: json.str('id'), label: json.str('label'), text: json.str('text'));

  final String id;
  final String label;
  final String text;
}

class SpecContent {
  const SpecContent({required this.scope, required this.criteria, this.axisNote});

  factory SpecContent.fromJson(Json json) =>
      SpecContent(scope: json.strings('scope'), criteria: json.strings('criteria'), axisNote: json.strOrNull('axisNote'));

  final List<String> scope;
  final List<String> criteria;
  final String? axisNote;
}

class TaskPlanningStep {
  const TaskPlanningStep({required this.id, required this.label, required this.actor});

  final String id;
  final String label;
  final String actor;
}

class TaskTerms {
  const TaskTerms({required this.interface, required this.acceptance});

  final String interface;
  final String acceptance;
}

class TaskPlanningContent {
  TaskPlanningContent.fromJson(Json json)
    : heading = json.str('heading'),
      lead = json.str('lead'),
      steps = [for (final step in json.objs('steps')) TaskPlanningStep(id: step.str('id'), label: step.str('label'), actor: step.str('actor'))],
      source = json.str('source'),
      noDependency = json.str('noDependency'),
      tasks = json
          .obj('tasks')
          .map((id, value) => MapEntry(id, TaskTerms(interface: asJson(value).str('interface'), acceptance: asJson(value).str('acceptance')))),
      checks = json.strings('checks'),
      sharedOwner = json.str('sharedOwner'),
      texts = json.texts('texts'),
      status = json.texts('status');

  final String heading;
  final String lead;
  final List<TaskPlanningStep> steps;
  final String source;
  final String noDependency;
  final Map<String, TaskTerms> tasks;
  final List<String> checks;
  final String sharedOwner;
  final Map<String, String> texts;
  final Map<String, String> status;
}

class ScenarioOptionDef {
  const ScenarioOptionDef({required this.id, required this.label, required this.routes});

  final String id;
  final String label;
  final List<String> routes;
}

class SpeedOption {
  const SpeedOption({required this.value, required this.label});

  final double value;
  final String label;
}

class DirectFlowNode {
  const DirectFlowNode({required this.id, required this.label});

  final String id;
  final String label;
}

/// workflowDetail.json 전체.
class WorkflowContent {
  WorkflowContent.fromJson(Json json)
    : detailRoute = json.str('DETAIL_ROUTE'),
      copy = json.texts('DETAIL_COPY'),
      intro = json.obj('DETAIL_COPY').strings('intro'),
      speedOptions = [for (final option in json.objs('SPEED_OPTIONS')) SpeedOption(value: option.number('value'), label: option.str('label'))],
      directIntake = [for (final m in json.objs('DIRECT_INTAKE')) WorkflowMessage.fromJson(m)],
      directWorkText = json.obj('DIRECT_WORK').str('text'),
      directWorkOwns = json.obj('DIRECT_WORK').str('owns'),
      directClosing = [for (final m in json.objs('DIRECT_CLOSING')) WorkflowMessage.fromJson(m)],
      directFlow = [for (final node in json.objs('DIRECT_FLOW')) DirectFlowNode(id: node.str('id'), label: node.str('label'))],
      actorLabel = json.texts('ACTOR_LABEL'),
      scenarioOptions = [
        for (final option in json.objs('SCENARIO_OPTIONS'))
          ScenarioOptionDef(id: option.str('id'), label: option.str('label'), routes: option.strings('routes')),
      ],
      defaultScenario = json.obj('DEFAULT_SCENARIO'),
      optionHint = json.texts('OPTION_HINT'),
      specCopy = json.texts('SPEC_COPY'),
      seedCopy = json.obj('SEED_COPY'),
      intakeMessages = [for (final m in json.objs('INTAKE_MESSAGES')) WorkflowMessage.fromJson(m)],
      mergeOrder = json.strings('MERGE_ORDER'),
      parallelSpec = SpecContent.fromJson(json.obj('PARALLEL_SPEC')),
      taskPlanning = TaskPlanningContent.fromJson(json.obj('TASK_PLANNING')),
      sequentialIntake = [for (final m in json.objs('SEQUENTIAL_INTAKE')) WorkflowMessage.fromJson(m)],
      sequentialSpec = SpecContent.fromJson(json.obj('SEQUENTIAL_SPEC')),
      sequentialLane = LaneMeta.fromJson(json.obj('SEQUENTIAL_LANE')),
      sequentialClosing = [for (final m in json.objs('SEQUENTIAL_CLOSING')) WorkflowMessage.fromJson(m)],
      sequentialText = json.texts('SEQUENTIAL_TEXT'),
      sequentialTail = [for (final step in json.objs('SEQUENTIAL_TAIL')) TailStep.fromJson(step)],
      closingMessages = [for (final m in json.objs('CLOSING_MESSAGES')) WorkflowMessage.fromJson(m)],
      detailLanes = [for (final lane in json.objs('DETAIL_LANES')) LaneMeta.fromJson(lane)],
      laneScripts = json.obj('LANE_SCRIPTS').map((laneId, items) => MapEntry(laneId, [for (final item in asJsonList(items)) LaneScriptItem.fromJson(item)])),
      returnTargetLabel = json.texts('RETURN_TARGET_LABEL'),
      integrationSteps = [for (final step in json.objs('INTEGRATION_STEPS')) TailStep.fromJson(step)],
      recordRoot = json.str('RECORD_ROOT'),
      sequentialRecordRoot = json.str('SEQUENTIAL_RECORD_ROOT'),
      directRecordRoot = json.str('DIRECT_RECORD_ROOT');

  final String detailRoute;
  final Map<String, String> copy;
  final List<String> intro;
  final List<SpeedOption> speedOptions;
  final List<WorkflowMessage> directIntake;
  final String directWorkText;
  final String directWorkOwns;
  final List<WorkflowMessage> directClosing;
  final List<DirectFlowNode> directFlow;
  final Map<String, String> actorLabel;
  final List<ScenarioOptionDef> scenarioOptions;
  final Json defaultScenario;
  final Map<String, String> optionHint;
  final Map<String, String> specCopy;
  final Json seedCopy;
  final List<WorkflowMessage> intakeMessages;
  final List<String> mergeOrder;
  final SpecContent parallelSpec;
  final TaskPlanningContent taskPlanning;
  final List<WorkflowMessage> sequentialIntake;
  final SpecContent sequentialSpec;
  final LaneMeta sequentialLane;
  final List<WorkflowMessage> sequentialClosing;
  final Map<String, String> sequentialText;
  final List<TailStep> sequentialTail;
  final List<WorkflowMessage> closingMessages;
  final List<LaneMeta> detailLanes;
  final Map<String, List<LaneScriptItem>> laneScripts;
  final Map<String, String> returnTargetLabel;
  final List<TailStep> integrationSteps;
  final String recordRoot;
  final String sequentialRecordRoot;
  final String directRecordRoot;

  bool defaultOption(String key) => defaultScenario[key] as bool;

  String get defaultRoute => defaultScenario['route'] as String;
}
