import 'package:flutter/material.dart';

import '../elements/row_skill_list.dart';
import '../elements/text_title.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final int yearGap = DateTime.now().year - 2017;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.person),
                const SizedBox(
                  width: 10,
                ),
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '재직 - 위메이드',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                      Text(
                        '이직 관심 있음',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            const Text('서버 프로그래머 - 김형준'),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text(
                  '최종 수정 날짜',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w100,
                  ),
                ),
                Text(
                  '2023.02.16',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w100,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: 1000,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                // 소개 설명

                Padding(
                  padding: const EdgeInsets.all(25),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40.0),
                        child: Image.asset(
                          'assets/images/myface2.png',
                          width: 300,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const TextTitle(
                                msg: '소개', size: 45, useDivider: false),
                            Container(
                              height: 1,
                              width: 600,
                              color: Colors.black,
                            ),
                            const SizedBox(height: 10),
                            Text(
                                '게임이 좋아 QA를 시작으로 2013년 게임업계 첫 발을 딛고, 현재는 $yearGap년차가 된 서버 프로그래머 입니다.'),
                            const Text(
                                '다양한 게임을 장르 구분 없이 좋아하는 편이며, PC 모바일 및 콘솔 등 플랫폼 관련 없이 즐깁니다.'),
                            const SizedBox(height: 10),
                            const Text(
                                '프로그래머로서 항상 성장하기 위해 노력하고, C++20 같은 최신 표준에도 관심을 갖는 것은 기본이며,'),
                            const Text(
                                '언어에 제한을 두지 않고 학습하여, 범용적 자질을 갖추기 위한 많은 기술적 노력을 기울입니다.'),
                            const SizedBox(height: 10),
                            const Text(
                                '게임 분야 뿐 아니라 AI 및 빅데이터, 클라우드, NFT, 블록체인 같은 사회적 이슈 기술에 대해 관심이 높고,'),
                            const Text(
                                '가지고 있는 지식을 적극적으로 실무에 활용하여 성공적으로 적용했을 시, 큰 성취를 느끼는 편입니다.'),
                            const SizedBox(height: 10),
                            const Text(
                                '이러한 성향으로 인하여, 단순 특정 컨텐츠만 반복 작성하고 하나의 작업만 부여받아 일하는 역할보다,'),
                            const Text(
                                '도전적인 문제를 해결해 나가며, 저와 같이 성장해 나갈 수 있는 팀과 회사를 관심 깊게 찾고 있습니다.'),
                            const Text(
                                '팀원들의 생산성 향상이나 코드 리팩토링 관련한 이슈에 관심이 더 크고, 어려운 문제해결을 좋아합니다.')
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // 주요 활용 가능 스킬
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      TextTitle(
                        msg: '주요 활용 가능 스킬',
                        size: 50,
                        useDivider: true,
                      )
                    ],
                  ),
                ),
                const RowSkillCard(
                  title: 'Language',
                  titleSize: 30,
                  elemList: [
                    'assets/images/cpp.png',
                    'assets/images/python.png',
                    'assets/images/golang.jpg',
                    'assets/images/cpppp.png',
                    'assets/images/js.png',
                    'assets/images/typescript.png',
                    'assets/images/flutter.png',
                    'assets/images/vue.png',
                  ],
                  descList: [
                    'C++ )',
                    'IOCP, Asio 서버 모델 같은 핵심 통신 알고리즘을 잘 이해하고 있고, 기본 프레임워크도 직접 개발 가능합니다. 최신 C++20 버전까지 활용 가능하며 format, ranges, string_view 등을 통해 구 C++11 버전의 소스를 최적화 및 최신화한 경험이 있습니다. MMORPG 개발 경험이 있으며 복잡한 시스템과 컨텐츠 구현 시, 가장 많이 사용했던 언어 입니다.',
                    'Python )',
                    '생산성 향상을 위해 다양한 툴 제작 시 적극 활용하는 언어이며, 툴 뿐만 아니라 Fast API Web Server 프레임워크를 직접 작성하고 서버를 만들어 서비스한 경험이 있습니다. 기타 툴은 SQL 문서 파일을 관리하는 매니징 툴이나 기획 xlsx 파일을 기반으로 Data Script Code Generator 등을 구현한 경험이 있습니다. 대학원에서 AI 모델 학습 활용하는 경험에 있어서 python 을 많이 사용하였습니다.',
                    'Golang )',
                    '언어의 활용 방식과 문법에 대해 잘 숙지하고 있으며, reflection 을 활용하여 orm 기능을 직접 구현한 경험이 있습니다. json 포멧의 데이터를 log server 로 넘기면, 데이터를 파싱하여 DB 테이블 데이터와 column 명을 검사하고 올바른 데이트가 insert 되도록 구현한 핸들러가 있으며, DB 의 다양한 job 들을 하나의 트랜젝션으로 묶어 작업을 보장하는 DBJob 의 기능을 구현한 경험이 있습니다.',
                    'C# )',
                    'WPF 같은 윈도우 방식에 익숙한 툴 작업이 가능하고, 기본적인 문법과 reflection 기능을 활용한 코드 구현 설계가 가능합니다. WPF 를 활용하여 부하테스트 툴을 만들어 본 경험이 있으며, 운영툴 서버 기능도 현 언어를 활용하여 구현한 경험이 있습니다.',
                    'Flutter / Vue )',
                    '기본적인 웹 프론트엔드를 구현할 수 있고, 현재 보고 있는 웹 프로필 또한 Flutter 로 구현되어 다양한 형태의 웹 페이지, Desktop App 등을 구현할 수 있습니다.',
                  ],
                ),
                const RowSkillCard(
                  title: 'Database',
                  titleSize: 30,
                  elemList: [
                    'assets/images/mssql.webp',
                    'assets/images/mysql.png',
                    'assets/images/mongo.png',
                    'assets/images/redis.jpg',
                  ],
                  descList: [
                    'MSSQL / MYSQL )',
                    '기본적인 쿼리를 작성할 수 있으며, 데이터 저장을 위한 테이블 설계 및 활용에 대해 잘 이해하고 있습니다.',
                    'Mongo DB )',
                    '관계형 데이터베이스 보다 더 빠른 응답속도를 받기 위해 활용하였으며, 캐싱, 로그 데이터 적재, 채팅 정보 등등을 활용하기 위해 사용한 경험이 있습니다.',
                    'Redis )',
                    '실시간 랭킹 시스템을 구현하거나, 인스타그램 기능 중 팔로잉 팔로우 같은 복잡한 시스템을 구현한 경험이 있습니다.',
                  ],
                ),
                const RowSkillCard(
                  title: 'Environment',
                  titleSize: 30,
                  elemList: [
                    'assets/images/vs.png',
                    'assets/images/vsc.png',
                    'assets/images/windows.png',
                    'assets/images/linux.png',
                    'assets/images/azure.jpg',
                    'assets/images/aws.png',
                  ],
                  descList: [
                    'Windows / Linux )',
                    '윈도우와 리눅스 환경 개발 경험이 존재하며 특별한 어려움 없이 환경설정 및 개발환경 셋팅을 할 수 있습니다.',
                    'Azure / AWS )',
                    '클라우드 서비스를 활용하여 서버를 띄울 수 있고, Cloud Compute, Cloud Database 같은 단순한 서비스 뿐만 아니라, Storage Service, AWS Flexmatch 등을 통한 복합적인 서비스 설계와 컨텐츠와 관련한 기능설계를 할 수 있습니다.',
                  ],
                ),
                const SizedBox(height: 500),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
