// 로컬 실행 기록 예시(React src/workflow-detail/records.js 이식). cursor 까지 적용된 이벤트에서 파일 목록과 내용을 매번 새로 만든다
// (저장·디스크 쓰기 없음).
// AI-NOTE: 구성은 AgentWorkflow 문서 기준이다. 실행 폴더 ai-log/YYYYMMDD/001_HHMMSS_title 아래에
// index.md(요청·탐색), current.md(최신 상태·결정·다음), ledger.md(시간순 교환·게이트), timeline.md·decisions.md(최신순),
// events.jsonl(시간순), state.json(coordinator 직렬 checkpoint), 00-request/{work-spec.md, task-planning/(병렬: 제안·검토 라운드),
// task-contract.json·md(병렬: 승인 후 동결)}, 03-lanes/<lane>/{00-request, sessions,01-planning,02-development,03-qa,04-completed},
// 04-integration/{planning,merge,implementation,build,qa}, 05-wiki, raw/invocations/<id>.
// 순차는 레인 폴더 없이 실행 폴더 바로 아래 01-planning 등을 쓴다. 직접 처리는 00-request/request.md 와 01-direct 만 만든다.
// 기획 심사는 라운드 JSON 을 모두 남기고 승인본만 Markdown 을 만든다. QA 는 attempt-NNN/result.json·result.md,
// issue-ledger.json/md 는 deriveIssues 에서 파생되는 읽기 전용 원장이며 같은 지적은 한 항목으로 갱신되고 독립 QA 통과로만 해결된다.
// 파일 내용 문자열(JSON 들여쓰기·키 순서 포함)은 원본과 한 글자도 다르지 않아야 한다(test/fixtures 차등 비교).
import '../../../core/js_compat.dart';
import 'workflow_scenario.dart';

class RecordFile {
  const RecordFile(this.path, this.content);

  final String path;
  final String content;

  Map<String, Object?> toJson() => {'path': path, 'content': content};
}

class WorkflowRecords {
  const WorkflowRecords({required this.root, required this.files, required this.latestPath});

  final String root;
  final List<RecordFile> files;
  final String? latestPath;

  RecordFile? fileAt(String? path) => path == null ? null : files.where((file) => file.path == path).firstOrNull;

  Map<String, Object?> toJson() => {
    'root': root,
    'files': [for (final file in files) file.toJson()],
    'latestPath': latestPath,
  };
}

String _pad3(int value) => padZero(value, 3);

const Set<String> _seededSessions = {'plan-author', 'dev-author', 'plan-reviewer', 'dev-reviewer'};

const Map<String, String> _laneStatusText = {
  'queued': '배정 대기',
  'seeding': 'Seed 준비',
  'running': '진행 중',
  'returned': '되돌림',
  'ready': 'QA 통과 · 병합 대기',
  'merged': '병합됨',
  'done': '완료',
};

const List<String> _rootOrder = ['index.md', 'current.md', 'ledger.md', 'timeline.md', 'decisions.md', 'events.jsonl', 'state.json'];

class _Context {
  _Context(this.events);

  final List<WorkflowEvent> events;
  final Map<String, int> attempts = {};
  final Map<String, List<String>> seeds = {};
  final Map<String, Map<String, int>> runs = {};
  final List<String> readyOrder = [];
}

class _RecordBuilder {
  _RecordBuilder(this.scenario);

  final WorkflowScenario scenario;

  String laneDir(String laneId) => scenario.parallel ? '03-lanes/$laneId/' : '';

  String laneOwns(String laneId) => scenario.lanes.firstWhere((lane) => lane.id == laneId).owns;

  // 원문 호출 기록을 남기는 이벤트: 반려·실패와 그 해결 시도(같은 단계의 바로 다음 회차).
  bool isRawEvent(WorkflowEvent event, List<WorkflowEvent> events) {
    if (event.isFault) return true;
    if (event.verdict == null) return false;
    final previous = events.where((item) => item.lane == event.lane && item.stage == event.stage && item.seq < event.seq).lastOrNull;
    return previous != null && previous.isFault;
  }

  String invocationId(WorkflowEvent event) => '${_pad3(event.seq)}-${event.lane}-${event.stage}-${event.attempt}';

  List<RecordFile> rawFiles(WorkflowEvent event) {
    final id = invocationId(event);
    final base = 'raw/invocations/$id';
    final role = event.stage == 'qa' ? '독립 QA' : '${stageLabel(event.stage!)} 검토';
    final target = event.stage == 'plan-review' ? '계획 라운드 JSON' : (event.stage == 'dev-review' ? '실제 diff' : '실행 중인 결과물');
    return [
      RecordFile(
        '$base/prompt.md',
        '# $role 요청 (${scenario.laneKey(event.lane!)} · ${event.attempt}회차)\n\n- 작업 명세: 00-request/work-spec.md\n- 검토 대상: $target\n- 응답 형식: verdict(APPROVED|REJECTED|PASSED|FAILED), reasons[]\n',
      ),
      RecordFile(
        '$base/command.json',
        jsonPretty({
          'invocation': id,
          'lane': event.lane,
          'stage': event.stage,
          'attempt': event.attempt,
          'session': event.session,
          'resumed': event.resumed,
          'stdin': 'prompt.md',
          'readOnly': true,
        }),
      ),
      RecordFile(
        '$base/stdout.txt',
        '${jsonCompact({
          'verdict': event.verdict!.toUpperCase(),
          'reasons': event.reason != null ? [event.reason] : <String>[],
          'summary': event.text,
        })}\n',
      ),
      RecordFile('$base/stderr.txt', ''),
    ];
  }

  Map<String, Object?> lineageFor(String laneId, _Context context) {
    final runs = context.runs[laneId] ?? const <String, int>{};
    Map<String, Object?> child(String id, String parent) {
      final count = runs[id] ?? 0;
      return {'id': id, 'parent': parent, 'mode': count > 0 ? 'fork' : 'pending', 'resumes': count - 1 > 0 ? count - 1 : 0};
    }

    return {
      'seeds': [
        for (final id in context.seeds[laneId] ?? const <String>[]) {'id': id, 'readOnly': true, 'outputs': <String>[]},
      ],
      'children': [
        child('plan-author', 'author-seed'),
        child('dev-author', 'author-seed'),
        child('plan-reviewer', 'reviewer-seed'),
        child('dev-reviewer', 'reviewer-seed'),
      ],
      'independent': ['qa', 'wiki'],
    };
  }

  String _list(List<String> lines) => lines.map((line) => '- $line').join('\n');

  // 이벤트 하나가 직접 만들거나 고치는 파일.
  List<RecordFile> filesForEvent(WorkflowEvent event, _Context context) {
    final files = <RecordFile>[];
    final content = scenario.content;
    if (event.type == 'message' && event.seq == 1) {
      files.add(RecordFile('00-request/request.md', '# 요청 원문\n\n${event.text}\n'));
    }
    // 범위 질문은 사람에게 묻는 Master 메시지다(Task Planning 라운드가 아니다).
    if (event.type == 'message' && event.decision == 'scope-question') {
      files.add(RecordFile('00-request/scope-question.md', '# 범위 확인 (Master AI → 사람)\n\n- ${event.text}\n'));
    }
    if (event.type == 'spec') {
      final spec = scenario.deriveSpec(event.step + 1)!;
      final owns = spec.lanes.isNotEmpty
          ? spec.lanes.map((lane) => '- ${lane.key} ${lane.title}: ${lane.owns}').join('\n')
          : '- 작업축별 소유 경로는 Task Planning(00-request/task-contract.json)에서 정함';
      final axis = spec.axisNote != null ? '\n## 작업축\n- ${spec.axisNote}\n' : '';
      files.add(
        RecordFile('00-request/work-spec.md', '# WORK SPEC\n\n## 범위\n${_list(spec.scope)}\n\n## 완료 기준\n${_list(spec.criteria)}\n\n## 소유 경로\n$owns\n$axis'),
      );
    }
    // AI-NOTE: 병렬 전체 Task Planning 기록. 제안(proposal) → 검토 라운드(승인) → 동결 계약 순으로만 생긴다.
    // 모두 cursor 까지의 이벤트에서 다시 만들어지므로 되감으면 아직 일어나지 않은 승인·동결 파일은 없다.
    if (event.type == 'task') {
      final plan = scenario.deriveTaskPlan(event.step + 1)!;
      final taskRows = [
        for (final task in plan.tasks)
          {
            'lane': task.id,
            'key': task.key,
            'title': task.title,
            'ownedPaths': [task.owns],
            'interfaces': [task.terms.interface],
            'acceptance': [task.terms.acceptance],
            'dependsOnUnfinished': <String>[],
          },
      ];
      if (event.stage == 'task-split') {
        files.add(
          RecordFile(
            '00-request/task-planning/proposal-001.json',
            jsonPretty({'round': 1, 'author': 'task-planning-author', 'source': '00-request/work-spec.md', 'axes': taskRows}),
          ),
        );
      }
      if (event.stage == 'task-review') {
        files.add(
          RecordFile(
            '00-request/task-planning/round-001.json',
            jsonPretty({
              'round': 1,
              'reviewer': 'task-planning-reviewer',
              'proposal': 'proposal-001.json',
              'verdict': 'APPROVED',
              'checks': plan.checks,
              'sharedOwnership': plan.sharedOwner,
            }),
          ),
        );
      }
      if (event.stage == 'task-freeze') {
        files.add(
          RecordFile(
            '00-request/task-contract.json',
            jsonPretty({
              'frozen': true,
              'approvedRound': plan.approvedRound,
              'tasks': taskRows,
              'sharedOwnership': plan.sharedOwner,
              'mergeOrder': plan.mergeOrder,
            }),
          ),
        );
        final rows = plan.tasks.map((task) => '- ${task.key} ${task.title}: ${task.owns} · 미완료 의존 없음').join('\n');
        final order = plan.mergeOrder!.map((id) => '- ${scenario.laneKey(id)} $id').join('\n');
        files.add(RecordFile('00-request/task-contract.md', '# Task Contract (동결)\n\n$rows\n- 공유 소유: ${plan.sharedOwner}\n\n## 병합 순서(동결)\n$order\n'));
      }
    }
    if (event.type == 'message' && event.decision == 'dispatch') {
      for (final lane in scenario.lanes) {
        final task = scenario.parallel ? scenario.deriveTaskPlan(event.step + 1)!.tasks.where((item) => item.id == lane.id).firstOrNull : null;
        final terms = task == null
            ? ''
            : '- 출처: 00-request/task-contract.json (승인 라운드 1)\n- 인터페이스: ${task.terms.interface}\n- 수용 기준: ${task.terms.acceptance}\n- 자기 worktree에서 진행, 다른 레인의 미완료 결과를 기다리지 않음\n';
        files.add(
          RecordFile(
            '${laneDir(lane.id)}00-request/lane-context.md',
            '# ${scenario.parallel ? '레인 ${lane.key}' : '작업'} · ${lane.title}\n\n- 소유 경로: ${lane.owns}\n$terms- 완료 조건: 개발 검수 승인 + 독립 QA 통과\n',
          ),
        );
      }
    }
    // 직접 처리는 계획·검수·QA 기록 없이 변경 요약 하나만 남긴다.
    if (event.type == 'direct') {
      files.add(RecordFile('01-direct/change-summary.md', '# 직접 처리 (Master AI)\n\n- ${event.text}\n- 변경 범위: ${content.directWorkOwns}\n'));
    }
    if (event.type == 'seed') {
      context.seeds[event.lane!] = [...?context.seeds[event.lane!], event.session!];
    }

    final lane = event.lane;
    if (lane != null) {
      final dir = laneDir(lane);
      if (event.type == 'seed') {
        files.add(RecordFile('${dir}sessions/lineage.json', jsonPretty(lineageFor(lane, context))));
      }
      if (event.stage != null) {
        final runs = context.runs.putIfAbsent(lane, () => {});
        final session = event.session;
        runs['$session'] = (runs['$session'] ?? 0) + 1;
        if (_seededSessions.contains(session) && scenario.seeded) {
          files.add(RecordFile('${dir}sessions/lineage.json', jsonPretty(lineageFor(lane, context))));
        }
      }
      final reasons = event.reason != null ? [event.reason] : <String>[];
      if (event.stage == 'plan-review') {
        files.add(
          RecordFile(
            '${dir}01-planning/round-${_pad3(event.attempt!)}.json',
            jsonPretty({'round': event.attempt, 'verdict': event.verdict!.toUpperCase(), 'reasons': reasons}),
          ),
        );
        if (event.verdict == 'approved') {
          files.add(
            RecordFile(
              '${dir}01-planning/plan.md',
              '# 승인된 계획 (${scenario.laneKey(lane)})\n\n- 승인 라운드: ${event.attempt}\n- 반려 라운드: ${event.attempt! - 1}\n- 다음 단계: 개발\n',
            ),
          );
        }
      }
      if (event.stage == 'dev') {
        files.add(
          RecordFile(
            '${dir}02-development/change-summary.md',
            '# 변경 요약 (${scenario.laneKey(lane)} · ${event.attempt}회차)\n\n- ${event.text}\n- 변경 범위: ${laneOwns(lane)}\n',
          ),
        );
      }
      if (event.stage == 'dev-review') {
        files.add(
          RecordFile(
            '${dir}02-development/review-round-${_pad3(event.attempt!)}.json',
            jsonPretty({'round': event.attempt, 'verdict': event.verdict!.toUpperCase(), 'reasons': reasons}),
          ),
        );
      }
      if (event.stage == 'qa') {
        final attemptDir = '${dir}03-qa/attempt-${_pad3(event.attempt!)}';
        files.add(
          RecordFile(
            '$attemptDir/result.json',
            jsonPretty({
              'attempt': event.attempt,
              'verdict': event.verdict!.toUpperCase(),
              'issues': event.issueId != null ? [event.issueId] : <String>[],
              'resolves': event.resolves != null ? [event.resolves] : <String>[],
              'session': 'independent',
              'resumed': event.resumed,
            }),
          ),
        );
        files.add(
          RecordFile(
            '$attemptDir/result.md',
            '# QA ${event.attempt}회차 — ${verdictLabel[event.verdict]}\n\n${event.reason != null ? '- 결함: ${event.issueId} ${event.reason}\n' : '- ${event.text}\n'}',
          ),
        );
        final issues = scenario.deriveIssues(lane, event.step + 1);
        files.add(
          RecordFile(
            '${dir}03-qa/issue-ledger.json',
            jsonPretty({
              'derivedFrom': 'attempt-*/result.json',
              'issues': [for (final issue in issues) issue.toJson()],
            }),
          ),
        );
        final ledger = issues.isNotEmpty
            ? issues
                  .map((issue) => '- ${issue.id} · ${issue.status == 'resolved' ? '해결(${issue.resolvedBy})' : '열림'} · 재현 ${issue.occurrences}회 · ${issue.text}')
                  .join('\n')
            : '- 지적 없음';
        files.add(RecordFile('${dir}03-qa/issue-ledger.md', '# 지적 원장 (읽기 전용 파생)\n\n$ledger\n'));
      }
      if (event.ready) {
        final manifest = <String, Object?>{'lane': lane, 'status': 'READY'};
        // JSON.stringify 는 undefined 값을 빼므로 기록되지 않은 회차는 키 자체가 없다.
        final planRounds = context.attempts['$lane:plan-review'];
        final devRounds = context.attempts['$lane:dev-review'];
        if (planRounds != null) manifest['planReviewRounds'] = planRounds;
        if (devRounds != null) manifest['devReviewRounds'] = devRounds;
        manifest['qaAttempts'] = event.attempt;
        files.add(RecordFile('${dir}04-completed/manifest.json', jsonPretty(manifest)));
      }
      if (event.stage != null && isRawEvent(event, context.events)) files.addAll(rawFiles(event));
    }

    if (event.type == 'integration') {
      // 병합 순서는 작업 계약에서 동결한 MERGE_ORDER 다. READY 도착 순서는 기록용으로만 남긴다.
      final order = [...content.mergeOrder];
      String keys(List<String> ids) => ids.map(scenario.laneKey).join(' → ');
      switch (event.stage) {
        case 'integration-plan':
          files.add(
            RecordFile(
              '04-integration/planning/plan.md',
              '# 통합 기획\n\n- 병합 순서(작업 계약 고정): ${keys(order)}\n- READY 도착 순서(참고): ${keys(context.readyOrder)}\n- 공유 경로 충돌: 없음\n',
            ),
          );
        case 'merge':
          files.add(
            RecordFile(
              '04-integration/merge/merge.json',
              jsonPretty({'order': order, 'source': '00-request/task-contract.json', 'readyOrder': context.readyOrder, 'conflicts': <String>[]}),
            ),
          );
        case 'integration-dev':
          files.add(RecordFile('04-integration/implementation/change-summary.md', '# 통합 구현\n\n- ${event.text}\n'));
        case 'integration-review':
          files.add(RecordFile('04-integration/implementation/review-round-001.json', jsonPretty({'round': 1, 'verdict': 'APPROVED', 'reasons': <String>[]})));
        case 'build':
          files.add(
            RecordFile(
              '04-integration/build/build.json',
              jsonPretty({
                'commands': ['npm run build', 'npm test'],
                'result': 'PASSED',
              }),
            ),
          );
        case 'integration-qa':
          files.add(
            RecordFile(
              '04-integration/qa/attempt-001/result.json',
              jsonPretty({
                'attempt': 1,
                'verdict': 'PASSED',
                'scenarios': ['목록 → 상태 변경 → 이력 확인'],
              }),
            ),
          );
          files.add(RecordFile('04-integration/qa/attempt-001/result.md', '# 통합 QA 1회차 — 통과\n\n- 목록에서 상태를 바꾸면 이력에 최신순으로 나타남\n'));
        case 'wiki':
          files.add(RecordFile('05-wiki/wiki-update.md', '# Wiki 갱신 (독립 Wiki Author·Reviewer)\n\n- 구조와 판단 근거 기록\n- 범위 제외 결정 기록\n'));
        case 'final-merge':
          files.add(RecordFile('04-integration/merge/final.json', jsonPretty({'target': 'starting-branch', 'local': true, 'pushed': false})));
      }
    }
    return files;
  }

  List<RecordFile> aggregateFiles(List<WorkflowEvent> events, int cursor) {
    final lanes = scenario.deriveLanes(cursor);
    final gate = scenario.deriveMergeGate(cursor);
    final integration = scenario.deriveIntegration(cursor);
    final last = events.last;
    final decisions = [
      for (final event in events)
        if (event.type == 'message' && const ['route', 'scope', 'permission'].contains(event.decision)) event,
    ];
    final nextLane = [
      for (final lane in lanes)
        if (lane.current != null) '${lane.key} ${lane.current!.label} ${lane.current!.attempt}회차',
    ];
    final nextIntegration = integration.where((item) => item.isActive).firstOrNull;
    var next = '다음 요청 대기';
    if (cursor < scenario.total) {
      next = nextLane.isNotEmpty ? nextLane.join(', ') : (nextIntegration != null ? nextIntegration.label : 'Master AI 응답');
    }
    final String gateText;
    if (gate == null) {
      gateText = '없음(${scenario.isDirect ? '직접 처리' : '순차'})';
    } else if (gate.status == 'locked') {
      gateText = '잠김 (${gate.waitingFor.isEmpty ? '-' : gate.waitingFor.join('·')} 대기)';
    } else if (gate.status == 'open') {
      gateText = '열림';
    } else {
      gateText = '병합 완료';
    }
    String describe(WorkflowEvent event) => '- ${event.time} ${scenario.describeEvent(event)}';
    final title = scenario.lanes.length > 1 ? '사내 요청 대시보드' : (scenario.lanes.firstOrNull?.title ?? '상태 이름 수정');
    final handling = scenario.specStep == -1 ? '- 처리: 01-direct/change-summary.md (Master AI 직접 처리)\n' : '- 작업 명세: 00-request/work-spec.md\n';
    final split = scenario.parallel ? '- 작업 분할: 00-request/task-planning/ → 00-request/task-contract.json\n' : '';
    final laneLine = scenario.parallel ? '- 레인: ${scenario.lanes.map((lane) => '03-lanes/${lane.id}').join(', ')}\n' : '';
    final decisionLines = decisions.isNotEmpty
        ? decisions.reversed.map((event) => '- ${event.time} ${event.actor == 'human' ? '사람' : 'Master AI'}: ${event.text}').join('\n')
        : '- 아직 없음';

    return [
      RecordFile(
        'index.md',
        '# $title\n\n- 요청: 00-request/request.md\n$handling$split- 현재 상태: current.md\n- 교환 원장: ledger.md\n- 최신순 진행: timeline.md · decisions.md\n$laneLine',
      ),
      RecordFile(
        'current.md',
        '# 현재 상태\n\n- 최신: ${scenario.describeEvent(last)}\n- 결정: ${decisions.isNotEmpty ? decisions.last.text : '없음'}\n- 레인: ${lanes.map((lane) => '${lane.key} ${_laneStatusText[lane.status]}').join(' · ')}\n- 병합 게이트: $gateText\n- 다음: $next\n',
      ),
      RecordFile('ledger.md', '# 교환·게이트 원장 (시간순)\n\n${events.map(describe).join('\n')}\n'),
      RecordFile('timeline.md', '# 타임라인 (최신순)\n\n${events.reversed.map(describe).join('\n')}\n'),
      RecordFile('decisions.md', '# 결정 (최신순)\n\n$decisionLines\n'),
      RecordFile(
        'events.jsonl',
        '${events.map((event) => jsonCompact({'seq': event.seq, 'time': event.time, 'type': event.type, 'actor': event.actor, 'lane': event.lane, 'stage': event.stage, 'attempt': event.attempt, 'verdict': event.verdict, 'session': event.session})).join('\n')}\n',
      ),
      RecordFile(
        'state.json',
        jsonPretty({
          'schemaVersion': 3,
          'route': scenario.options.route,
          'checkpoint': last.seq,
          // 배정 전 레인은 stage 가 없다(null). "ready" 는 실제 READY·병합·완료된 레인에만 쓴다.
          'lanes': {
            for (final lane in lanes)
              lane.id: {
                'status': lane.status,
                'stage': lane.current?.stage ?? (const ['ready', 'merged', 'done'].contains(lane.status) ? 'ready' : null),
                ...lane.counts.toJson(),
              },
          },
          'mergeGate': gate?.status,
        }),
      ),
    ];
  }
}

List<RecordFile> _sortFiles(Iterable<RecordFile> files) => stableSorted(files, (a, b) {
  final ra = _rootOrder.indexOf(a.path);
  final rb = _rootOrder.indexOf(b.path);
  if (ra != -1 || rb != -1) return (ra == -1 ? 99 : ra) - (rb == -1 ? 99 : rb);
  return a.path.compareTo(b.path);
});

/// cursor 까지의 기록. files 는 경로 순, latestPath 는 마지막 단계가 직접 만든 마지막 파일(없으면 current.md).
WorkflowRecords deriveRecords(num cursor, WorkflowScenario scenario) {
  final at = scenario.clamp(cursor);
  final events = scenario.eventsUpTo(at);
  final content = scenario.content;
  final root = scenario.parallel ? content.recordRoot : (scenario.isDirect ? content.directRecordRoot : content.sequentialRecordRoot);
  if (events.isEmpty) return WorkflowRecords(root: root, files: const [], latestPath: null);

  final builder = _RecordBuilder(scenario);
  final context = _Context(events);
  final byPath = <String, RecordFile>{};
  String? latestPath;
  final lastStep = events.last.step;
  for (final event in events) {
    if (event.lane != null && event.stage != null) context.attempts['${event.lane}:${event.stage}'] = event.attempt!;
    if (event.ready) context.readyOrder.add(event.lane!);
    for (final file in builder.filesForEvent(event, context)) {
      // Map 은 처음 넣은 순서를 지키고 같은 키는 값만 바꾼다(원본 Map.set 과 같음).
      byPath[file.path] = file;
      if (event.step == lastStep) latestPath = file.path;
    }
  }
  for (final file in builder.aggregateFiles(events, at)) {
    byPath[file.path] = file;
  }
  return WorkflowRecords(root: root, files: List.unmodifiable(_sortFiles(byPath.values)), latestPath: latestPath ?? 'current.md');
}

/// 직전 cursor 와 비교한 파일 변화: new | updated. 화면의 "새 파일"/"갱신" 표시에 쓴다.
Map<String, String> deriveRecordChanges(num cursor, WorkflowScenario scenario) {
  final at = scenario.clamp(cursor);
  final changes = <String, String>{};
  if (at == 0) return changes;
  final before = {for (final file in deriveRecords(at - 1, scenario).files) file.path: file.content};
  for (final file in deriveRecords(at, scenario).files) {
    if (!before.containsKey(file.path)) {
      changes[file.path] = 'new';
    } else if (before[file.path] != file.content) {
      changes[file.path] = 'updated';
    }
  }
  return changes;
}
