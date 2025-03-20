import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:mastprogs_v2/common/font_style.dart';
import 'package:mastprogs_v2/common/provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ContentItem {
  final String? description;
  final String? imagePath;
  final String? buttonText;
  final String? url;
  final IconData? icon;
  final String? codeSnippet;
  final String? language;

  ContentItem({
    this.description,
    this.imagePath,
    this.buttonText,
    this.url,
    this.icon,
    this.codeSnippet,
    this.language,
  });
}

class ExpandableImageCard extends StatelessWidget {
  final String title;
  final List<ContentItem> contentItems;
  final bool isExpanded;
  final VoidCallback onToggle;

  const ExpandableImageCard({
    super.key,
    required this.title,
    required this.contentItems,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.blue.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(15),
                  topRight: const Radius.circular(15),
                  bottomLeft:
                      isExpanded ? Radius.zero : const Radius.circular(15),
                  bottomRight:
                      isExpanded ? Radius.zero : const Radius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: FontStyleYouandiModernTR.getStyle(
                      context: context,
                      fontSize: 18,
                      lightColor: Colors.grey.shade700,
                      darkColor: Colors.grey.shade300,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(Icons.expand_more,
                        color: isDarkMode
                            ? Colors.grey.shade300
                            : Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedAlign(
              alignment:
                  isExpanded ? Alignment.topCenter : Alignment.bottomCenter,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.bounceOut,
              heightFactor: isExpanded ? 1 : 0,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: contentItems
                      .map(
                          (item) => buildContentItem(context, item, isDarkMode))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildContentItem(
      BuildContext context, ContentItem item, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.imagePath != null)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: SizedBox(
              width: double.infinity,
              child: Image.asset(
                item.imagePath!,
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
        if (item.description != null)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Text(
              item.description!,
              style: FontStyleNotoSans.getStyle(
                context: context,
                fontSize: 14,
              ),
            ),
          ),
        if (item.buttonText != null && item.url != null)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: ElevatedButton.icon(
              onPressed: () => _launchUrl(item.url!),
              style: ElevatedButton.styleFrom(
                foregroundColor: isDarkMode ? Colors.white : Colors.black,
                backgroundColor:
                    isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(item.icon ?? Icons.open_in_new),
              label: Text(item.buttonText!),
            ),
          ),
        if (item.codeSnippet != null)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth:
                        MediaQuery.of(context).size.width - 80, // 패딩을 고려한 최소 너비
                  ),
                  child: HighlightView(
                    item.codeSnippet!,
                    language: item.language ?? 'go',
                    theme: githubTheme,
                    padding: const EdgeInsets.all(12),
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}

class WorkSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> cardData;
  final Function(String) getExpandedState;
  final Function(String) toggleExpandedState;

  const WorkSection({
    super.key,
    required this.title,
    required this.cardData,
    required this.getExpandedState,
    required this.toggleExpandedState,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: FontStyleYouandiModernTR.getStyle(
            context: context,
            fontSize: 24,
          ),
        ),
        const Divider(),
        ...cardData.map((data) {
          String id = data['id'] ??
              '${title.toLowerCase().replaceAll(' ', '_')}_${data['title'].toLowerCase().replaceAll(' ', '_')}';
          return ExpandableImageCard(
            title: data['title'],
            contentItems: data['contentItems'],
            isExpanded: getExpandedState(id),
            onToggle: () => toggleExpandedState(id),
          );
        }),
        const SizedBox(height: 40),
      ],
    );
  }
}

class WorkScreen extends StatefulWidget {
  const WorkScreen({super.key});

  @override
  _WorkScreenState createState() => _WorkScreenState();
}

class _WorkScreenState extends State<WorkScreen> {
  final Map<String, bool> _expandedStates = {};
  final Set<String> _initiallyExpandedCards = {
    '리치포켓_주식마스터_구현',
    '위메이드_플러스_typeorm_구현',
    '위메이드_플러스_부하테스트_툴_구현',
    '위메이드_플러스_log_로직_설계',
    '한빛소프트_매치메이킹_구현',
  };
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    for (var cardId in _initiallyExpandedCards) {
      _expandedStates[cardId] = true;
    }
  }

  bool _getExpandedState(String cardId) {
    return _expandedStates[cardId] ?? _initiallyExpandedCards.contains(cardId);
  }

  void _toggleExpandedState(String cardId) {
    setState(() {
      _expandedStates[cardId] = !_getExpandedState(cardId);
    });
  }

  Widget _buildBottomButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 맨 위로 가는 버튼 추가
        ElevatedButton(
          onPressed: () {
            // 페이지의 맨 위로 스크롤
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          },
          child: const Text('맨 위로'),
        ),
        // 다음 화면 보기 버튼 추가
        ElevatedButton(
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          child: const Text('다른 페이지'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WorkSection(
                  title: '리치포켓',
                  cardData: [
                    {
                      'title': '주식마스터 구현',
                      'id': '리치포켓_주식마스터_구현',
                      'contentItems': [
                        ContentItem(
                          description:
                              'Github 에서 코드를 관리하고 있으며, release 브랜치에 커밋되는 시점에 Github Actions 를 통해 자동 빌드 및 배포작업이 이루어집니다. Web Front 는 cloudflare pages 서비스에서 배포되고 있으며, 안드로이드 앱 빌드는 Actions 를 통해 aab 파일 생성 후, 구글 플레이콘솔에 프로덕션으로 배포됩니다.',
                          imagePath: 'assets/images/stockmaster-flowchart.png',
                        ),
                        ContentItem(
                          description:
                              '주식 종목 분석에는 Open AI 의 Chat GPT 를 활용하고 있으며, 이에 대한 결과를 Json 으로 받아 서비스 하는 형태로 관리됩니다.',
                        ),
                        ContentItem(
                          buttonText: '주식마스터 App',
                          url:
                              'https://play.google.com/store/apps/details?id=com.stockmaster.richpocket&pcampaignid=web_share',
                        ),
                        ContentItem(
                          buttonText: '주식마스터 Web',
                          url: 'https://richpocket.net/stock-master',
                        ),
                      ],
                    },
                  ],
                  getExpandedState: _getExpandedState,
                  toggleExpandedState: _toggleExpandedState,
                ),
                WorkSection(
                  title: '위메이드 플러스',
                  cardData: [
                    {
                      'title': '피싱토네이도 아키텍쳐 구현',
                      'contentItems': [
                        ContentItem(
                          description:
                              '기존에 넷마블에서 서비스 했던 C++ 서버를 C++20 버전으로 포팅하고, 별도로 위믹스 체인과 통신하기 위한 전체 아키텍쳐를 구성하였습니다. 성능을 위해 Go 언어를 활용한 Web 서버를 구축하였고, Wemix Chain 의 느린 응답속도에 대한 유저의 부정적 반응을 줄이기 위해 많은 노력을 기울였습니다.',
                          imagePath: 'assets/images/fishing_tornado.png',
                        ),
                      ],
                    },
                    {
                      'title': 'Nallary 아키텍쳐 설계',
                      'contentItems': [
                        ContentItem(
                          description:
                              '이더리움 블록체인 기반의 메타버스 커뮤니티 앱을 구축하기 위해 전체 아키텍쳐를 구성하였습니다. 인스타그램 같은 SNS 형태의 서비스에, 추가 3D 캐릭터 컨텐츠를 제공하는 형태로 구축하였습니다. 이미지 용량이 크기 때문에, AWS 의 람다 서비스를 통해 앱을 이용시에는 저용량의 이미지를 불러와 로딩속도를 최적화 하였고, 이더리움 블록체인에는 S3 원본 이미지에 대한 값을 기입하여 Opensea 와 같은 서비스에서 원본 이미지를 볼 수 있도록 하였습니다. Redis 에서는 실시간 이슈가 되고 있는 NFT 대해 시간 단위 랭킹을 집계하였고, 개인 간의 간단한 채팅서비스 또한 Redis 및 MQTT 브로커를 통해 제공되었습니다.',
                          imagePath: 'assets/images/nallary.png',
                        ),
                      ],
                    },
                    {
                      'title': 'Fast API 서버 구현',
                      'contentItems': [
                        ContentItem(
                          description:
                              'Fast API 의 속도가 일반 Node.js 보다 훨씬 빠르며 Go 서버에 가까이 성능이 나온다는 점에서 선택한 프레임워크 입니다. 또한 파이썬으로 구현이 되어 있어 프로젝트 구축 시간을 많이 단축시킬 수 있었기에, 선택하여 직접 구현하였습니다.',
                        ),
                        ContentItem(
                          buttonText: 'Fast API 서버 프레임워크',
                          url:
                              'https://github.com/MastProgs/fast-api-framework',
                          icon: Icons.code,
                        ),
                      ],
                    },
                    {
                      'title': '코드 제네레이터',
                      'contentItems': [
                        ContentItem(
                          description:
                              '엑셀 파일을 그대로 읽어서, 코드로 자동 작성해주는 툴을 구현하였습니다. 기획 데이터를 json 으로 수동 변환하여 검사하고 서버에 올리는 귀찮은 작업을 단순화 했습니다.',
                          buttonText: '코드 제네레이터',
                          url:
                              'https://github.com/MastProgs/fast-api-framework/blob/main/auto_code_generator.py',
                          icon: Icons.code,
                        ),
                      ],
                    },
                    {
                      'title': 'Go TypeORM 구현',
                      'id': '위메이드_플러스_typeorm_구현',
                      'contentItems': [
                        ContentItem(
                          description:
                              'Go 언어로 직접 TypeORM 을 구현하였습니다. 기존에 구현했던 내용은 MySQL 과 string 쿼리로 소통하는 방식이었지만, 유지보수와 확장성을 위해 Go 언어에 새롭게 업데이트 된 Generic reflection 기능을 활용하여, TypeORM 을 구현 및 트랜젝션 보장 기능까지 구현하였습니다.',
                          codeSnippet: '''
// 테이블 정의
type TblTest struct {
	Id        int64     `pk:"true" auto:"true"`
	Name      string    `default:"" length:"100"`
	Value     float64   `default:"0.0"`
	Active    bool      `default:"1"`
	CreatedAt time.Time `default:"CURRENT_TIMESTAMP"`
	UpdatedAt time.Time `default:"CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"`
	UserEmail string    `default:"" length:"100"`
}

// INSERT 예제
newRecord := TblTest{
  Name:   "테스트 데이터",
  Value:  123.45,
  Active: true,
}
id, err := repo.InsertStruct(newRecord)

// UPDATE 예제
var result TblTest
result.Name = "수정된 이름"
result.Value = 987.65
result.UpdatedAt = time.Now()
affected, err := repo.UpdateStruct(result, map[string]interface{}{"id": 1})

// UPSERT 예제
upsertRecord := TblTest{
  Name:      "UPSERT 테스트",
  Value:     555.55,
  Active:    true,
  CreatedAt: time.Now(),
}
upsertID, err := repo.UpsertStruct(upsertRecord)

// SELECT 예제
selectedUser := TblTest{}
err = repo.Find(&selectedUser, &FindOptions{
  Where:   map[string]interface{}{"id": id},
  Columns: []string{"id", "name"},
})
''',
                          language: 'go',
                        ),
                        ContentItem(
                          buttonText: '더 업그레이드 된 최신 Go ORM 구현',
                          url:
                              'https://github.com/MastProgs/go_server_framework/blob/main/database/example.go',
                          icon: Icons.code,
                        ),
                        ContentItem(
                          buttonText: 'TypeORM 코드',
                          url:
                              'https://github.com/MastProgs/custom-codes/blob/main/ezDB.go',
                          icon: Icons.code,
                        ),
                        ContentItem(
                          buttonText: 'Go TypeORM 과정 설명',
                          url: 'https://naver.me/xoL4jPs4',
                          icon: Icons.description,
                        ),
                      ],
                    },
                    {
                      'title': 'DBJob 구현',
                      'contentItems': [
                        ContentItem(
                          description:
                              'Typescript 의 TypeORM 을 활용하여, Save Update Delete Increase Decrease 같은 DB에 요청해야하는 다중 쿼리문과 Redis에 요청해야하는 다양한 request 들을 한 번의 트랜잭션으로 묶어 요청할 수 있도록 코드로 구현하였습니다.',
                        ),
                        ContentItem(
                          buttonText: 'Typescript DBJob 코드',
                          url:
                              'https://github.com/MastProgs/custom-codes/blob/main/DBJob.ts',
                          icon: Icons.code,
                        ),
                        ContentItem(
                          buttonText: 'Typescript DBJob 문서',
                          url:
                              'https://github.com/MastProgs/custom-codes#dbjobts',
                          icon: Icons.description,
                        ),
                      ],
                    },
                    {
                      'title': 'C++20 최신화',
                      'contentItems': [
                        ContentItem(
                          description:
                              '과거 넷마블에서 서비스 종료 했던 C++11 게임 서버를 C++20 으로 다시 포팅하였습니다. 과정 중 에러 4만개 이상을 수정하고, 생산성을 위해 최신 문법으로 재작업을 진행하였습니다. log 를 남기기 위해 format 문법을 사용하고, 크래시가 나는 경우 dump 파일을 남기지 않고 있어서, 관련 기능을 직접 구현하였습니다.',
                        ),
                      ],
                    },
                    {
                      'title': 'Pagination 기능',
                      'contentItems': [
                        ContentItem(
                          description:
                              'SNS 에서 스크롤링 및 페이지 형태로 데이터를 가져오는 기법인 Pagination 라이브러리를 훨씬 더 사용하기 쉽게 랩핑하였습니다. DB 에서 읽은 책갈피 위치에 대한 Hash 값을 기반으로 다음 위치의 Hash 값과 다음 data limit size 만큼의 값을 반환하도록 구현하였습니다.',
                        ),
                        ContentItem(
                          buttonText: 'Typescript Pagination 코드',
                          url:
                              'https://github.com/MastProgs/custom-codes/blob/main/Pager.ts',
                          icon: Icons.code,
                        ),
                        ContentItem(
                          buttonText: 'Typescript Pagination 문서',
                          url:
                              'https://github.com/MastProgs/custom-codes#pagerts',
                          icon: Icons.description,
                        ),
                      ],
                    },
                    {
                      'title': 'C# 부하테스트 툴 구현',
                      'id': '위메이드_플러스_부하테스트_툴_구현',
                      'contentItems': [
                        ContentItem(
                          description:
                              'WPF C# 을 활용하여 부하테스트 툴을 구현하였습니다. IP & Port, Thread, 반복, 딜레이 옵션 등을 활용하여, 서버의 각 컨텐츠 및 기능 별 부하테스트를 할 수 있는 툴입니다.',
                          imagePath: 'assets/images/UwpStressTool.png',
                        ),
                      ],
                    },
                    {
                      'title': 'Redis 핸들러 구현',
                      'contentItems': [
                        ContentItem(
                          description:
                              '기존에 구현되어 있던 Redis 핸들러가 문제가 있어, 새로 구현하였습니다. cpp_redis 오픈소스를 활용하여 더 간편하고 재사용 가능하게 코드를 구현하였습니다.',
                        ),
                        ContentItem(
                          buttonText: 'C++ Redis 핸들러 코드',
                          url:
                              'https://github.com/MastProgs/None_boost_Asio/blob/master/C%2B%2B20%20Asio/CoroutineAsioCpp20/Core/Redis/Redis.h',
                          icon: Icons.code,
                        ),
                        ContentItem(
                          buttonText: 'C++ Redis 핸들러 문서',
                          url:
                              'https://github.com/MastProgs/None_boost_Asio#redis',
                          icon: Icons.description,
                        ),
                      ],
                    },
                    {
                      'title': '문자열 변환 핸들러',
                      'contentItems': [
                        ContentItem(
                          description:
                              'Unicode, Multibyte, UTF-8, string, wstring, CString, CStringA 등 문자열을 마구잡이로 섞어 쓰고 있는 구 코드로 인해, 문제가 너무 많이 발생하여 이를 한꺼번에 특정 타입 문자열로 변환하여 주는 핸들러를 직접 구현하였습니다.',
                        ),
                        ContentItem(
                          buttonText: 'C++ 문자열 변환 코드',
                          url:
                              'https://github.com/MastProgs/None_boost_Asio/blob/master/C%2B%2B20%20Asio/CoroutineAsioCpp20/Common/String/ToStr.h',
                          icon: Icons.code,
                        ),
                      ],
                    },
                    {
                      'title': 'Log 로직 설계',
                      'id': '위메이드_플러스_log_로직_설계',
                      'contentItems': [
                        ContentItem(
                          description:
                              '사업팀에서 필요로 하는 로그를 적재해야하는 요청이 있어서 구현하게 되었습니다. 게임서버에서 필요한 여러 객체들에 대한 정보를 합산하여 Json 화 시키고, 해당 Json 을 Log 서버로 전송하면, Log 서버에서 DB 의 테이블 컬럼 정보를 가져와 검증 한 뒤, 필요한 정보들만 뽑아 쿼리로 만들어 DB 에 insert 시키는 구조입니다. 이를 통해 게임 서버에서는 정보를 남겨야 하는 시점에 필요한 객체들을 쉽게 합산하여 Log 서버로 데이터를 넘기면, Log 서버 내에서는 필요한 정보만 골라 Log DB 테이블 구조와는 상관없이 서버 배포도 자유롭고, 어떤 로그이건 동일한 프로세스 처리가 가능하도록 구현하였습니다.',
                          imagePath: 'assets/images/LogServerArchi.png',
                        ),
                        ContentItem(
                          description:
                              'Log 서버가 Web Rest API 로 주고 받도록 하다보니, 가끔씩 로그 패킷 유실이 발생하는 경우나 예상치 못하게 log 서버가 떨어질 경우를 대비하여, 게임서버가 직접 DB 에 데이터를 적재하는 형태로도 추가 구현하였습니다.',
                        ),
                      ],
                    },
                    {
                      'title': '날짜 시간 통합 관리',
                      'contentItems': [
                        ContentItem(
                          description:
                              '일주일 단위를 기준으로 반복되어 실행되어야 하는 스케쥴러 날짜 프로세스 로직을 구현하였습니다. 과거 코드는 local time 과 utc time 이 혼재되어 사용되고 있었고, 이를 통합하여 활용하기 위해 기본적으로 표준 utc 로 통합하는 처리를 하였습니다. string, time_point 를 변환하거나, 필요한 시간 값들의 연산 및 추출하는 형태로 생산성을 향상시켰습니다. 추가로 주간 이벤트 시간 처리가 매번 기획자 분들께서 스크립트로 입력해주어야 하는 부분을, week_hh_mm_ss 라는 클래스를 구현하여, 특정 요일의 시분초를 계산하는 클래스를 구현하였습니다. week_hh_mm_ss 클래스와 특정 시각을 조합하면, 해당 주차의 특정 요일의 시간분초 time_point 를 계산하여 가져오거나, week_hh_mm_ss 클래스를 서로 비교 연산하여 전후 시각을 알 수 있도록 구현하여, 매주 이벤트 시간 관리에 편의성을 더했습니다.',
                        ),
                        ContentItem(
                          buttonText: 'C++ 날짜 시간 코드',
                          url:
                              'https://github.com/MastProgs/None_boost_Asio/blob/master/C%2B%2B20%20Asio/CoroutineAsioCpp20/Common/Datetime/Datetime.h',
                          icon: Icons.code,
                        ),
                      ],
                    },
                  ],
                  getExpandedState: _getExpandedState,
                  toggleExpandedState: _toggleExpandedState,
                ),
                WorkSection(
                  title: '조이시티',
                  cardData: [
                    {
                      'title': '개발망 클라 런처 구현',
                      'contentItems': [
                        ContentItem(
                          description:
                              '각 국가 버전별 실행 명령 인자 값이 다르고, id pw ip port 등, 여러 정보를 매 실행마다 수동으로 입력하여 클라를 실행해야하는 시스템이라 많이 불편했었습니다. 자동화 런처 툴을 직접 개발하여, 버튼 몇 개만으로 실행 명령이나 옵션을 주어 게임 클라이언트를 실행할 수 있는 툴을 구현하였습니다.',
                        ),
                      ],
                    },
                    {
                      'title': '개발망 아이템 지급 툴 구현',
                      'contentItems': [
                        ContentItem(
                          description:
                              '개발 과정 중 필요한 아이템이나 캐릭터 세팅에 필요한 부분을 매번 서버 프로그래머에 요청하는 프로세스로 작업을 하기에 많은 시간이 소요되었습니다. 이를 해결하기 위해 아이템 지급 툴을 직접 구현하였습니다. 우편함으로 원하는 아이템이나 옵션을 지급하는 기능을 만들어 더 이상 서버 프로그래머가 관여하지 않아도, 기획자 및 클라이언트 프로그래머가 원활히 작업할 수 있도록 작업하였습니다.',
                        ),
                      ],
                    },
                  ],
                  getExpandedState: _getExpandedState,
                  toggleExpandedState: _toggleExpandedState,
                ),
                WorkSection(
                  title: '한빛소프트',
                  cardData: [
                    {
                      'title': '매치메이킹 구현',
                      'id': '한빛소프트_매치메이킹_구현',
                      'contentItems': [
                        ContentItem(
                          description:
                              'AWS GameLift 의 Flexmatch 를 활용하여, 게임 서버 매칭 시스템을 구현하였습니다. 클라이언트가 로비 서버에서 매치메이킹을 신청하면 이를 웹 서버로 전달하고, 웹 서버는 AWS 에 기능을 요청하여 관련 유니크한 티켓을 받아 매치메이킹에 대한 정보를 중개하는 역할을 구현하였습니다. 매칭이 이루어지면, GameLift 내의 임의 데디서버에 방을 생성하여 주고, 연결에 필요한 정보들을 파싱하여 각 클라이언트들에게 정보를 건네주는 순서로 진행되었습니다. AWS SNS 같은 기능을 활용하여 반복적인 loop 부분을, 매칭 되었을 시점에만 클라이언트에게 알려주는 형태로 만들고 싶었으나, AWS SNS 서비스 이용에 대한 추가 발생 요금을 회사측이 허용해주질 않았기에, 추가적인 기능은 더 해보지 못했습니다.',
                          imagePath: 'assets/images/AWSgameliftFlexmatch.png',
                        ),
                      ],
                    },
                  ],
                  getExpandedState: _getExpandedState,
                  toggleExpandedState: _toggleExpandedState,
                ),
                WorkSection(
                  title: '모아이게임즈',
                  cardData: [
                    {
                      'title': 'Sub 초기화 Loader 구현',
                      'contentItems': [
                        ContentItem(
                          description:
                              'MMO 게임에서 플레이어가 첫 서버 접속 시점에 필요한 필수 정보를 제외한, 나머지 후에 불러와도 괜찮은 데이터의 경우 필요한 시점에 데이터를 불러오도록 하는 로직을 구현하였습니다. 데이터가 필요한 순간에 즉시 최초 한 번만 DB 로 부터 정보를 받아왔습니다. (우편, 이벤트 정보 등등)',
                          imagePath: 'assets/images/process_subloader.png',
                        ),
                      ],
                    },
                    {
                      'title': '업적 시스템 구현',
                      'contentItems': [
                        ContentItem(
                          imagePath: 'assets/images/process_achv2.png',
                        ),
                        ContentItem(
                          description:
                              '특정 행동에 대한 업적 진행도를 올려주거나, 달성한 업적에 대한 보상을 지급하는 컨텐츠를 구현하였습니다. DB 부하를 줄이기 위해 LazyStore 라는 기능을 따로 구현하여, 1분마다 관련 정보를 한꺼번에 누적하여 저장할 수 있도록 로직을 구현하였습니다.',
                          imagePath: 'assets/images/process_achv1.png',
                        ),
                      ],
                    },
                    {
                      'title': '기억의 돌',
                      'contentItems': [
                        ContentItem(
                          description:
                              '현재 위치를 기억하고, 기억의 돌을 소모하여 특정 위치로 이동하는 컨텐츠를 구현하였습니다.',
                        ),
                      ],
                    },
                    {
                      'title': '칭호',
                      'contentItems': [
                        ContentItem(
                          description:
                              '칭호 지급 및 조건부 칭호 기능 구현, 칭호와 연동된 능력치 지급 컨텐츠를 구현하였습니다.',
                        ),
                      ],
                    },
                    {
                      'title': '출석 이벤트',
                      'contentItems': [
                        ContentItem(
                          description:
                              '매일 출석에 따른 스크립트에 입력된 보상 지급하는 기능을 구현하였습니다.',
                        ),
                      ],
                    },
                    {
                      'title': '누적 접속 보상',
                      'contentItems': [
                        ContentItem(
                          description:
                              '접속한 시간에 비례하여 스크립트에 입력된 보상을 지급하는 기능을 구현하였습니다. 특정 틱 단위로 DB 에 기록을 하고, 보상을 받을 수 잇는 시간이 되면 클라에 알림을 발송하는 형태로 구현하였습니다.',
                        ),
                      ],
                    },
                    {
                      'title': '오늘의 활동',
                      'contentItems': [
                        ContentItem(
                          description:
                              '매일 해야 하는 과제를 완수하면 보상을 지급하는 기능을 구현하였습니다.',
                        ),
                      ],
                    },
                    {
                      'title': '외형변경권',
                      'contentItems': [
                        ContentItem(
                          description: '외형변경권을 통해 외형을 변경할 수 있는 기능을 구현하였습니다.',
                        ),
                      ],
                    },
                    {
                      'title': '특수 업적',
                      'contentItems': [
                        ContentItem(
                          description:
                              '특정 상황에서 조건에 맞는 행동을 완수하면 지급되는 업적을 구현하였습니다. 샌드박스 형 조건 체크 기능 추가 구현 후, 업적 시스템과 결합하였습니다.',
                        ),
                      ],
                    },
                  ],
                  getExpandedState: _getExpandedState,
                  toggleExpandedState: _toggleExpandedState,
                ),
                const SizedBox(height: 16),
                _buildBottomButton(context),
                const SizedBox(height: 250),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
