import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mastprogs_v2/common/element/card_with_title.dart';
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
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return _buildWideLayout();
          } else {
            return _buildNarrowLayout();
          }
        },
      ),
    );
  }

  Widget _buildWideLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Padding(
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
          ],
        ),
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
}
