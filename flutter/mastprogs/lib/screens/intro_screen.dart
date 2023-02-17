import 'package:flutter/material.dart';

import '../elements/desc_box.dart';
import '../elements/img_url_button.dart';
import '../elements/row_skill_list.dart';
import '../elements/text_title.dart';

class IntroScreen extends StatelessWidget {
  final int yearGap = DateTime.now().year - 2017;
  final double basicPaddingSize = 25;

  IntroScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                      padding:
                          EdgeInsets.symmetric(horizontal: basicPaddingSize),
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

              const SizedBox(height: 10),

              // 전화 번호, 이메일, 학력
              Padding(
                padding: EdgeInsets.all(basicPaddingSize),
                child: Column(
                  children: [
                    const TextTitle(msg: '기본 정보', size: 45, useDivider: true),
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.phone,
                              color: Colors.grey,
                              size: 40,
                            ),
                            const SizedBox(width: 20),
                            Container(
                              alignment: Alignment.center,
                              width: 300,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(5)),
                                border: Border.all(
                                  width: 2,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Text('０１０ · ４１４０ · ０３４１'),
                              ),
                            ),
                            const SizedBox(width: 50),
                            const Icon(
                              Icons.email,
                              color: Colors.grey,
                              size: 40,
                            ),
                            const SizedBox(width: 20),
                            Container(
                              width: 300,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(5)),
                                border: Border.all(
                                  width: 2,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      '_ f o r  ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    Icon(
                                      Icons.alternate_email,
                                      size: 16,
                                    ),
                                    Text(
                                      '  k a k a o . c o m',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 50),
                          child: Text('편하게 연락 주시면 확인 후 답변 드리고 있습니다.'),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 50),
                          child: Text(
                              '간단한 회사 소개와 팀 내용 및 역할 정보를 공유주시면, 최대한 빠르게 확인 후 회신 드리도록 하겠습니다.'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            const TextTitle(
                                msg: '대학교', size: 35, useDivider: false),
                            Image.asset(
                              'assets/images/tuk.jpg',
                              height: 150,
                            ),
                            const SizedBox(height: 10),
                            const Text('한국공학대학 (구 한국산업기술대)'),
                            const Text('게임공학과 4년제 학사 졸업'),
                            const SizedBox(height: 10),
                            const Text('2015.03.01 ~ 2018.02.09'),
                          ],
                        ),
                        const SizedBox(width: 50),
                        Column(
                          children: [
                            const TextTitle(
                                msg: '대학원', size: 35, useDivider: false),
                            Image.asset(
                              'assets/images/kookmin.png',
                              width: 300,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 10),
                            const Text('국민대학교 소프트웨어융학대학원'),
                            const Text('인공지능과 석사 졸업'),
                            const SizedBox(height: 10),
                            const Text('2021.03.01 ~ 2023.02.15'),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            const TextTitle(
                                msg: '군력', size: 35, useDivider: false),
                            Image.asset(
                              'assets/images/airforce.png',
                              height: 150,
                            ),
                            const SizedBox(height: 10),
                            const Text('대한민국 공군'),
                            const Text('병장 만기 전역'),
                            const SizedBox(height: 10),
                            const Text('2010.11.22 ~ 2012.11.23'),
                          ],
                        ),
                        const SizedBox(width: 20),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 기타 외부 페이지
              Padding(
                padding: EdgeInsets.all(basicPaddingSize),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    ImgButtonUrl(
                      imgPath: 'assets/images/github.png',
                      url: 'https://github.com/MastProgs',
                      imgSize: 50,
                    ),
                    SizedBox(width: 15),
                    ImgButtonUrl(
                      imgPath: 'assets/images/naverpost.png',
                      url:
                          'https://post.naver.com/my/series/detail.nhn?seriesNo=370283&memberNo=559061',
                      imgSize: 50,
                    ),
                    SizedBox(width: 15),
                    ImgButtonUrl(
                      imgPath: 'assets/images/steam.png',
                      url:
                          'https://steamdb.info/calculator/76561198025794435/?cc=kr',
                      imgSize: 50,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),
              // 주요 활용 가능 스킬
              Padding(
                padding: EdgeInsets.symmetric(horizontal: basicPaddingSize),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    TextTitle(
                      msg: '주요 활용 가능 스킬',
                      size: 45,
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
                  'assets/images/electron.png',
                ],
                descList: [
                  '[ C++ ]',
                  'IOCP, Asio 서버 모델 같은 핵심 통신 알고리즘을 잘 이해하고 있고, 기본 프레임워크도 직접 개발 가능합니다. 최신 C++20 버전까지 활용 가능하며 format, ranges, string_view 등을 통해 구 C++11 버전의 소스를 최적화 및 최신화하여 생산성을 극대화한 경험이 있습니다. MMORPG 개발 경험이 있으며 복잡한 시스템과 컨텐츠 구현 시, 가장 많이 사용했던 언어 입니다.',
                  '[ Python ]',
                  '생산성 향상을 위해 다양한 툴 제작 시 적극 활용하는 언어이며, 툴 뿐만 아니라 Fast API Web Server 프레임워크를 직접 작성하고 서버를 만들어 서비스한 경험이 있습니다. 기타 툴은 SQL 문서 파일을 관리하는 매니징 툴이나 기획 xlsx 파일을 기반으로 Data Script Code Generator 등을 구현한 경험이 있습니다. 대학원에서 AI 모델 학습 활용하는 경험에 있어서 python 을 주 언어로 많이 사용하였습니다.',
                  '[ Golang ]',
                  '언어의 활용 방식과 문법에 대해 잘 숙지하고 있으며, reflection 을 활용하여 orm 기능을 직접 구현한 경험이 있습니다. json 포멧의 데이터를 log server 로 넘기면, 데이터를 파싱하여 DB 테이블 데이터와 column 명을 검사하고 올바른 데이트가 insert 되도록 구현한 핸들러가 있으며, DB 의 다양한 job 들을 하나의 트랜젝션으로 묶어 작업을 보장하는 DBJob 의 기능을 구현한 경험이 있습니다.',
                  '[ C# ]',
                  'WPF 같은 윈도우 방식에 익숙한 툴 작업이 가능하고, 기본적인 문법과 reflection 기능을 활용한 코드 구현 설계가 가능합니다. WPF 를 활용하여 부하테스트 툴을 만들어 본 경험이 있으며, 운영툴 서버 기능도 현 언어를 활용하여 구현한 경험이 있습니다.',
                  '[ Flutter / Vue / Electron ]',
                  '기본적인 웹 프론트엔드를 구현할 수 있고, 현재 보고 있는 웹 프로필 또한 Flutter 로 구현되어 다양한 형태의 웹 페이지, Desktop App 등을 구현할 수 있습니다.',
                ],
              ),
              const RowSkillCard(
                title: 'Database',
                titleSize: 30,
                elemList: [
                  'assets/images/mssql.png',
                  'assets/images/mysql.png',
                  'assets/images/mongo.png',
                  'assets/images/redis.jpg',
                ],
                descList: [
                  '[ MSSQL / MYSQL ]',
                  '기본적인 쿼리를 작성할 수 있으며, 데이터 저장을 위한 테이블 설계 및 활용에 대해 잘 이해하고 있습니다.',
                  '[ Mongo DB ]',
                  '관계형 데이터베이스 보다 더 빠른 응답속도를 받기 위해 활용하였으며, 캐싱, 로그 데이터 적재, 채팅 정보 등등을 활용하기 위해 사용한 경험이 있습니다.',
                  '[ Redis ]',
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
                  '[ Visual Studio & Code ]',
                  '비주얼 스튜디오와 비주얼 스튜디오 코드를 통한 통합 개발 환경을 기반으로 개발을 해왔습니다. 기본적인 설정과 프리셋, 언어별 개발 도구들을 준비하고 활용할 수 있습니다.',
                  '[ Windows / Linux ]',
                  '윈도우와 리눅스 환경 개발 경험이 존재하며 특별한 어려움 없이 환경설정 및 개발환경 셋팅을 할 수 있습니다.',
                  '[ Azure / AWS ]',
                  '클라우드 서비스를 활용하여 서버를 띄울 수 있고, Cloud Compute, Cloud Database 같은 단순한 서비스 뿐만 아니라, Storage Service, AWS Flexmatch 등을 통한 복합적인 서비스 설계와 컨텐츠와 관련한 기능설계를 할 수 있습니다.',
                ],
              ),

              const SizedBox(height: 50),

              // 가치관
              Padding(
                padding: EdgeInsets.symmetric(horizontal: basicPaddingSize),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    TextTitle(
                      msg: '가치관',
                      size: 45,
                      useDivider: true,
                    ),
                    SizedBox(height: 10),
                    DescriptionBox(
                      title: '항상 성장을 추구하며 앞서가는 프로그래머',
                      titleSize: 20,
                      desc:
                          '현재 이 순간에도 IT 기술들은 매우 발빠르게 성장하며 앞서나가고 있으며, 너무 방대한 발전 기술들이 쏟아지면서 하나의 지식을 익히기에도 오랜 시간과 열정이 필요하여 많은 학습을 요구하는 시대입니다. 이런 상황에서 늘 열린 자세로 새로운 신기술들을 익히기위해 노력하며, 학습한 여러 기술과 정보들을 실무에 적용하기 위한 노력도 해보고, 관심있어 하시는 분들과 함께 공부한 내용을 공유하기도 합니다. 공부하고 알아갈 수록 부족한 부분이 많다는 것을 깨닫기에, 언제나 겸손한 자세로 지식 뿐만 아니라 다른 여러 인문학적인 요소들도 스스로 채우려 노력합니다.',
                    ),
                    SizedBox(height: 40),
                    DescriptionBox(
                      title: '격의 없는 커뮤니케이션과 열린 마음',
                      titleSize: 20,
                      desc:
                          '프로젝트는 혼자 작업하지 않습니다. 기획적인 요청에 있어서 매번 다른 요구가 들어올 수 도 있으며, 동료 프로그래머 분들과 함께 작업하면서 많은 협업을 진행하게 됩니다. 매번 설계와 수정을 반복하면서 다양한 피드백을 받아 내고 유동적으로 움직이는 역할 또한 매우 중요하다는 사실을 알고 있습니다. 저는 언제나 여러 요청들에 대해 긍정적으로 수용할 자세가 되어있고 그 어느 의견이든지 존중하려고 합니다. 이러한 자세가 저 스스로 뿐만 아니라 함께 성장하고 배울 수 있는 환경을 조성하고 조직 전체가 긍정적으로 나아갈 수 있는 방향이라고 생각합니다.',
                    ),
                    SizedBox(height: 40),
                    DescriptionBox(
                      title: '믿고 함께 신뢰 할 수 있는 프로그래머',
                      titleSize: 20,
                      desc:
                          '프로그래밍은 1과 0으로 이루어져있는 논리 연산입니다. 오류가 있다면 차근차근 풀어나가야 하며 이런 순서를 건너뛰고 누군가 마법처럼 해결해 주는 일은 없습니다. 덮어놓고 있는다고 하여 가려질 수 있는 직업도 아닙니다. 오류나 실수가 있다면 발빠르게 인정하고 최대한 신속하게 대응하고 만회하기 위해 노력합니다. 작업에 있어 항상 완벽하다고 보장할 수는 없지만, 적어도 제 작업에 있어서 신뢰할 수 있는 프로그래머로 인정받을 수 있도록 노력을 많이 합니다. 동료로부터 믿음이 있어야 협업을 장애없이 이어 갈 수 있으며, 문제가 발견되었더라도 빠르게 오류를 보완하여 앞으로 나아갈 수 있다는 것을 잘 알고 있습니다.',
                    ),
                    SizedBox(height: 40),
                    DescriptionBox(
                      title: '자기계발 시간확보가 필요한 프로그래머',
                      titleSize: 20,
                      desc:
                          '불필요한 야근을 지양하는 것을 첫번째로 생각합니다. 작업상황에 따른 일이 몰려 야근하거나, 개인적인 성취 욕구에 야근을 하게 되는 경우가 있어서, 항상 구성원 역할에 최선을 다 합니다. 하지만 야근의 종류가 모호한 지시사항이나, 비효율적인 프로세스, 비정상적인 일정산정에 따른 경우라면 제가 추구하는 업무 환경은 아닙니다. 적당한 개인적인 시간이 주어져야 자기계발도 가능하고, 지속적인 자기계발이 회사의 성장과 더불어 함께 성장할 수 있는 환경이라고 생각하기 때문입니다. 상황상 어쩔수 없이 팀 모두 함께 해야하는 경우에 대해 부정하지는 않으나, 개인의 성과는 곧 야근이라고 당연 시 생각하는 가치관은 저와 반대됩니다. 지속적인 야근은 저 스스로의 퍼포먼스를 높게 유지하기 어렵게 만들고 회사의 성장에도 기여하기 어려운 점을 잘 알고 있기 때문입니다.',
                    ),
                    SizedBox(height: 40),
                    DescriptionBox(
                      title: '기여할 일을 찾아서 하는 프로그래머',
                      titleSize: 20,
                      desc:
                          '회사의 주 업무보다는 팀원의 생산성 향상에 기여하거나, 코드 리팩토링 작업을 통한 개선을 하는 등, 저 스스로의 목표를 세우고 원하는 목표를 달성하는 것을 선호합니다. 그러다 보니 라이브 서비스의 작업자로 들어가는 것 보다는 신규 개발팀에서 원하는 기능과 목표를 설계하여 개선하고, 도전적이며 새로운 업무들을 작업하면서, 함께 배우고 성장하길 원하는 팀을 선호합니다. 가끔 이런 분위기를 싫어하시거나 현재 상태를 최대한 바꾸지 않고 평상시의 상황을 유지하길 좋아하는 팀의 경우, 제가 회사에 기여할 수 있는 역할은 회사에서 업무가 할당된 주 컨텐츠 작업 등 밖에 없으므로 개인 퍼포먼스의 최대 효과를 낼 수 없기에, 모두가 함께 성장하고자 하는 회사를 선호합니다.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 500),
            ],
          ),
        ),
      ),
    );
  }
}
