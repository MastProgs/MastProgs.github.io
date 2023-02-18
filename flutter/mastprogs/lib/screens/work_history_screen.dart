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
                        WorkBoxBasic(
                          w: 225,
                          h: 225,
                          backColor: Colors.grey.shade200,
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
                        Container(
                          width: 225,
                          height: 225,
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                          child: Column(
                            children: const [],
                          ),
                        ),
                        Container(
                          width: 225,
                          height: 225,
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                          child: Column(
                            children: const [],
                          ),
                        ),
                        Container(
                          width: 225,
                          height: 225,
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                          child: Column(
                            children: const [],
                          ),
                        ),
                        Container(
                          width: 225,
                          height: 225,
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                          child: Column(
                            children: const [],
                          ),
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
                child: Image.asset(path),
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
