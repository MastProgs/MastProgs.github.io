import 'package:flutter/material.dart';
import 'package:mastprogs_v2/common/font_style.dart';
import 'package:mastprogs_v2/common/provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Company> companies = [
    Company(
        '리치포켓',
        'assets/images/richpocket.png',
        [
          Job(
            '창업',
            '2023.07.01 (사업자 등록 2024.04.01)',
            description:
                '만들고 싶은 SaaS 서비스가 생겨 도전해보고자 1인 창업으로 시작했습니다. 부업 정도로 운영하면서 작업하고 있기 때문에, 본업에는 지장이 없을 예정 입니다.',
          ),
          Job(
            'MoneyCV 자동트레이딩',
            '2024.08.19',
            projectInfo: {
              '장르': '자산 관리 서비스',
              '플랫폼': 'web',
            },
            skills: [
              'flutter.png',
              'python.png',
              'linux.png',
              'naver_cloud_platform.png',
              'git.png',
            ],
            description:
                '장기투자자도 쉽게 투자 전략을 세울 수 있도록 도와주는 서비스를 만들고자 출시했습니다. 웹 사이트로 서비스 중입니다.',
          ),
          Job(
            '주식마스터',
            '2024.10.15',
            projectInfo: {
              '장르': '검색 서비스',
              '플랫폼': 'web, Android',
            },
            skills: [
              'flutter.png',
              'python.png',
              'linux.png',
              'naver_cloud_platform.png',
              'git.png',
            ],
            description:
                '초보자 들도 쉽게 특정 주식 종목을 분석할 수 있는 서비스를 만들고자 출시했습니다. 구글 플레이스토어 및 웹 사이트로 서비스 중입니다.',
            url:
                'https://play.google.com/store/apps/details?id=com.stockmaster.richpocket',
          ),
          Job(
            '로또커스텀',
            '2025.05.30',
            projectInfo: {
              '장르': '로또 분석 서비스',
              '플랫폼': 'Android',
            },
            skills: [
              'flutter.png',
              'go.png',
              'linux.png',
              'naver_cloud_platform.png',
              'git.png',
            ],
            description:
                '로또 당첨 확률이 높은 조합을 추천해주는 서비스를 만들고자 출시했습니다. 구글 플레이스토어에서 서비스 중입니다.',
            url:
                'https://play.google.com/store/apps/details?id=com.richpocket.lottomaster',
            isFinal: true,
          ),
        ],
        isCurrent: true),
    Company('알레프리서치코리아', 'assets/images/aleph.png', [
      Job(
        '입사',
        '2024.04.15',
        description:
            '블록체인 코어를 개발하는 스타트업에 입사했습니다. Cosmos SDK 기반으로 개발 및 Sui Framework 기반으로 블록체인 코어 개발 및 디파이 스테이킹 서비스를 개발하였습니다.',
      ),
      Job(
        '퇴사',
        '2024.07.19',
        description:
            '회사의 방향성이나 리드급의 의사소통이 미흡하고, 오래 장기적으로 일하기에는 적합하지 않다고 생각하여 퇴사하였습니다.',
        isFinal: true,
      ),
    ]),
    Company('위메이드플러스', 'assets/images/wemade.png', [
      Job(
        '입사',
        '2021.09.06',
        description:
            '대학원을 재학중인 상황에서, 대학원과 병행하며 근무를 할 수 있으니 일손이 필요하다는 부탁을 받고 입사하였습니다.',
      ),
      Job(
        'Nallary',
        '2022.03.31 Drop',
        projectInfo: {
          '장르': '소셜 네트워크 앱, NFT 거래 플랫폼',
          '플랫폼': 'iOS, Android',
          '그래픽': '2D, 인게임: 풀 3D 뷰',
        },
        skills: [
          'ts.png',
          'mysql.png',
          'redis.png',
          'linux.png',
          'aws.png',
          'git.png',
        ],
        description:
            'NFT 컨텐츠와 Gallary의 합성 소셜 플랫폼 프로젝트로 모바일을 기반으로 개발되던 프로젝트였습니다. 이더리움 ERC-721 프로토콜을 기준으로 NFT 거래 소유 발행 등을 지원하는 프로젝트였으며, 플랫폼 내에서는 유저들이 아바타로 돌아다니며 다양한 작품들을 플랫폼 내에서 확인하고 다양한 컨텐츠를 즐기는, 일종의 NFT 거래와 컨텐츠를 활용할 수 있는 타사의 제페토 앱과 같다고 볼 수 있습니다. 하지만 모바일 IOS 측의 정책적인 이슈로 출시 직전 문제가 해결되지 못하고, 무기한 연기되었습니다. 저는 이 프로젝트에서 기본적인 프레임워크 부터 팔로잉/팔로우/좋아요 같은 소셜 컨텐츠 및 실시간 랭킹 시스템 등을 담당하여 구현하였습니다. 서비스를 하기 위한 AWS 클라우드 서버 환경을 설정하고 환경설정을 다루는 작업들을 담당했습니다.',
      ),
      Job(
        '피싱 토네이도 챔피언십',
        '2022.03.31 (Release 2023.05.25)',
        projectInfo: {
          '장르': 'Fishing',
          '플랫폼': 'iOS, Android',
          '그래픽': '2D',
        },
        skills: [
          'cpp.png',
          'go.png',
          'mysql.png',
          'redis.png',
          'windows.png',
          'azure.png',
          'git.png',
        ],
        description:
            '과거 넷마블에서 서비스 종료했던 게임에 token 을 붙여 재출시 준비 작업을 진행하였습니다. 과거 소스코드를 C++20 버전으로 포팅하고, 넷마블 퍼블리셔와 관련되어 있는 코드를 제거하는 작업을 진행하였습니다. token 연동을 하기 위해 Go 웹 서버를 통해 기타 token 관련한 컨텐츠들을 처리하였습니다. 로그 정보를 파일로만 남기던 구조를 변경하여, Go 서버를 통해 로그를 DB 로 적재하는 로직을 구현하였고, 게임 서버가 크래시 날 경우 dump 파일을 남길 수 있는 로직을 설계하였습니다. 또한 문자열 인코딩 문제가 빈번하고 통일되지 않은 자료형으로 인해, 문자열을 다양한 타입으로 변환할 수 있는 핸들러, Redis 연결 오류 같은 굵직한 이슈 등을 해결하였습니다. 서비스를 하기 위한 Azure 클라우드 서버 환경을 설정하고, 클라우드 서비스를 구성하는 작업 또한 담당하였습니다.',
      ),
      Job(
        '미공개 프로젝트',
        '2023.01.16',
        projectInfo: {
          '장르': '미정',
          '플랫폼': 'PC',
          '그래픽': '2D',
        },
        skills: [
          'python.png',
          'mysql.png',
          'mongodb.png',
          'redis.png',
          'linux.png',
          'azure.png',
          'git.png'
        ],
        description:
            '블록체인 재화를 연동한 게임을 개발하였습니다. 파이썬의 Fast API 를 활용하여 서버 프레임워크를 짜고, 그 위에 다양한 컨텐츠 작업과 코어 시스템들을 개발하였습니다. 서버 아키텍쳐 설계, 메인 웹 서버, 채팅 소켓 서버, 스케쥴러 서버, 스크립트 파일 검사, xlsx -> code, code -> xlsx, JWT 토큰 시스템, TypeORM 설계, 비동기 통신 등등, 모든 설계에 대한 A to Z 작업을 진행했습니다.',
      ),
      Job(
        '퇴사',
        '2023.06.30',
        description:
            '회사의 프로젝트를 여러개 진행하였지만, 현실적으로 프로젝트들의 성과가 저조했었고, 이러한 상황속에 작은 규모의 회사에서 지속적으로 투자를 받기에는 어려운 상황이었습니다. 그래서 회사의 경영진과 상의하여 퇴사를 진행하게 되었습니다.',
        isFinal: true,
      ),
    ]),
    Company('조이시티', 'assets/images/joycity.png', [
      Job(
        '입사',
        '2020.09.07',
        description:
            '게임 전체적으로 리뉴얼 작업을 진행해야하는 상황에서, 회사측 제의를 받아 입사를 진행하였습니다. 일손이 부족한 리뉴얼 작업을 담당했었고, 그와 함께 필요한 각종 이벤트 및 컨텐츠 작업들도 같이 작업하며 리뉴얼 업무를 했던 회사입니다.',
      ),
      Job(
        '프리스타일',
        '2020.09.07',
        projectInfo: {
          '장르': '아케이드',
          '플랫폼': 'PC',
          '그래픽': '3D Top View',
        },
        skills: ['cpp.png', 'mssql.png', 'windows.png', 'svn.png'],
        description:
            '오랫동안 라이브 서비스를 하던 게임에 다양한 컨텐츠 작업 및 구조적 리뉴얼 작업을 단행했습니다. 프로젝트 특성상 너무 낡고 오래되어, 생산성을 위한 개선 작업 툴을 만들거나 코드 리펙토링을 하기 위해 많은 노력을 기울였습니다.',
      ),
      Job(
        '퇴사',
        '2021.04.13',
        description:
            '특별히 불화가 있거나 문제가 있었던 부분은 없었지만, 준비하고 있었던 대학원과 병행하기에는 야근이 너무 많았었고, 어느 정도 큰 업무 처리들은 잘 마무리가 되었다고 판단되어, 퇴사를 진행하게 되었습니다.',
        isFinal: true,
      ),
    ]),
    Company('한빛소프트', 'assets/images/hb.png', [
      Job(
        '입사',
        '2020.02.03',
        description:
            '일손이 필요하다고 요청받아 지인을 통해 입사하게 되었습니다. 프로젝트 개발 초기에 합류하게 되었습니다.',
      ),
      Job(
        'Gunslinger Stratos',
        '2023.02.03',
        projectInfo: {
          '장르': 'TPS',
          '플랫폼': 'PC',
          '그래픽': '3D Full View',
        },
        skills: [
          'cpp.png',
          'js.png',
          'unreal.png',
          'mysql.png',
          'linux.png',
          'aws.png',
          'svn.png'
        ],
        description:
            '해당 프로젝트는 일본의 글로벌 기업인 Square Enix 와 함께 협업으로 진행되는 대형 프로젝트였습니다. 프로젝트가 약 1년정도 진행이 되고 있던 상황에 합류하였으며, TPS 게임 장르의 게임이었습니다. 언리얼의 데디케이티드 서버 + 웹 서버를 활용하여 게임이 제작되었으며, 제가 주로 담당했던 업무는 AWS 의 GameLift 기능 중 Flexmatch 라는 매치메이킹 관련 기능을 웹 서버와 데디케이티드 서버에 각각 구현하는 역할이 주 업무였습니다. 기타 업무는 라이브 서비스를 위한 운영툴에서 정보 조회 기능을 구현하는 역할도 담당하였습니다.',
      ),
      Job(
        '퇴사',
        '2020.05.01',
        description:
            '입사하고 나서 얼마 있지 않아 몸이 금방 아프게되어 아쉽게 퇴사하였습니다. 몸이 아파서 퇴사를 고민하던 시점에 함께 계속 일을 했으면 좋겠다는 요청을 주시며 아쉬움을 표하셨지만, 모든 연차를 소모하고 병가까지 쓰고 있던 상황이라 저 스스로도 일단 몸의 휴식이 최우선이라고 생각되어 원래 계획대로 퇴사하게 되었습니다.',
        isFinal: true,
      ),
    ]),
    Company('모아이게임즈', 'assets/images/moai.png', [
      Job(
        '입사',
        '2017.08.07',
        description: '개발 초기 시점에 MMORPG 개발을 경험해보고 싶어서, 직접 지원하여 합류하게 되었습니다.',
      ),
      Job(
        'TRAHA',
        '2018.04.18',
        projectInfo: {
          '장르': 'MMORPG',
          '플랫폼': 'IOS, Android',
          '그래픽': '3D Full View',
        },
        skills: [
          'cpp.png',
          'cpppp.png',
          'unreal.png',
          'mssql.png',
          'windows.png',
          'azure.png',
          'svn.png'
        ],
        description:
            '트라하 개발 초창기에 입사하여 서버의 시스템 설계 및 컨텐츠 관련 작업을 주로 진행하였습니다. 거의 대부분 C++ 로 작업을 진행하였고, 구현했던 컨텐츠를 기반으로, 넥슨 사에서 제공되는 운영툴 양식에 맞게 C# 으로 컨텐츠 내용을 연동하여 라이브 서비스에서 활용할 수 있도록 하는 작업을 담당하였습니다. 핵심 코어 코드들은 입사하기 전에 구현이 되어 있었고, 기존에 존재하는 코어 시스템 위에 이를 활용한 새 컨텐츠를 올리는 형태의 작업이 많았습니다. DB의 경우 MSSQL을 활용했었고, 프로시저를 미리 구현하여 필요한 때에 프로시저를 활용하는 형태로 사용하였습니다. 게임 출시는 4월 18일에 출시하여 퇴사를 할 때까지 라이브 서비스 또한 진행하였습니다.',
      ),
      Job(
        '퇴사',
        '2019.12.13',
        description:
            '회사의 경영난과 함께 대규모 구조조정이 진행되었습니다. 제가 대상자는 아니었지만 많은 분들께서 회사를 떠나게 되다보니 분위기도 많이 바뀌게 되고, 그에 따라 계속 회사 내에 있기 보다는 새로운 회사를 통해 더 많은 경험을 하는게 좋다고 생각되어 퇴사를 하게 되었습니다.',
        isFinal: true,
      ),
    ]),
  ];

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0, bottom: 20.0), // 상하단 여유 공간
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                Column(
                  children: companies.map((company) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CompanyCard(company: company),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10.0),
                _buildBottomButton(context),
                const SizedBox(height: 250.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Company {
  final String name;
  final String logo;
  final List<Job> jobs;
  final bool isCurrent;

  Company(this.name, this.logo, this.jobs, {this.isCurrent = false});
}

class Job {
  final String title;
  final String date;
  final Map<String, String>? projectInfo;
  final List<String>? skills;
  final String? description;
  final String? url;
  final bool isFinal;

  Job(
    this.title,
    this.date, {
    this.projectInfo,
    this.skills,
    this.description,
    this.url,
    this.isFinal = false,
  });

  List<String> get skillsImagePaths {
    return skills?.map((skill) => 'assets/images/$skill').toList() ?? [];
  }
}

class CompanyCard extends StatefulWidget {
  final Company company;

  const CompanyCard({super.key, required this.company});

  @override
  _CompanyCardState createState() => _CompanyCardState();
}

class _CompanyCardState extends State<CompanyCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Card(
      child: Column(
        children: [
          ListTile(
            title: GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(
                  children: [
                    Image.asset(widget.company.logo, width: 50, height: 50),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: themeProvider.themeMode == ThemeMode.light
                              ? Colors.grey.shade300
                              : Colors.grey.shade900,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 5),
                          child: Text(widget.company.name,
                              style: FontStyleYouandiModernTR.getStyle(
                                  context: context, fontSize: 28)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            trailing: AnimatedRotation(
              duration: const Duration(milliseconds: 300),
              turns: _isExpanded ? 0.5 : 0,
              child: IconButton(
                icon: const Icon(Icons.expand_more),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
            ),
          ),
          ClipRect(
            child: AnimatedAlign(
              alignment:
                  _isExpanded ? Alignment.topCenter : Alignment.bottomCenter,
              duration: const Duration(milliseconds: 1500),
              curve: Curves.bounceOut,
              heightFactor: _isExpanded ? 1 : 0,
              child: Column(
                children: [
                  if (widget.company.isCurrent)
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 23.0, top: 5.0, bottom: 5.0),
                      child: Row(
                        children: [
                          const Icon(Icons.badge, color: Colors.red, size: 36),
                          const SizedBox(width: 10),
                          Text('현재',
                              style: FontStyleNotoSans.getStyle(
                                  context: context,
                                  fontSize: 24,
                                  lightColor: Colors.red,
                                  darkColor: Colors.red)),
                        ],
                      ),
                    ),
                  Column(
                    children: widget.company.jobs.map((job) {
                      return ListTile(
                        title: Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Row(
                            children: [
                              const Icon(Icons.assistant,
                                  size: 28, color: Colors.blue),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 7.0),
                                  child: Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(job.title,
                                              style: FontStyleNotoSans.getStyle(
                                                  context: context,
                                                  fontSize: 18)),
                                          Text(job.date,
                                              style: FontStyleYouandiModernTR
                                                  .getStyle(
                                                      context: context,
                                                      fontSize: 14,
                                                      lightColor:
                                                          Colors.grey.shade700,
                                                      darkColor: Colors.grey)),
                                        ],
                                      ),
                                      const SizedBox(width: 5),
                                      if (job.url != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 8.0),
                                          child: GestureDetector(
                                            onTap: () async {
                                              final Uri url =
                                                  Uri.parse(job.url!);
                                              if (!await launchUrl(url,
                                                  mode: LaunchMode
                                                      .externalApplication)) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'URL을 열 수 없습니다.'),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: Colors.blue
                                                        .withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.open_in_new,
                                                  size: 20,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        subtitle: LayoutBuilder(
                          builder: (BuildContext context,
                              BoxConstraints constraints) {
                            return IntrinsicHeight(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (!job.isFinal)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 23.5),
                                        child: Container(
                                          width: 2.5,
                                          color: Colors.grey,
                                        ),
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 23.5),
                                        child: Container(
                                          width: 2.5,
                                          color: Colors.transparent,
                                        ),
                                      ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 10),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (job.projectInfo != null &&
                                                job.projectInfo!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 20),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              bottom: 10),
                                                      child: Text(
                                                        '프로젝트 정보',
                                                        style: FontStyleNotoSans
                                                            .getStyle(
                                                                context:
                                                                    context,
                                                                fontSize: 14),
                                                      ),
                                                    ),
                                                    ProjectInfoTable(
                                                        projectInfo:
                                                            job.projectInfo!),
                                                  ],
                                                ),
                                              ),
                                            if (job.skillsImagePaths.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 10),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text('사용 기술',
                                                        style: FontStyleNotoSans
                                                            .getStyle(
                                                                context:
                                                                    context,
                                                                fontSize: 14)),
                                                    const SizedBox(height: 10),
                                                    Wrap(
                                                      spacing: 8,
                                                      runSpacing: 8,
                                                      children: job
                                                          .skillsImagePaths
                                                          .map((skill) {
                                                        return Tooltip(
                                                          message: skill
                                                              .split('/')
                                                              .last
                                                              .split('.')
                                                              .first,
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(6),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: themeProvider
                                                                          .themeMode ==
                                                                      ThemeMode
                                                                          .light
                                                                  ? Colors.grey
                                                                      .shade200
                                                                  : Colors.grey
                                                                      .shade800,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                          0.1),
                                                                  blurRadius: 2,
                                                                  offset:
                                                                      const Offset(
                                                                          0, 1),
                                                                ),
                                                              ],
                                                            ),
                                                            child: Image.asset(
                                                              skill,
                                                              width: 60,
                                                              height: 60,
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (job.description != null)
                                              Container(
                                                width: double
                                                    .infinity, // 가로 길이를 끝까지 채우기
                                                decoration: BoxDecoration(
                                                  color: themeProvider
                                                              .themeMode ==
                                                          ThemeMode.light
                                                      ? Colors.grey.shade200
                                                      : Colors.grey
                                                          .shade800, // 배경색 설정
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10), // 모서리 둥글게
                                                ),
                                                padding: const EdgeInsets.all(
                                                    20.0), // 내부 여백
                                                child: Text(job.description!),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProjectInfoTable extends StatelessWidget {
  final Map<String, String> projectInfo;

  const ProjectInfoTable({super.key, required this.projectInfo});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Card(
      margin: EdgeInsets.zero, // 추가
      shape: RoundedRectangleBorder(
        // 추가
        borderRadius: BorderRadius.circular(8),
      ),
      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0), // 수정
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: projectInfo.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0), // 수정
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      entry.key,
                      style: FontStyleNotoSans.getStyle(
                        context: context,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        lightColor: Colors.black87,
                        darkColor: Colors.white70,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.value,
                      style: FontStyleNotoSans.getStyle(
                        context: context,
                        fontSize: 14,
                        lightColor: Colors.black54,
                        darkColor: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
