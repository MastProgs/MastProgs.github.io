// GitHub Pages는 상세 경로를 index.html로 재작성하지 않으므로 해시 경로를 실제 href에도 사용한다.
// AI-NOTE: 일반 클릭은 Flutter 라우터가 처리하고 수정 키·보조 버튼은 브라우저가 href를 직접 연다.
// 두 경로가 같은 화면을 가리키도록 앱 경로와 메인 앵커의 공개 URL을 여기서 함께 만든다.

Uri routeLink(String path) => Uri.parse('/#$path');

Uri anchorLink(String id) => Uri(path: '/', fragment: '/?anchor=$id');
