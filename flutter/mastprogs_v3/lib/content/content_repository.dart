// 경로별로 필요한 데이터만 늦게 읽는 저장소(같은 출처의 번들 자산만, 네트워크·저장 없음).
// AI-NOTE: React 는 /sprite·/subtitles 를 별도 청크로 늦게 불러오고 메인 번들에는 SpriteBrief(원본 GIF 요약)만 둔다.
// 같은 원칙으로 메인은 site·resume·pixel-assets(가벼운 GIF 목록)만 읽고, 레이어·팔레트 세트·골격·자막 예시는 각 상세 페이지에서만 읽는다.
// 한 번 읽은 자산은 Future 로 보관해 같은 탭 안에서 다시 읽지 않는다.
import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/json.dart';
import '../features/portfolio/portfolio_content.dart';
import '../features/sprite/model/pixel_layers.dart';
import '../features/sprite/model/pixel_palette_sets.dart';
import '../features/sprite/model/pixel_rig.dart';
import '../features/sprite/model/pixel_studio_content.dart';
import '../features/sprite/model/sprite_meta.dart';
import '../features/subtitles/model/subtitles_content.dart';
import '../features/workflow/model/workflow_content.dart';

class MainContent {
  const MainContent({required this.site, required this.resume, required this.sprite});

  final SiteContent site;
  final ResumeContent resume;
  final SpriteMeta sprite;
}

/// /sprite 머리글·문구·원본 GIF 목록(가벼운 부분). 원본 데이터 모델을 만들지 못해도 이것만으로 GIF 대체 화면을 그린다.
class SpritePageData {
  const SpritePageData({required this.site, required this.content, required this.sprite});

  final SiteContent site;
  final PixelStudioContent content;
  final SpriteMeta sprite;
}

/// /sprite 전용 원본 데이터(20행 레이어·색 표·팔레트 세트 10종·골격·프레임 각도).
class SpriteStudioData {
  const SpriteStudioData({required this.layers, required this.colorTable, required this.sets, required this.rig, required this.motionRig});

  final PixelLayerModel layers;
  final List<Rgb?> colorTable;
  final List<PaletteSet> sets;
  final HeroRig rig;
  final Json motionRig;
}

class WorkflowPageData {
  const WorkflowPageData({required this.content});

  final WorkflowContent content;
}

class SubtitlesPageData {
  const SubtitlesPageData({required this.site, required this.content});

  final SiteContent site;
  final SubtitlesContent content;
}

class ContentRepository {
  ContentRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final Map<String, Future<Object?>> _raw = {};

  Future<Object?> _read(String name) => _raw.putIfAbsent(name, () async => jsonDecode(await _bundle.loadString('assets/data/$name.json', cache: false)));

  Future<Json> _object(String name) async => asJson(await _read(name));

  Future<SiteContent>? _site;
  Future<MainContent>? _main;
  Future<WorkflowPageData>? _workflow;
  Future<SpritePageData>? _spritePage;
  Future<SpriteStudioData>? _studio;
  Future<SubtitlesPageData>? _subtitles;

  Future<SiteContent> site() => _site ??= _object('site').then(SiteContent.fromJson);

  Future<MainContent> main() => _main ??= () async {
    final results = await Future.wait([site(), _object('resume'), _object('pixel-assets')]);
    return MainContent(site: results[0] as SiteContent, resume: ResumeContent.fromJson(results[1] as Json), sprite: SpriteMeta.fromJson(results[2] as Json));
  }();

  Future<WorkflowPageData> workflow() => _workflow ??= _object('workflowDetail').then((json) => WorkflowPageData(content: WorkflowContent.fromJson(json)));

  Future<SpritePageData> spritePage() => _spritePage ??= () async {
    final results = await Future.wait([site(), _object('pixelStudio'), _object('pixel-assets')]);
    return SpritePageData(
      site: results[0] as SiteContent,
      content: PixelStudioContent.fromJson(results[1] as Json),
      sprite: SpriteMeta.fromJson(results[2] as Json),
    );
  }();

  Future<SpriteStudioData> studio() => _studio ??= () async {
    final results = await Future.wait([
      _object('pixel-layers'),
      _read('pixel-source-colors'),
      _read('pixel-palette-sets'),
      _object('pixel-rig'),
      _object('pixel-motion-rig'),
    ]);
    return SpriteStudioData(
      layers: PixelLayerModel.fromJson(results[0] as Json),
      colorTable: sourceColorTable(results[1] as List),
      sets: buildPaletteSets(asJsonList(results[2])),
      rig: buildRig(results[3] as Json),
      motionRig: results[4] as Json,
    );
  }();

  Future<SubtitlesPageData> subtitles() => _subtitles ??= () async {
    final results = await Future.wait([site(), _object('subtitles')]);
    return SubtitlesPageData(site: results[0] as SiteContent, content: SubtitlesContent.fromJson(results[1] as Json));
  }();
}
