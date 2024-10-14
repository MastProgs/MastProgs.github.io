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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return _buildWideLayout();
            } else {
              return _buildNarrowLayout();
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
                  title: 'Introduce',
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
                  title: 'Contact',
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
                  title: 'Academics',
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
                CardWithTitle(
                  title: 'Skills',
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
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNarrowLayout() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          CardWithTitle(
            title: 'Introduce',
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
            title: 'Contact',
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
            title: 'Academics',
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
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        'assets/images/myface3.png',
        width: 150,
        height: 180,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildIntroduction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '게임이 좋아 QA를 시작으로 2013년 게임업계에 첫 발을 딛고, 현재는 $_year 년차가 된 서버 프로그래머 입니다. 다양한 게임을 장르 구분 없이 좋아하는 편이며, PC 모바일 및 콘솔 등 플랫폼 관련 없이 즐깁니다.',
          style: FontStyleNotoSans.getStyle(
            context: context,
            fontSize: 12,
            lightColor: Colors.grey.shade700,
            darkColor: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '프로그래머로서 항상 성장하기 위해 노력하고, C++20 같은 최신 표준에도 관심을 갖는 것은 기본이며, 언어에 제한을 두지 않고 학습하면서, 범용적 자질을 갖추기 위해 많은 기술적 노력을 기울이고 있습니다.',
          style: FontStyleNotoSans.getStyle(
            context: context,
            fontSize: 12,
            lightColor: Colors.grey.shade700,
            darkColor: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '게임 분야 뿐 아니라 AI 및 빅데이터, 클라우드, NFT, 블록체인 같은 사회적 이슈 기술에 대해 관심이 높고, 가지고 있는 지식을 적극적으로 실무에 활용하여 성공적으로 적용했을 때, 큰 성취를 느끼는 편입니다.',
          style: FontStyleNotoSans.getStyle(
            context: context,
            fontSize: 12,
            lightColor: Colors.grey.shade700,
            darkColor: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '이러한 성향으로 인하여, 단순 특정 컨텐츠만 반복 작성하고 하나의 작업만 부여받아 일하는 역할보다는 도전적인 문제를 해결해 나가며, 저와 같이 성장해 나갈 수 있는 팀과 회사를 관심 깊게 찾고 있습니다. 생산성 향상이나 코드 리팩토링, 또는 새롭고 도전적인 문제를 고민하고 해결하는 것을 선호합니다.',
          style: FontStyleNotoSans.getStyle(
            context: context,
            fontSize: 12,
            lightColor: Colors.grey.shade700,
            darkColor: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildActivities() {
    return const CardWithTitle(
      title: 'Activities',
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
}
