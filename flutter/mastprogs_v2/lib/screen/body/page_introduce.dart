import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mastprogs_v2/common/element/card_with_title.dart';
import 'package:mastprogs_v2/common/element/skill_section.dart';
import 'package:mastprogs_v2/common/element/url_button.dart';
import 'package:mastprogs_v2/common/font_style.dart';

class IntroduceScreen extends StatefulWidget {
  const IntroduceScreen({super.key});

  @override
  State<IntroduceScreen> createState() => _IntroduceScreenState();
}

class _IntroduceScreenState extends State<IntroduceScreen> {
  final String _year = (DateTime.now().year - 2017).toString();
  bool _isDarkMode = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return _buildWideLayout();
            } else {
              return _buildNarrowLayout(context);
            }
          },
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: min(constraints.maxWidth, 900),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                CardWithTitle(
                  title: '소개',
                  content: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildProfileImage(),
                      const SizedBox(width: 16),
                      Expanded(child: _buildIntroduction()),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CardWithTitle(
                  title: '연락처',
                  content: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.phone),
                              const SizedBox(width: 16),
                              Text(
                                '010-4140-0341',
                                style: FontStyleNotoSans.getStyle(
                                  context: context,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              const Icon(Icons.email),
                              const SizedBox(width: 16),
                              Text(
                                '_for@kakao.com',
                                style: FontStyleNotoSans.getStyle(
                                  context: context,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '편하게 연락 주시면 확인 후 답변 드리고 있습니다.',
                        style: FontStyleNotoSans.getStyle(
                          context: context,
                          fontSize: 12,
                          lightColor: Colors.grey.shade700,
                          darkColor: Colors.grey,
                        ),
                      ),
                      Text(
                        '간단한 회사 소개와 팀 내용 및 역할 정보를 공유주시면, 최대한 빠르게 확인 후 회신 드리도록 하겠습니다.',
                        style: FontStyleNotoSans.getStyle(
                          context: context,
                          fontSize: 12,
                          lightColor: Colors.grey.shade700,
                          darkColor: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CardWithTitle(
                  title: '학력',
                  content: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                '대학원',
                                style: FontStyleNotoSans.getStyle(
                                  context: context,
                                  fontSize: 24,
                                ),
                              ),
                              Image.asset(
                                'assets/images/kookmin.png',
                                fit: BoxFit.contain,
                                width: 150,
                                height: 150,
                              ),
                              Text(
                                '국민대학교 소프트웨어융합대학원',
                                style: FontStyleNotoSans.getStyle(
                                  context: context,
                                  fontSize: 12,
                                  lightColor: Colors.grey.shade700,
                                  darkColor: Colors.grey,
                                ),
                              ),
                              Text(
                                '인공지능 학과 석사 졸업',
                                style: FontStyleNotoSans.getStyle(
                                  context: context,
                                  fontSize: 12,
                                  lightColor: Colors.grey.shade700,
                                  darkColor: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '2021.03.01 ~ 2023.02.15',
                                style: FontStyleNotoSans.getStyle(
                                  context: context,
                                  fontSize: 12,
                                  lightColor: Colors.grey.shade700,
                                  darkColor: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '대학교',
                                style: FontStyleNotoSans.getStyle(
                                  context: context,
                                  fontSize: 24,
                                ),
                              ),
                              Image.asset(
                                'assets/images/tuk.png',
                                fit: BoxFit.contain,
                                width: 150,
                                height: 150,
                              ),
                              Text(
                                '한국공학대학 (구 한국산업기술대)',
                                style: FontStyleNotoSans.getStyle(
                                  context: context,
                                  fontSize: 12,
                                  lightColor: Colors.grey.shade700,
                                  darkColor: Colors.grey,
                                ),
                              ),
                              Text(
                                '게임공학과 4년제 학사 졸업',
                                style: FontStyleNotoSans.getStyle(
                                  context: context,
                                  fontSize: 12,
                                  lightColor: Colors.grey.shade700,
                                  darkColor: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '2015.03.01 ~ 2018.02.09',
                                style: FontStyleNotoSans.getStyle(
                                  context: context,
                                  fontSize: 12,
                                  lightColor: Colors.grey.shade700,
                                  darkColor: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '군력',
                                style: FontStyleNotoSans.getStyle(
                                  context: context,
                                  fontSize: 24,
                                ),
                              ),
                              Image.asset(
                                'assets/images/airforce.png',
                                fit: BoxFit.contain,
                                width: 150,
                                height: 150,
                              ),
                              Text(
                                '대한민국 공군',
                                style: FontStyleNotoSans.getStyle(
                                  context: context,
                                  fontSize: 12,
                                  lightColor: Colors.grey.shade700,
                                  darkColor: Colors.grey,
                                ),
                              ),
                              Text(
                                '병장 만기 전역',
                                style: FontStyleNotoSans.getStyle(
                                  context: context,
                                  fontSize: 12,
                                  lightColor: Colors.grey.shade700,
                                  darkColor: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '2010.11.22 ~ 2012.11.23',
                                style: FontStyleNotoSans.getStyle(
                                  context: context,
                                  fontSize: 12,
                                  lightColor: Colors.grey.shade700,
                                  darkColor: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildActivities(),
                const SizedBox(height: 16),
                _buildSkills(),
                const SizedBox(height: 16),
                _buildValue(),
                const SizedBox(height: 16),
                _buildBottomButton(context),
                const SizedBox(height: 250),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          CardWithTitle(
            title: '소개',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileImage(),
                const SizedBox(height: 16),
                _buildIntroduction(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CardWithTitle(
            title: '연락처',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone),
                    const SizedBox(width: 16),
                    Text(
                      '010-4140-0341',
                      style: FontStyleNotoSans.getStyle(
                        context: context,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.email),
                    const SizedBox(width: 16),
                    Text(
                      '_for@kakao.com',
                      style: FontStyleNotoSans.getStyle(
                        context: context,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '편하게 연락 주시면 확인 후 답변 드리고 있습니다.',
                  style: FontStyleNotoSans.getStyle(
                    context: context,
                    fontSize: 12,
                    lightColor: Colors.grey.shade700,
                    darkColor: Colors.grey,
                  ),
                ),
                Text(
                  '간단한 회사 소개와 팀 내용 및 역할 정보를 공유주시면, 최대한 빠르게 확인 후 회신 드리도록 하겠습니다.',
                  style: FontStyleNotoSans.getStyle(
                    context: context,
                    fontSize: 12,
                    lightColor: Colors.grey.shade700,
                    darkColor: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CardWithTitle(
            title: '학력',
            content: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/images/kookmin.png',
                      fit: BoxFit.contain,
                      width: 100,
                      height: 100,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '대학원',
                          style: FontStyleNotoSans.getStyle(
                            context: context,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '국민대학교 소프트웨어융합대학원',
                          style: FontStyleNotoSans.getStyle(
                            context: context,
                            fontSize: 12,
                            lightColor: Colors.grey.shade700,
                            darkColor: Colors.grey,
                          ),
                        ),
                        Text(
                          '인공지능 학과 석사 졸업',
                          style: FontStyleNotoSans.getStyle(
                            context: context,
                            fontSize: 12,
                            lightColor: Colors.grey.shade700,
                            darkColor: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '2021.03.01 ~ 2023.02.15',
                          style: FontStyleNotoSans.getStyle(
                            context: context,
                            fontSize: 12,
                            lightColor: Colors.grey.shade700,
                            darkColor: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/images/tuk.png',
                      fit: BoxFit.contain,
                      width: 100,
                      height: 100,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '대학교',
                          style: FontStyleNotoSans.getStyle(
                            context: context,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '한국공학대학 (구 한국산업기술대)',
                          style: FontStyleNotoSans.getStyle(
                            context: context,
                            fontSize: 12,
                            lightColor: Colors.grey.shade700,
                            darkColor: Colors.grey,
                          ),
                        ),
                        Text(
                          '게임공학과 4년제 학사 졸업',
                          style: FontStyleNotoSans.getStyle(
                            context: context,
                            fontSize: 12,
                            lightColor: Colors.grey.shade700,
                            darkColor: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '2015.03.01 ~ 2018.02.09',
                          style: FontStyleNotoSans.getStyle(
                            context: context,
                            fontSize: 12,
                            lightColor: Colors.grey.shade700,
                            darkColor: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/airforce.png',
                          fit: BoxFit.contain,
                          width: 100,
                          height: 100,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '군력',
                              style: FontStyleNotoSans.getStyle(
                                context: context,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '대한민국 공군',
                              style: FontStyleNotoSans.getStyle(
                                context: context,
                                fontSize: 12,
                                lightColor: Colors.grey.shade700,
                                darkColor: Colors.grey,
                              ),
                            ),
                            Text(
                              '병장 만기 전역',
                              style: FontStyleNotoSans.getStyle(
                                context: context,
                                fontSize: 12,
                                lightColor: Colors.grey.shade700,
                                darkColor: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '2010.11.22 ~ 2012.11.23',
                              style: FontStyleNotoSans.getStyle(
                                context: context,
                                fontSize: 12,
                                lightColor: Colors.grey.shade700,
                                darkColor: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildActivities(),
          const SizedBox(height: 16),
          _buildSkills(),
          const SizedBox(height: 16),
          _buildValue(),
          const SizedBox(height: 16),
          _buildBottomButton(context),
          const SizedBox(height: 250),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        'assets/images/myface3.png',
        width: 230 / 5 * 4,
        height: 230,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildIntroduction() {
    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey.shade900 : Colors.grey.shade300, // 배경색
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(15), // 내부 여백
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '게임이 좋아 QA를 시작으로 2013년 게임업계에 첫 발을 딛고, 현재는 $_year 년차가 된 서버 프로그래머 입니다. 다양한 게임을 장르 구분 없이 좋아하는 편이며, PC 모바일 및 콘솔 등 플랫폼 관련 없이 즐깁니다.',
            style: FontStyleNotoSans.getStyle(
              context: context,
              fontSize: 14,
              lightColor: Colors.grey.shade700,
              darkColor: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '프로그래머로서 항상 성장하기 위해 노력하고, C++20 같은 최신 표준에도 관심을 갖는 것은 기본이며, 언어에 제한을 두지 않고 학습하면서, 범용적 자질을 갖추기 위해 많은 기술적 노력을 기울이고 있습니다.',
            style: FontStyleNotoSans.getStyle(
              context: context,
              fontSize: 14,
              lightColor: Colors.grey.shade700,
              darkColor: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '게임 분야 뿐 아니라 AI 및 빅데이터, 클라우드, NFT, 블록체인 같은 사회적 이슈 기술에 대해 관심이 높고, 가지고 있는 지식을 적극적으로 실무에 활용하여 성공적으로 적용했을 때, 큰 성취를 느끼는 편입니다.',
            style: FontStyleNotoSans.getStyle(
              context: context,
              fontSize: 14,
              lightColor: Colors.grey.shade700,
              darkColor: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '이러한 성향으로 인하여, 단순 특정 컨텐츠만 반복 작성하고 하나의 작업만 부여받아 일하는 역할보다는 도전적인 문제를 해결해 나가며, 저와 같이 성장해 나갈 수 있는 팀과 회사를 관심 깊게 찾고 있습니다. 생산성 향상이나 코드 리팩토링, 또는 새롭고 도전적인 문제를 고민하고 해결하는 것을 선호합니다.',
            style: FontStyleNotoSans.getStyle(
              context: context,
              fontSize: 14,
              lightColor: Colors.grey.shade700,
              darkColor: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivities() {
    return const CardWithTitle(
      title: '기타 활동',
      content: Column(
        children: [
          UrlButton(
            imageAsset: 'assets/images/github.png',
            title: 'Github Codes',
            description: '다양한 서버 프레임 워크 및 작업 내용을 확인해 보실 수 있습니다.',
            url: 'https://github.com/mastprogs',
          ),
          SizedBox(height: 16),
          UrlButton(
            imageAsset: 'assets/images/naverpost.png',
            title: 'Naver Post',
            description: '코드 공부 및 개발 작업 과정을 컨텐츠로 확인해 볼 수 있습니다.',
            url:
                'https://post.naver.com/my/series/detail.nhn?seriesNo=370283&memberNo=559061',
          ),
          SizedBox(height: 16),
          UrlButton(
            imageAsset: 'assets/images/steam.png',
            title: 'Steam',
            description: '어떠한 게임들을 다양하게 오랜시간 즐겼는지 플레이 기록을 확인해 볼 수 있습니다.',
            url:
                'https://steamdb.info/calculator/76561198025794435/?cc=kr&all_games',
          ),
        ],
      ),
    );
  }

  Widget _buildSkills() {
    return CardWithTitle(
      title: '활용 가능 스킬',
      content: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '프로그래밍 언어 및 기술',
            style: FontStyleNotoSans.getStyle(
              context: context,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 16),
          SkillsSection(
            allSkills: [
              Skill(
                'C++',
                3,
                'IOCP, Asio 서버 모델 같은 핵심 통신 알고리즘을 잘 이해하고 있고, 기본 프레임워크도 직접 개발 가능합니다. 최신 C++20 버전까지 활용 가능하며, format, ranges, string_view 등을 통해 구 C++11 버전 소스를 최적화 및 최신화하여 생산성을 극대화 한 경험이 있습니다. MMORPG 개발 경험이 있으며, 복잡한 시스템과 컨텐츠 구현 시, 가장 많이 사용했던 언어 입니다.',
                ['assets/images/cpp.png'],
              ),
              Skill(
                'Python',
                3,
                '생산성 향상을 위해 다양한 툴 제작 시 적극 활용하는 언어 이며, 툴 뿐만 아니라 Fast API 웹 서버 프레임워크를 직접 작성하고 서버를 만들어 서비스한 경험이 있습니다. 파이썬으로 만들어 본 툴은 SQL 문서 파일을 관리하는 매니징 툴이나, 기획 xlsx 파일을 기반으로 Data Script Code Generator 등을 구현한 경험이 있습니다. 대학원에서 AI 모델 학습 활용하는 경험에 있어서 파이썬을 주 언어로 많이 사용한 경험이 있습니다.',
                ['assets/images/python.png'],
              ),
              Skill(
                'Go',
                3,
                '언어의 활용 방식과 문법에 대해 잘 숙지하고 있으며, reflection 을 활용하여 orm 기능을 직접 구현할 정도로 구조와 내용을 잘 이해하고 있습니다. json 포멧 데이터를 go 언어로 된 log server 로 넘기면, 해당 데이터를 파싱하여 DB 테이블 데이터와 column 명을 검사 후, 올바른 데이터가 insert 되도록 핸들러를 구현한 경험이 있습니다. 추가로 DB 의 다양한 job 들을 go 언어 상에서 하나의 트랜젝션으로 묶어 처리를 보장하는 DBJob 의 기능을 구현한 경험도 있습니다.',
                ['assets/images/go.png'],
              ),
              Skill(
                'C#',
                2,
                'WPF 같은 윈도우 방식에 익숙한 툴 작업이 가능하고, 기본적인 문법과 reflection 기능을 활용한 코드 구현 설계가 가능합니다. WPF 를 활용하여 부하테스트 툴을 만들어 본 경험이 있으며, 운영툴의 .Net framework 를 기반으로 한 서버에서 MMORPG 운영 기능을 연동하여 구현한 경험이 있습니다.',
                ['assets/images/cpppp.png'],
              ),
              Skill(
                'TypeScript',
                2,
                '타입스크립트를 활용하여 웹 프레임워크를 직접 작성하고 Node.js 를 활용하여 운영툴 및 게임 서버를 서비스한 경험이 있습니다.',
                ['assets/images/ts.png', 'assets/images/js.png'],
              ),
              Skill(
                'Flutter',
                2,
                '플러터를 활용하여 웹 프론트 및 모바일 앱을 직접 작성하고 서비스한 경험이 있습니다. 현재 보고 계신 웹 프로필 또한 Flutter 로 구현되어 다양한 형태의 웹 페이지, Desktop App 등을 구현할 수 있습니다.',
                ['assets/images/flutter.png'],
              ),
              Skill(
                'Vue, Electron',
                1,
                'Vue 를 활용하여 웹 프론트를 구현할 수 있으며, Electron 을 활용하여 Desktop App 을 개인 프로젝트 형태로 구현한 경험이 있습니다.',
                ['assets/images/vue.png', 'assets/images/electron.png'],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '데이터베이스',
            style: FontStyleNotoSans.getStyle(
              context: context,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 16),
          SkillsSection(
            allSkills: [
              Skill(
                'MSSQL, MySQL',
                3,
                '관계형 데이터베이스를 활용하여 MMORPG 게임 서버를 구현한 경험이 있으며, 많은 게임에서 익숙하게 활용한 경험이 있습니다. 테이블 설계 및 쿼리, 프로시저 작성 등 기본적인 사용법을 잘 이해하고 있습니다. 힌트 및 인덱스 등을 활용하여 최적화 하는 방법에 대한 이해가 있습니다.',
                ['assets/images/mssql.png', 'assets/images/mysql.png'],
              ),
              Skill(
                'Redis',
                3,
                '관계형 데이터베이스 보다 더 빠른 응답속도를 받기 위해 활용하였으며, 분~시간 단위 랭킹 시스템, SNS 팔로잉 팔로우, 캐싱, 채팅 컨텐츠 Pub/Sub 모델을 활용한 경험이 있습니다.',
                ['assets/images/redis.png'],
              ),
              Skill(
                'MongoDB',
                2,
                '휘발되어도 괜찮은 데이터를 기반으로 가볍게 사용하기 위해 활용한 경험이 있으며, 캐싱, 로그 데이터 적재, 채팅 데이터 적재 형태로 활용한 경험이 있습니다.',
                ['assets/images/mongodb.png'],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '개발 환경',
            style: FontStyleNotoSans.getStyle(
              context: context,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 16),
          SkillsSection(
            allSkills: [
              Skill(
                'VS, VSCode',
                3,
                'C++ 및 C# 개발시 Visual Studio 를 많이 사용했으며, 기타 언어 작업 시 VSCode 를 사용한 경험이 있습니다.',
                ['assets/images/vs.png', 'assets/images/vsc.png'],
              ),
              Skill(
                'Windows, Linux',
                3,
                'Windows 환경에서 주로 개발한 경험이 많으며, MMORPG 의 경우 Windows Server 에서 서비스 한 경험이 있습니다. 나머지 서버 개발은 특별한 경우가 아니라면 Linux 환경에서 서비스를 한 경험이 많습니다.',
                ['assets/images/windows.png', 'assets/images/linux.png'],
              ),
              Skill(
                'Git, SVN',
                2,
                '소스 코드 관리를 위해 많이 사용한 경험이 있으며, 협업 시 소스 코드 관리를 위해 많이 사용한 경험이 있습니다.',
                ['assets/images/git.png', 'assets/images/svn.png'],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'CI/CD',
            style: FontStyleNotoSans.getStyle(
              context: context,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 16),
          SkillsSection(
            allSkills: [
              Skill(
                'Cloud Workers/Pages',
                2,
                'release 할 github 소스 코드를 web frontend 페이지로 배포하기 위해, cloudflare workers 를 통해 배포 자동화한 경험이 있고, 각종 이메일 발송에 대한 정보를 slack 으로 보내는 것을 구현한 경험이 있습니다.',
                ['assets/images/cloudflare.png'],
              ),
              Skill(
                'GitHub Actions',
                2,
                '작업했던 소스 코드를 Github actions 를 통해 웹 사이트 자동 배포 및 Android aab 및 apk 파일 생성 등을 직접 구현한 경험이 있습니다.',
                ['assets/images/github_actions.png'],
              ),
              Skill(
                'Jenkins',
                2,
                '회사에서 사용하는 프로젝트의 CI/CD 파이프라인을 만들고 각종 빌드 및 배포 작업에 대한 스크립트를 작성한 경험이 있습니다.',
                ['assets/images/jenkins.png'],
              ),
              Skill(
                'Docker/Kubernetes',
                1,
                '도커에 대한 개념과 활용성에 대해서 이해하고 있으나, 현업에서 직접 사용한 경험은 없습니다.',
                ['assets/images/docker.png', 'assets/images/kubernetes.png'],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '클라우드 서비스',
            style: FontStyleNotoSans.getStyle(
              context: context,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 16),
          SkillsSection(
            allSkills: [
              Skill(
                'AWS',
                2,
                'AWS 의 활용성에 대해서 이해하고 있고, EC2, RDS, S3, Lambda, GameLift 등의 서비스를 활용한 경험이 있습니다.',
                ['assets/images/aws.png'],
              ),
              Skill(
                'Azure',
                2,
                'Azure 의 활용성에 대해서 이해하고 있으며, 단순 컴퓨팅 서비스와 데이터베이스 서비스를 활용한 경험이 있습니다.',
                ['assets/images/azure.png'],
              ),
              Skill(
                'Firebase',
                2,
                'Firebase 의 활용성에 대해서 이해하고 있고, 로그인 회원가입 등을 작업할 때, front 와 backend 를 직접 구현한 경험이 있습니다.',
                ['assets/images/firebase.png'],
              ),
              Skill(
                'Naver Cloud Platform',
                2,
                'Naver Cloud Platform 는 개인 프로젝트를 진행할 때, 서비스를 이용한 경험이 있습니다.',
                [
                  'assets/images/naver_cloud_platform.png',
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValue() {
    return CardWithTitle(
      title: '가치관',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '항상 성장을 추구하며 앞서가는 프로그래머',
            style: FontStyleNotoSans.getStyle(
              context: context,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? Colors.grey.shade900
                  : Colors.grey.shade300, // 배경색
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(15), // 내부 여백
            child: Text(
              '현재 이 순간에도 IT 기술들은 매우 발빠르게 성장하며 앞서나가고 있으며, 너무 방대한 발전 기술들이 쏟아지면서 하나의 지식을 익히기에도 오랜 시간과 열정이 필요하여 많은 학습을 요구하는 시대입니다. 이런 상황에서 늘 열린 자세로 새로운 신기술들을 익히기 위해 노력하며, 학습한 여러 기술과 정보들을 실무에 적용하기 위한 노력도 해보고, 관심있어 하시는 분들과 함께 공부한 내용을 공유하기도 합니다. 공부하고 알아갈 수 록 부족한 부분이 많다는 것을 깨닫기에, 언제나 겸손한 자세로 지식 뿐만 아니라 다른 여러 인문학적인 요소들도 스스로 채우려 노력합니다.',
              style: FontStyleNotoSans.getStyle(
                context: context,
                fontSize: 14,
                lightColor: Colors.grey.shade700,
                darkColor: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '격의 없는 커뮤니케이션과 열린 마음',
            style: FontStyleNotoSans.getStyle(
              context: context,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? Colors.grey.shade900
                  : Colors.grey.shade300, // 배경색
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(15), // 내부 여백
            child: Text(
              '프로젝트는 혼자 작업하지 않습니다. 기획적인 요청에 있어서 매번 다른 요구가 들어올 수 도 있으며, 동료 프로그래머 분들과 함께 작업하면서 많은 협업을 진행하게 됩니다. 매번 설계와 수정을 반복하면서 다양한 피드백을 받아 내고 유동적으로 움직이는 역할 또한 매우 중요하다는 사실을 알고 있습니다. 저는 언제나 여러 요청들에 대해 긍정적으로 수용할 자세가 되어있고 그 어느 의견이든지 종ㄴ중하려고 합니다. 이러한 자세가 저 스스로 뿐만 아니라 함께 성장하고 배울 수 있는 환경을 조성하고 조직 전체가 긍정적으로 나아갈 수 있는 방향이라고 생각합니다.',
              style: FontStyleNotoSans.getStyle(
                context: context,
                fontSize: 14,
                lightColor: Colors.grey.shade700,
                darkColor: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '믿고 함께 신뢰 할 수 있는 프로그래머',
            style: FontStyleNotoSans.getStyle(
              context: context,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? Colors.grey.shade900
                  : Colors.grey.shade300, // 배경색
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(15), // 내부 여백
            child: Text(
              '프로그래밍은 1과 0으로 이루어져있는 논리 연산입니다. 오류가 있다면 차근차근 풀어나가야 하며 이런 순서를 건너뛰고 누군가 마법처럼 해결해 주는 일은 없습니다. 덮어놓고 있는다고 하여 가려질 수 있는 직업도 아닙니다. 오류나 실수가 있다면 발빠르게 인정하고 최대한 신속하게 대응하며 만회하기 위해 노력합니다. 작업에 있어 항상 완벽하다고 보장할 수 는 없지만, 적어도 제 작업에 있어서 신뢰할 수 있는 프로그래머로 인정받을 수 있도록 노력을 많이 합니다. 동료로부터 믿음이 있어야 협업을 장애없이 이어 갈 수 있으며, 문제가 발견되었더라도 빠르게 오류를 보완하여 앞으로 나아갈 수 있다는 것을 잘 알고 있습니다.',
              style: FontStyleNotoSans.getStyle(
                context: context,
                fontSize: 14,
                lightColor: Colors.grey.shade700,
                darkColor: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '기여할 일을 찾아서 하는 프로그래머',
            style: FontStyleNotoSans.getStyle(
              context: context,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? Colors.grey.shade900
                  : Colors.grey.shade300, // 배경색
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(15), // 내부 여백
            child: Text(
              '회사의 주 업무 뿐만 아니라 팀원의 생산성 향상에 기여하거나, 코드 리팩토링 작업을 통한 개선을 하는 등, 저 스스로의 목표를 세우고 원하는 목표를 달성하는 것을 선호합니다. 그러다 보니 신규 개발 기능과 다양한 목표를 설계하며 개선하고, 도전적이고 신선한 업무들을 작업하면서, 함께 배우고 성장하길 원하는 팀을 선호합니다. 가끔 이런 분위기를 싫어하거나 현재 상태를 최대한 바꾸지 않고 평상시의 상황을 유지하길 좋아하는 팀의 경우, 제가 회사에 기여할 수 있는 역할은 회사에서 업무가 할당된 주 컨텐츠 작업 등 밖에 없으므로 개인 퍼포먼스의 최대 효과를 낼 수 없다는 것을 잘 알고 있기에, 모두가 함께 성장하고자 하는 회사나 팀을 선호합니다.',
              style: FontStyleNotoSans.getStyle(
                context: context,
                fontSize: 14,
                lightColor: Colors.grey.shade700,
                darkColor: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 맨 위로 가는 버튼 추가
        ElevatedButton(
          onPressed: () {
            // 페이지의 맨 위로 스크롤
            Scrollable.of(context).position.jumpTo(0);
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
}
