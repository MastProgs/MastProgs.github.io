// Voice to SRT 상세 페이지(/subtitles) 문구·사실·예시 데이터(assets/data/subtitles.json = React src/content/subtitles.js).
// AI-NOTE: 사실은 사용자 승인 하에 원본 저장소의 README, docs/wiki 와 소스를 읽어 정리한 값이다(데모 저장소
// docs/reference/voice-to-srt/source-facts.json). 개인 AI 로그·녹음·미디어·설정·env 는 읽지 않았고 넣지 않는다.
// 품질·속도·정확도 수치, 출시 상태는 쓰지 않는다. WALKTHROUGH_FIXTURE 는 처리 원리를 보여 주려고 새로 쓴 짧은 가상 대사·시각이다.
// 이 파일은 JSON 을 형 있는 값으로 옮기기만 한다.
import '../../../core/json.dart';
import 'subtitles_model.dart';

class LabeledText {
  const LabeledText({required this.label, required this.text});

  factory LabeledText.fromJson(Json json) => LabeledText(label: json.str('label'), text: json.str('text'));

  final String label;
  final String text;
}

class PipelineStep {
  const PipelineStep({required this.id, required this.where, required this.label, required this.text});

  final String id;
  final String where;
  final String label;
  final String text;
}

class TitledList {
  const TitledList({required this.title, required this.items});

  factory TitledList.fromJson(Json json) => TitledList(title: json.str('title'), items: json.strings('items'));

  final String title;
  final List<String> items;
}

class WalkthroughStage {
  const WalkthroughStage({required this.id, required this.label, required this.title, required this.text});

  final String id;
  final String label;
  final String title;
  final String text;
}

class SubtitlesContent {
  SubtitlesContent.fromJson(Json json)
    : page = json.texts('SUBTITLES_PAGE'),
      intro = json.obj('SUBTITLES_PAGE').strings('intro'),
      sections = json.obj('SUBTITLES_PAGE').texts('sections'),
      pipeline = [
        for (final step in json.objs('SUBTITLE_PIPELINE'))
          PipelineStep(id: step.str('id'), where: step.str('where'), label: step.str('label'), text: step.str('text')),
      ],
      does = TitledList.fromJson(json.obj('SUBTITLE_BOUNDARY').obj('does')),
      doesNot = TitledList.fromJson(json.obj('SUBTITLE_BOUNDARY').obj('doesNot')),
      proposalFieldsShown = json.obj('SUBTITLE_BOUNDARY').strings('proposalFields'),
      proposalNote = json.obj('SUBTITLE_BOUNDARY').str('proposalNote'),
      editor = [for (final item in json.objs('SUBTITLE_EDITOR')) LabeledText.fromJson(item)],
      structureParts = [for (final item in json.obj('SUBTITLE_STRUCTURE').objs('parts')) LabeledText.fromJson(item)],
      structureLocal = TitledList.fromJson(json.obj('SUBTITLE_STRUCTURE').obj('local')),
      structureExternal = TitledList.fromJson(json.obj('SUBTITLE_STRUCTURE').obj('external')),
      uses = [for (final item in json.objs('SUBTITLE_USES')) LabeledText.fromJson(item)],
      walkCopy = json.texts('WALKTHROUGH_COPY'),
      stages = [
        for (final stage in json.objs('WALKTHROUGH_STAGES'))
          WalkthroughStage(id: stage.str('id'), label: stage.str('label'), title: stage.str('title'), text: stage.str('text')),
      ],
      fixture = WalkthroughFixture.fromJson(json.obj('WALKTHROUGH_FIXTURE'));

  final Map<String, String> page;
  final List<String> intro;
  final Map<String, String> sections;
  final List<PipelineStep> pipeline;
  final TitledList does;
  final TitledList doesNot;
  final List<String> proposalFieldsShown;
  final String proposalNote;
  final List<LabeledText> editor;
  final List<LabeledText> structureParts;
  final TitledList structureLocal;
  final TitledList structureExternal;
  final List<LabeledText> uses;
  final Map<String, String> walkCopy;
  final List<WalkthroughStage> stages;
  final WalkthroughFixture fixture;
}
