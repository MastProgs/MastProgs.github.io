import 'package:flutter/material.dart';
import 'package:mastprogs/elements/text_title.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkHistory extends StatelessWidget {
  const WorkHistory({super.key});

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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const TextTitle(
                        msg: '위메이드 플러스', size: 25, useDivider: true),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const WorkBoxBasic(
                            w: 225,
                            h: 225,
                            backColor: Colors.white,
                            headText: 'FastAPI 서버 구현',
                            headSize: 22,
                            bodyText:
                                'Fast API 의 속도가 일반 Node.js 보다 훨씬 빠르며 Go 서버에 가까이 성능이 나온다는 사실을 확인하고, 최신 프레임워크를 실무에 적용했습니다.',
                            children: [
                              Spacer(),
                              CardUrlButton(
                                msg: 'Python',
                                icon: Icons.code,
                                color: Colors.cyan,
                                url:
                                    'https://github.com/MastProgs/fast-api-framework',
                              ),
                            ]),
                        WorkBoxBasic(
                          w: 225,
                          h: 225,
                          backColor: Colors.grey.shade200,
                          headText: 'Code Generator',
                          headSize: 22,
                          bodyText:
                              'xlsx 파일을 그대로 읽어서, 코드로 작성해주는 툴. 기획 데이터를 json 으로 수동으로 변환하여 서버에 올리는 복잡한 작업을 자동화했습니다. ',
                          children: const [
                            Spacer(),
                            CardUrlButton(
                              msg: 'Python',
                              icon: Icons.code,
                              color: Colors.cyan,
                              url:
                                  'https://github.com/MastProgs/fast-api-framework/blob/main/auto_code_generator.py',
                            ),
                          ],
                        ),
                        Container(
                          width: 470,
                          height: 225,
                          decoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(15)),
                            border: Border.all(
                              width: 1,
                              color: Colors.grey.shade300,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                offset: const Offset(2, 2),
                                blurRadius: 2.0,
                                spreadRadius: 1,
                              ),
                              const BoxShadow(
                                color: Colors.white,
                                offset: Offset(-2, -2),
                                blurRadius: 2.0,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.engineering,
                            size: 200,
                            color: Colors.grey,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        WorkBoxBasic(
                          w: 225,
                          h: 225,
                          backColor: Colors.grey.shade100,
                          headText: '채팅 서버 구현',
                          headSize: 22,
                          bodyText:
                              'MQTT 기술을 활용하여 채팅 서버를 구현하였습니다. Broker 서버를 통해 메세지를 주고 받고, Redis 에 다양한 채팅 대화 및 방 생성 정보를 저장하며 활용하였습니다.',
                        ),
                        WorkBoxBasic(
                          w: 470,
                          h: 225,
                          backColor: Colors.white,
                          headText: 'DBJob 로직 구현',
                          headSize: 22,
                          bodyText:
                              'TypeORM 을 활용하여, Save / Update / Delete / Increase / Decrease 같은 DB에 요청해야하는 다중 쿼리문과 Redis 에 요청해야하는 다양한 request 들을 한번의 트랜잭션으로 묶어 요청할 수 있도록 코드로 구현하였습니다. ( Go언어의 경우 reflection 을 활용한 TypeORM을 직접 구현 )',
                          children: [
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                CardUrlButton(
                                  msg: 'Go',
                                  icon: Icons.code,
                                  color: Colors.cyan,
                                  url:
                                      'https://github.com/MastProgs/custom-codes/blob/main/ezDB.go',
                                ),
                                SizedBox(width: 5),
                                CardUrlButton(
                                  msg: 'Go',
                                  icon: Icons.description_outlined,
                                  color: Colors.cyan,
                                  url: 'https://naver.me/xoL4jPs4',
                                ),
                                SizedBox(width: 10),
                                CardUrlButton(
                                  msg: 'TS',
                                  icon: Icons.code,
                                  color: Colors.cyan,
                                  url:
                                      'https://github.com/MastProgs/custom-codes/blob/main/DBJob.ts',
                                ),
                                SizedBox(width: 5),
                                CardUrlButton(
                                  msg: 'TS',
                                  icon: Icons.description_outlined,
                                  color: Colors.cyan,
                                  url:
                                      'https://github.com/MastProgs/custom-codes#dbjobts',
                                ),
                              ],
                            )
                          ],
                        ),
                        WorkBoxBasic(
                          w: 225,
                          h: 225,
                          backColor: Colors.grey.shade200,
                          headText: 'C++20 으로 최신화',
                          headSize: 22,
                          bodyText:
                              '과거 서비스 종료 했던 C++11 게임서버를 C++20 으로 다시 버전업을 하여, 최신 문법으로 포팅하는 작업을 하였습니다.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        WorkBoxBasic(
                          w: 470,
                          h: 225,
                          backColor: Colors.white,
                          headText: 'Pager 프로세스',
                          headSize: 22,
                          bodyText:
                              'SNS 에서 스크롤링 및 페이지 형태로 데이터를 가져오는 기법인 Pagination 라이브러리를 훨씬 더 사용하기 쉽게 랩핑한 클래스입니다. TypeORM 의 Select 구문을 Pager 에 초기화 값으로 넣어주고, DB에서 읽은 책갈피 위치에 대한 Hash 값을 같이 넣고 실행시키면, 다음 위치의 Hash 값과 다음 data limit size 만큼 값을 반환하는 클래스 입니다.',
                          children: [
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                CardUrlButton(
                                  msg: 'TS',
                                  icon: Icons.code,
                                  color: Colors.cyan,
                                  url:
                                      'https://github.com/MastProgs/custom-codes/blob/main/Pager.ts',
                                ),
                                SizedBox(width: 5),
                                CardUrlButton(
                                  msg: 'TS',
                                  icon: Icons.description_outlined,
                                  color: Colors.cyan,
                                  url:
                                      'https://github.com/MastProgs/custom-codes#pagerts',
                                ),
                              ],
                            ),
                          ],
                        ),
                        WorkBoxBasic(
                          w: 225,
                          h: 225,
                          backColor: Colors.grey.shade200,
                          headText: 'C# 부하테스트 툴',
                          headSize: 22,
                          bodyText:
                              'UWP & C# 을 활용하여 부하테스트 툴을 구현하였습니다. IP & Port, Thread, 반복, 딜레이 옵션등을 활용하여 서버 부하테스트를 할 수 있는 툴입니다.',
                          children: const [
                            Spacer(),
                            CardImgButton(
                              msg: 'C#',
                              icon: Icons.image_outlined,
                              color: Colors.cyan,
                              path: 'assets/images/UwpStressTool.png',
                            ),
                          ],
                        ),
                        WorkBoxBasic(
                          w: 225,
                          h: 225,
                          backColor: Colors.white,
                          headText: 'Redis 핸들러 구현',
                          headSize: 22,
                          bodyText:
                              '기존 구현되어있던 redis 핸들러가 문제가 많아 새로 구현하였습니다. cpp_redis 오픈 소스를 활용하여 간편하게 활용가능하게 변경했습니다.',
                          children: [
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                CardUrlButton(
                                  msg: 'C++',
                                  icon: Icons.code,
                                  color: Colors.cyan,
                                  url:
                                      'https://github.com/MastProgs/None_boost_Asio/tree/master/C%2B%2B20%20Asio/CoroutineAsioCpp20/Core/Redis',
                                ),
                                SizedBox(width: 5),
                                CardUrlButton(
                                  msg: 'C++',
                                  icon: Icons.description_outlined,
                                  color: Colors.cyan,
                                  url:
                                      'https://github.com/MastProgs/None_boost_Asio#redis',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        WorkBoxBasic(
                          w: 225,
                          h: 225,
                          backColor: Colors.grey.shade200,
                          headText: '문자열 변환 핸들러',
                          headSize: 22,
                          bodyText:
                              'Unicode, Multibyte, UTF-8, string, wstring, CString, CStringA 문자열을 섞어 쓰는 구 코드 문제로 변환 이슈를 제거하기 위해 구현하게 되었습니다.',
                          children: const [
                            Spacer(),
                            CardUrlButton(
                              msg: 'C++',
                              icon: Icons.code,
                              color: Colors.cyan,
                              url:
                                  'https://github.com/MastProgs/None_boost_Asio/blob/master/C%2B%2B20%20Asio/CoroutineAsioCpp20/Common/String/ToStr.h',
                            ),
                          ],
                        ),
                        const WorkBoxBasic(
                          w: 715,
                          h: 225,
                          backColor: Colors.white,
                          headText: 'Log Server 구현',
                          headSize: 22,
                          bodyText:
                              '사업팀에서 필요로 하는 로그를 적재해야하는 요청이 있어서 구현하게 되었습니다. 게임서버에서 필요한 여러 객체들에 대한 정보를 합산하여 Json 화 시키고, 해당 Json 을 Log Server로 전송하면, Log Server 에서 DB 의 테이블 컬럼 정보를 가져와 검증 한 뒤, 필요한 정보들만 뽑아 쿼리로 만들어 DB 에 insert 하는 구조입니다. 이를 통해 게임서버에서는 정보를 남겨야 하는 시점에 필요한 객체들을 ToJson() 함수로 받아 합산하여 Log Server로 날리기만 하면 되었고, log DB Table 구조와는 상관없이 서버 배포도 자유롭고, 어떤 로그이건 동일한 프로세스 처리가 가능해 생산성에 좋았습니다.',
                          children: [
                            Spacer(),
                            CardImgButton(
                              msg: 'C++ & Go',
                              icon: Icons.image_outlined,
                              color: Colors.cyan,
                              path: 'assets/images/LogServerArchi.png',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: const [
                        WorkBoxBasic(
                          w: 960,
                          h: 225,
                          backColor: Colors.white,
                          headText: '날짜시간 통합 관리',
                          headSize: 22,
                          bodyText:
                              '과거 코드는 local time 과 utc time 이 혼재되어 사용되어 있었고, 이를 통합하여 활용하기 위해 기본적으로 표준 utc 표준대로 통합하는 처리를 하였습니다. string, time_point 를 변환하거나, 필요한 시간 값들의 연산 및 추출하는 형태로 생산성을 향상시켰습니다. 추가로 주간 이벤트 시간 처리가 매번 기획자 분들께서 스크립트로 입력해주어야 하는 부분을, week_hh_mm_ss 라는 클래스를 구현하여 특정 요일의 시분초를 계산하는 클래스를 구현하였습니다. week_hh_mm_ss 클래스와 특정 시각을 조합하면, 해당 주차의 특정 요일의 시간분초 time_point 를 계산하여 가져오거나, week_hh_mm_ss 클래스를 서로 비교 연산하여 전후 시각을 알 수 있도록 구현해두어, 매주 이벤트 시간 관리에 편의성을 더했습니다.',
                          children: [
                            Spacer(),
                            CardUrlButton(
                              msg: 'C++',
                              icon: Icons.code,
                              color: Colors.cyan,
                              url:
                                  'https://github.com/MastProgs/None_boost_Asio/blob/master/C%2B%2B20%20Asio/CoroutineAsioCpp20/Common/Datetime/Datetime.h',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const TextTitle(msg: '조이시티', size: 25, useDivider: true),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const WorkBoxBasic(
                          w: 470,
                          h: 225,
                          backColor: Colors.white,
                          headText: '개발망 클라 런처',
                          headSize: 22,
                          bodyText:
                              '각 국가 버전별 실행 명령인자 값이 다르고, id pw ip port 등등 여러 정보를 매 실행마다 수동으로 입력하여 클라를 실행해야하는 시스템이라 불편했었습니다. 자동화 작업으로 버튼 몇 개만 누르면 입맛에 맞는 실행 명령을 입력하여 개발망 클라이언트를 구동시킬 수 있는 런처 툴을 제작하여 나눠드렸고, 개발 시간 단축에 힘을 보탰습니다.',
                        ),
                        WorkBoxBasic(
                          w: 470,
                          h: 225,
                          backColor: Colors.grey.shade200,
                          headText: '개발망 아이템 지급 툴',
                          headSize: 22,
                          bodyText:
                              '개발 과정 중에 필요한 아이템이나 캐릭터 셋팅에 필요한 부분들을 매번 서버 프로그래머에 요청하는 프로세스로 작업을 하기에 비효율적이었습니다. 자동화 작업으로 필요한 버튼 몇 개만 누르면 아이템 지급이나 캐릭터 상태에 대한 셋팅을 진행할 수 있도록 툴을 제작하여 나눠드렸고, 개발 시간 단축에 힘을 보탰습니다.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const TextTitle(msg: '한빛소프트', size: 25, useDivider: true),
                    Row(
                      children: const [
                        WorkBoxBasic(
                          w: 960,
                          h: 225,
                          backColor: Colors.white,
                          headText: 'AWS GameLift Flexmatch',
                          headSize: 22,
                          bodyText:
                              '클라이언트가 로비 서버에서 매치메이킹을 신청하면 이를 웹 서버로 전달하고, 웹 서버는 AWS에 기능을 요청하여 관련 유니크한 티켓을 받아 매치메이킹에 대한 정보를 중개하는 역할을 구현하였습니다. 매칭이 이루어 진다면 GameLift 내의 임의 데디서버에 방을 생성하여 주고, 연결에 필요한 정보들을 파싱하여 각 클라이언트에게 정보를 건네주는 순서로 진행되었습니다. AWS SNS 같은 기능을 활용하여 반복적인 loop 부분을, 매칭 되었을 시점에만 클라이언트에게 알려주는 형태로 만들고 싶었으나, AWS SNS 서비스 이용에 대한 추가 발생 요금을 회사측이 허용해주질 않았기에 아쉽게도 구현해보지는 못했습니다.',
                          children: [
                            Spacer(),
                            CardImgButton(
                              msg: 'C++',
                              icon: Icons.image_outlined,
                              color: Colors.cyan,
                              path: 'assets/images/AWSgameliftFlexmatch.png',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const TextTitle(msg: '모아이게임즈', size: 25, useDivider: true),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        WorkBoxBasic(
                          w: 470,
                          h: 225,
                          backColor: Colors.grey.shade200,
                          headText: 'SubLoader',
                          headSize: 22,
                          bodyText:
                              '처음 플레이어가 서버에 접속 할 때, 플레이어와 관련한 정보를 모두 다 불러와야 하는데, 처음부터 불필요한 정보까지 모두 불러올 필요가 없으므로, 데이터가 필요한 순간에 즉시 최초 한 번만 DB로 부터 정보를 받아오는 시스템을 구현하였었습니다. (우편, 이벤트 정보 등등)',
                          children: const [
                            Spacer(),
                            CardImgButton(
                              msg: 'C++',
                              icon: Icons.image_outlined,
                              color: Colors.cyan,
                              path: 'assets/images/process_subloader.png',
                            ),
                          ],
                        ),
                        WorkBoxBasic(
                          w: 470,
                          h: 225,
                          backColor: Colors.white,
                          headText: '업적',
                          headSize: 22,
                          bodyText:
                              '특정 행동에 대한 업적 진행도를 올려주거나, 달성한 업적에 대해 보상을 지급하는 컨텐츠를 구현하였었습니다. DB부하를 줄이기 위해 LazyStore 라는 기능을 따로 구현하여 1분마다 관련 정보를 저장할 수 있도록 처리하였습니다.',
                          children: [
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                CardImgButton(
                                  msg: 'C++',
                                  icon: Icons.image_outlined,
                                  color: Colors.cyan,
                                  path: 'assets/images/process_achv1.png',
                                ),
                                SizedBox(width: 5),
                                CardImgButton(
                                  msg: 'C++',
                                  icon: Icons.image_outlined,
                                  color: Colors.cyan,
                                  path: 'assets/images/process_achv2.png',
                                ),
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const WorkBoxBasic(
                          w: 225,
                          h: 225,
                          backColor: Colors.white,
                          headText: '기억의 돌',
                          headSize: 22,
                          bodyText:
                              '현재 위치를 기억하고, 기억의 돌을 소모하여 특정 위치로 이동하는 컨텐츠, 좌표를 즉시 DB에 저장하고, 아이템 사용 시 해당 저장 위치로 캐릭터 이동하는 기능.',
                        ),
                        const WorkBoxBasic(
                          w: 225,
                          h: 225,
                          backColor: Colors.white,
                          headText: '칭호',
                          headSize: 22,
                          bodyText:
                              '칭호 지급 및 조건부 칭호 기능 구현, 칭호와 연동된 능력치 지급 기능 구현. 조건부 칭호의 경우, 매 시즌마다 초기화 되며 다음 시즌 시 랭킹 별 보상으로 지급.',
                        ),
                        WorkBoxBasic(
                          w: 225,
                          h: 225,
                          backColor: Colors.grey.shade200,
                          headText: '출석 이벤트',
                          headSize: 22,
                          bodyText:
                              '매일 출석에 따라 스크립트에 입력된 보상 지급기능 구현 및 관련 정보 DB 기록.',
                        ),
                        const WorkBoxBasic(
                          w: 225,
                          h: 225,
                          backColor: Colors.white,
                          headText: '누적 접속 보상',
                          headSize: 22,
                          bodyText:
                              '접속한 시간에 비례하여 스크립트에 입력된 보상 지급 기능 구현 및 관련 정보 DB 기록. 타이머를 통해 보상을 받을 수 있는 접속 시간이 되면 클라에 알림 발송.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        WorkBoxBasic(
                          w: 225,
                          h: 225,
                          backColor: Colors.grey.shade200,
                          headText: '오늘의 활동',
                          headSize: 22,
                          bodyText:
                              '매일 해야 하는 과제를 완수하면 스크립트에 입력된 보상을 지급하는 컨텐츠. ActivityHandler를 상속받아 업적과 비슷한 프로세스로 처리. 진행했던 내용들은 다음날 모두 초기화 처리.',
                        ),
                        const WorkBoxBasic(
                          w: 225,
                          h: 225,
                          backColor: Colors.white,
                          headText: '외형 변경권',
                          headSize: 22,
                          bodyText: '캐릭터의 외모를 변경하는 티켓을 소모하여, 외형을 다시 만드는 기능.',
                        ),
                        const WorkBoxBasic(
                          w: 225,
                          h: 225,
                          backColor: Colors.white,
                          headText: '특수 업적',
                          headSize: 22,
                          bodyText:
                              '특수한 상황에서 조건에 맞는 상황이 되어야, 진행도를 올려주는 컨텐츠. 샌드박스 형 조건 체크 기능 추가 구현 후, 기존 업적 시스템과 결합.',
                        ),
                        const SizedBox(
                          width: 225,
                          height: 225,
                        ),
                      ],
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

class CardUrlButton extends StatelessWidget {
  final String msg, url;
  final IconData icon;
  final Color color;

  const CardUrlButton({
    super.key,
    required this.msg,
    required this.icon,
    required this.color,
    required this.url,
  });

  void _GoUrl(String url) async {
    var uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        _GoUrl(url);
      },
      label: Text(
        msg,
        style: TextStyle(color: color),
      ),
      icon: Icon(
        icon,
        color: color,
      ),
    );
  }
}

class CardImgButton extends StatelessWidget {
  final String msg, path;
  final IconData icon;
  final Color color;

  const CardImgButton({
    super.key,
    required this.msg,
    required this.icon,
    required this.color,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                child: Padding(
                  padding: const EdgeInsets.all(50),
                  child: Image.asset(path),
                ),
              );
            });
      },
      label: Text(
        msg,
        style: TextStyle(color: color),
      ),
      icon: Icon(
        icon,
        color: color,
      ),
    );
  }
}

class WorkBoxBasic extends StatelessWidget {
  final double w, h, headSize;
  final Color backColor;
  final String headText, bodyText;
  final List<Widget> children;

  const WorkBoxBasic(
      {super.key,
      required this.w,
      required this.h,
      required this.backColor,
      required this.headText,
      required this.headSize,
      required this.bodyText,
      this.children = const []});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: backColor,
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        border: Border.all(
          width: 1,
          color: Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            offset: const Offset(2, 2),
            blurRadius: 2.0,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 2.0,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              headText,
              style: TextStyle(
                fontSize: headSize,
                fontFamily: 'YouandiModernTR',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(bodyText),
            for (Widget w in children) w
          ],
        ),
      ),
    );
  }
}
