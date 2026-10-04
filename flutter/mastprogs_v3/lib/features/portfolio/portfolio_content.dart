// 메인 이력서 문구·사례·이력 데이터(assets/data/site.json = React src/content/site.js, assets/data/resume.json = src/content/resume.js).
// AI-NOTE: 사례 문구는 이력서에 근거한 실제 작업만 서술하고, 생산성 비율이나 비용·시간 절감 수치는 쓰지 않는다.
// 사용자 명시 요청으로 "설명용 데모" 안내 문구와 직함을 화면에서 모두 뺐다. 이름은 "김형준" 만 표시한다.
// 회사·기간·역할·업무는 원문 범위를 넘겨 쓰지 않는다(기간이 겹치는 항목도 원문 그대로, 근무 연수 합산 없음).
// 이메일·전화 칸은 사용자가 최신 지시로 입력·포함을 확인한 값이며 일반 텍스트다(빈 값이면 contactValue 가 null → "준비 중").
// 링크는 profile 칸의 PORTFOLIO_URL 하나뿐이다(contactHref).
// 이 파일은 JSON 을 형 있는 값으로 옮기기만 한다(값 변경 없음).
import '../../core/json.dart';

class NavLink {
  const NavLink({required this.href, required this.label});

  factory NavLink.fromJson(Json json) => NavLink(href: json.str('href'), label: json.str('label'));

  final String href;
  final String label;

  /// '#about' → 'about'.
  String get anchor => href.startsWith('#') ? href.substring(1) : href;
}

class LabeledPoint {
  const LabeledPoint({required this.label, required this.text});

  factory LabeledPoint.fromJson(Json json) => LabeledPoint(label: json.str('label'), text: json.str('text'));

  final String label;
  final String text;
}

class CaseImage {
  const CaseImage({required this.src, required this.width, required this.height, required this.alt});

  final String src;
  final int width;
  final int height;
  final String alt;
}

class DiagramStep {
  const DiagramStep({required this.id, required this.label, required this.note});

  final String id;
  final String label;
  final String note;
}

class CaseDiagramData {
  const CaseDiagramData({required this.label, required this.steps});

  final String label;
  final List<DiagramStep> steps;
}

class PortfolioCase {
  PortfolioCase.fromJson(Json json)
    : id = json.str('id'),
      index = json.str('index'),
      title = json.str('title'),
      summary = json.str('summary'),
      tags = json.strings('tags'),
      image = json['image'] == null
          ? null
          : CaseImage(
              src: json.obj('image').str('src'),
              width: json.obj('image').integer('width'),
              height: json.obj('image').integer('height'),
              alt: json.obj('image').str('alt'),
            ),
      fit = json.strOrNull('fit'),
      isDiagram = json['mediaKind'] == 'diagram',
      diagram = json['diagram'] == null
          ? null
          : CaseDiagramData(
              label: json.obj('diagram').str('label'),
              steps: [for (final step in json.obj('diagram').objs('steps')) DiagramStep(id: step.str('id'), label: step.str('label'), note: step.str('note'))],
            ),
      problem = json.str('problem'),
      role = json.strings('role'),
      evidence = json.str('evidence'),
      limits = json.strOrNull('limits'),
      detailLabel = json['detail'] == null ? null : json.obj('detail').str('label');

  final String id;
  final String index;
  final String title;
  final String summary;
  final List<String> tags;
  final CaseImage? image;

  /// contain | cover (이미지 사례).
  final String? fit;
  final bool isDiagram;
  final CaseDiagramData? diagram;
  final String problem;
  final List<String> role;
  final String evidence;
  final String? limits;

  /// 상세 페이지가 있는 사례의 새 탭 링크 이름.
  final String? detailLabel;
}

class CoreItemDef {
  const CoreItemDef({required this.id, required this.index, required this.label});

  final String id;
  final String index;
  final String label;
}

class HeaderColumn {
  const HeaderColumn({required this.heading, required this.items});

  final String heading;
  final List<String> items;
}

/// site.json.
class SiteContent {
  SiteContent.fromJson(Json json)
    : sectionIds = json.texts('SECTION_IDS'),
      resumeLinks = [for (final link in json.objs('RESUME_LINKS')) NavLink.fromJson(link)],
      resumeNavHeading = json.str('RESUME_NAV_HEADING'),
      name = json.obj('IDENTITY').str('name'),
      headerColumns = [for (final column in json.objs('HEADER_COLUMNS')) HeaderColumn(heading: column.str('heading'), items: column.strings('items'))],
      navLinks = [for (final link in json.objs('NAV_LINKS')) NavLink.fromJson(link)],
      stickyLabel = json.obj('STICKY_BAR').str('label'),
      stickyRevealAfter = json.obj('STICKY_BAR').number('revealAfter'),
      heroArc = json.obj('HERO').strings('arc'),
      heroArcLabel = json.obj('HERO').str('arcLabel'),
      heroLines = json.obj('HERO').strings('lines'),
      stageTitle = json.obj('STAGE').str('title'),
      workflowSteps = [for (final step in json.obj('WORKFLOW_SUMMARY').objs('steps')) LabeledPoint.fromJson(step)],
      workflowSummary = json.texts('WORKFLOW_SUMMARY'),
      cases = [for (final item in json.objs('CASES')) PortfolioCase.fromJson(item)],
      subtitlesRoute = json.str('SUBTITLES_ROUTE'),
      srtBrief = json.texts('SRT_BRIEF'),
      srtPoints = [for (final point in json.obj('SRT_BRIEF').objs('points')) LabeledPoint.fromJson(point)],
      core = json.texts('CORE'),
      coreItems = [for (final item in json.obj('CORE').objs('items')) CoreItemDef(id: item.str('id'), index: item.str('index'), label: item.str('label'))],
      spriteRoute = json.str('SPRITE_ROUTE'),
      spriteBrief = json.texts('SPRITE_BRIEF'),
      spritePoints = [for (final point in json.obj('SPRITE_BRIEF').objs('points')) LabeledPoint.fromJson(point)],
      casesRail = json.texts('CASES_RAIL');

  final Map<String, String> sectionIds;
  final List<NavLink> resumeLinks;
  final String resumeNavHeading;
  final String name;
  final List<HeaderColumn> headerColumns;
  final List<NavLink> navLinks;
  final String stickyLabel;
  final double stickyRevealAfter;
  final List<String> heroArc;
  final String heroArcLabel;
  final List<String> heroLines;
  final String stageTitle;
  final List<LabeledPoint> workflowSteps;
  final Map<String, String> workflowSummary;
  final List<PortfolioCase> cases;
  final String subtitlesRoute;
  final Map<String, String> srtBrief;
  final List<LabeledPoint> srtPoints;
  final Map<String, String> core;
  final List<CoreItemDef> coreItems;
  final String spriteRoute;
  final Map<String, String> spriteBrief;
  final List<LabeledPoint> spritePoints;
  final Map<String, String> casesRail;

  String section(String key) => sectionIds[key]!;

  PortfolioCase caseById(String id) => cases.firstWhere((item) => item.id == id);
}

class AboutValue {
  const AboutValue({required this.title, required this.body});

  final String title;
  final String body;
}

class Highlight {
  const Highlight({required this.label, required this.text, required this.href, required this.linkLabel});

  final String label;
  final String text;
  final String href;
  final String linkLabel;
}

class ContactField {
  const ContactField({required this.id, required this.label, required this.value});

  final String id;
  final String label;
  final String value;
}

class CareerEntry {
  const CareerEntry({
    required this.id,
    required this.company,
    required this.start,
    required this.end,
    required this.role,
    required this.note,
    required this.duties,
    required this.tags,
  });

  final String id;
  final String company;
  final String start;

  /// null 이면 현재 진행 중.
  final String? end;
  final String role;
  final String note;
  final List<String> duties;
  final List<String> tags;

  bool get isCurrent => end == null;
}

class Education {
  const Education({required this.id, required this.date, required this.school, required this.major, required this.degree});

  final String id;
  final String date;
  final String school;
  final String major;
  final String degree;
}

class SkillGroup {
  const SkillGroup({required this.id, required this.label, required this.items});

  final String id;
  final String label;
  final List<String> items;
}

/// resume.json.
class ResumeContent {
  ResumeContent.fromJson(Json json)
    : presentLabel = json.str('PRESENT_LABEL'),
      photoSrc = json.obj('PHOTO').str('src'),
      photoWidth = json.obj('PHOTO').integer('width'),
      photoHeight = json.obj('PHOTO').integer('height'),
      photoAlt = json.obj('PHOTO').str('alt'),
      about = json.texts('ABOUT'),
      story = json.obj('ABOUT').strings('story'),
      values = [for (final value in json.obj('ABOUT').objs('values')) AboutValue(title: value.str('title'), body: value.str('body'))],
      highlights = [
        for (final item in json.obj('ABOUT').objs('highlights'))
          Highlight(label: item.str('label'), text: item.str('text'), href: item.str('href'), linkLabel: item.str('linkLabel')),
      ],
      portfolioUrl = json.str('PORTFOLIO_URL'),
      contact = json.texts('CONTACT'),
      contactFields = [
        for (final field in json.obj('CONTACT').objs('fields'))
          ContactField(id: field.str('id'), label: field.str('label'), value: field['value'] is String ? field.str('value') : ''),
      ],
      career = json.texts('CAREER'),
      careerEntries = [
        for (final entry in json.obj('CAREER').objs('entries'))
          CareerEntry(
            id: entry.str('id'),
            company: entry.str('company'),
            start: entry.str('start'),
            end: entry.strOrNull('end'),
            role: entry.str('role'),
            note: entry.str('note'),
            duties: entry.strings('duties'),
            tags: entry.strings('tags'),
          ),
      ],
      skills = json.texts('SKILLS'),
      education = [
        for (final item in json.obj('SKILLS').objs('education'))
          Education(id: item.str('id'), date: item.str('date'), school: item.str('school'), major: item.str('major'), degree: item.str('degree')),
      ],
      skillGroups = [
        for (final group in json.obj('SKILLS').objs('groups')) SkillGroup(id: group.str('id'), label: group.str('label'), items: group.strings('items')),
      ];

  final String presentLabel;
  final String photoSrc;
  final int photoWidth;
  final int photoHeight;
  final String photoAlt;
  final Map<String, String> about;
  final List<String> story;
  final List<AboutValue> values;
  final List<Highlight> highlights;
  final String portfolioUrl;
  final Map<String, String> contact;
  final List<ContactField> contactFields;
  final Map<String, String> career;
  final List<CareerEntry> careerEntries;
  final Map<String, String> skills;
  final List<Education> education;
  final List<SkillGroup> skillGroups;

  // 기간 표시. end 가 null 이면 "현재" 로 쓴다. 연수 합산은 하지 않는다.
  String formatPeriod(CareerEntry entry) => '${entry.start} – ${entry.end ?? presentLabel}';

  /// 비어 있으면 null(화면은 "준비 중").
  String? contactValue(ContactField field) {
    final value = field.value.trim();
    return value.isEmpty ? null : value;
  }

  // 링크로 보여 줄 주소. profile 칸의 값이 PORTFOLIO_URL 과 정확히 같을 때만 돌려주고, 그 밖의 값은 null(일반 텍스트)이다.
  String? contactHref(ContactField field) => field.id == 'profile' && contactValue(field) == portfolioUrl ? portfolioUrl : null;
}
