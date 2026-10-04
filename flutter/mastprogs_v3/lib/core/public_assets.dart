// 원본 정적 에셋 경로 변환.
// AI-NOTE: 데이터(assets/data)에는 React 공개 경로(/profile/..., /cases/..., /pixel/hero/...)가 그대로 들어 있다.
// Flutter 는 같은 파일을 pubspec 의 assets/media/... 자산으로 번들하므로 키만 바꿔 쓴다(바이트 변경·새 그림 없음).
// React 소스 삭제 전 demo/public 에서 SHA256 동일하게 옮긴 파일이며, 원본은 Git 커밋 fcdfc01 에만 남아 있다.
const String publicAssetRoot = 'assets/media';

String publicAsset(String webPath) => '$publicAssetRoot${webPath.startsWith('/') ? webPath : '/$webPath'}';
