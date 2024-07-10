import 'package:flutter/material.dart';

import '../elements/company_history_body.dart';
import '../elements/company_history_header.dart';
import '../elements/company_history_main.dart';

class CompanyHistoryScreen extends StatelessWidget {
  const CompanyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: 1000,
          child: Column(
            children: [
              const SizedBox(height: 50),
              // CompanyBigCard(
              //   children: [
              //     HistoryHeader(
              //       imgPath: 'assets/images/aleph.jpg',
              //       backColor: Colors.black87.withOpacity(0.85),
              //       msg: 'Aleph Research',
              //       msgColor: Colors.white,
              //     ),
              //     const SizedBox(height: 10),
              //     const CompanyHistoryPart(
              //       icon: Icons.assistant_rounded,
              //       iconColor: Colors.lightBlue,
              //       lineSize: 90,
              //       headMsg: '입사',
              //       headDate: '2024.04.15',
              //       desc:
              //           '블록체인 코어 시니어 개발자로 입사하였습니다. 스타트업 초창기 멤버로 합류하였으며, 자율적인 근무 분위기와 좋은 조건 제안으로, 개인 사업과 병행이 가능하다고 판단하여 같이 진행하게 되었습니다.',
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 50),
              CompanyBigCard(
                children: [
                  HistoryHeader(
                    imgPath: 'assets/images/people.png',
                    backColor: Colors.black87.withOpacity(0.85),
                    msg: '리치포켓',
                    msgColor: Colors.white,
                  ),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(width: 20),
                      Icon(
                        Icons.badge_rounded,
                        size: 50,
                        color: Colors.red,
                      ),
                      SizedBox(width: 24),
                      Text(
                        '현재',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const CompanyHistoryPart(
                    icon: Icons.assistant_rounded,
                    iconColor: Colors.lightBlue,
                    lineSize: 90,
                    headMsg: '창업',
                    headDate: '2023.07.01 (사업자 2024.04.01)',
                    desc:
                        '만들고 싶은 SaaS 서비스가 생겨 도전해보고자 1인 창업으로 시작하였습니다. 부업 정도로 운영하고 있기 때문에, 본업에는 지장이 없을 예정입니다.',
                  ),
                ],
              ),
              const SizedBox(height: 50),
              CompanyBigCard(children: [
                HistoryHeader(
                  imgPath: 'assets/images/wemade.png',
                  backColor: Colors.black87.withOpacity(0.85),
                  msg: '위메이드 플러스 [폐업]',
                  msgColor: Colors.white,
                ),
                const SizedBox(height: 10),
                const CompanyHistoryPart(
                  icon: Icons.assistant_rounded,
                  iconColor: Colors.lightBlue,
                  lineSize: 90,
                  headMsg: '입사',
                  headDate: '2021.09.06',
                  desc:
                      '대학원을 재학중인 상황에서, 대학원과 병행하며 근무를 할 수 있으니 일손이 필요하다는 부탁을 받고 입사하였습니다.',
                ),
                const CompanyHistoryPart(
                  icon: Icons.assistant_rounded,
                  iconColor: Colors.lightBlue,
                  lineSize: 570,
                  headMsg: 'Nallary',
                  headDate: '2022.03.31 Drop',
                  tableDesc: [
                    'Community SNS App, NFT Trading Platform',
                    'Mobile',
                    'Web Gallary, Ingame: 3D Full View',
                  ],
                  skillPath: [
                    'assets/images/typescript.png',
                    'assets/images/mysql.png',
                    'assets/images/redis.jpg',
                    'assets/images/linux.png',
                    'assets/images/aws.png',
                    'assets/images/github.png',
                  ],
                  desc:
                      'NFT 컨텐츠와 Gallary 의 합성 소셜 플랫폼 프로젝트로 모바일을 기반으로 개발되던 프로젝트였습니다. 이더리움 ERC-721 프로토콜을 기준으로 NFT 거래 소유 발행 등을 지원하는 프로젝트였으며, 플랫폼 내에서는 유저들이 아바타로 돌아다니며 다양한 작품들을 플랫폼 내에서 확인하고 다양한 컨텐츠를 즐기는, 일종의 NFT 거래와 컨텐츠를 활용할 수 있는 타사의 제페토 앱과 같다고 볼 수 있습니다. 하지만 모바일 IOS 측의 정책적인 이슈로 출시 직전 문제가 해결되지 못하여 무기한 연기되었습니다. 저는 이 프로젝트에서 기본적인 프레임워크 부터 팔로잉/팔로우/좋아요 같은 소셜 컨텐츠 및 실시간 랭킹 시스템 등을 담당하여 구현하였습니다. 서비스를 하기 위한 AWS 클라우드 서버 환경을 설정하고 환경설정을 다루는 작업들을 담당하였습니다.',
                ),
                const CompanyHistoryPart(
                  icon: Icons.assistant_rounded,
                  iconColor: Colors.lightBlue,
                  lineSize: 550,
                  headMsg: 'Fishing Tornado Championship',
                  headDate: '2022.03.31 (Release 2023.05.25)',
                  tableDesc: [
                    'Fishing Game',
                    'Mobile',
                    '2D View',
                  ],
                  skillPath: [
                    'assets/images/cpp.png',
                    'assets/images/golang.jpg',
                    'assets/images/mysql.png',
                    'assets/images/redis.jpg',
                    'assets/images/windows.png',
                    'assets/images/azure.jpg',
                    'assets/images/github.png',
                  ],
                  desc:
                      '과거 서비스 종료된 게임에 token 을 붙여, 재출시 준비 작업을 진행 중에 있습니다. 과거 소스코드를 C++20 버전으로 포팅하고, 넷마블 퍼블리셔와 관련되어있던 코드를 제거하는 작업을 진행했었습니다. token 연동을 하기 위한 Golang 웹 서버를 통해 기타 token 관련한 컨텐츠들을 처리하는 담당했습니다. 로그를 파일로만 남기던 구조를 변경하여 Golang 서버를 통해 로그를 DB 로 적재하는 작업을 진행하고, 크래시가 날 경우 dump 파일을 남길 수 있는 시스템과 인코딩 문제로 문자열처리, Redis 연결 오류 같은 굵직한 이슈 등을 해결하였습니다. 서비스를 하기 위한 Azure 클라우드 서버 환경을 설정하고 환경설정을 다루는 작업들을 담당하였습니다.',
                ),
                const CompanyHistoryPart(
                  icon: Icons.assistant_rounded,
                  iconColor: Colors.lightBlue,
                  lineSize: 500,
                  headMsg: '미공개 프로젝트',
                  headDate: '2023.01.16',
                  tableDesc: [
                    'Undefined',
                    'PC',
                    '2D View',
                  ],
                  skillPath: [
                    'assets/images/python.png',
                    'assets/images/mysql.png',
                    'assets/images/mongo.png',
                    'assets/images/redis.jpg',
                    'assets/images/windows.png',
                    'assets/images/linux.png',
                    'assets/images/azure.jpg',
                    'assets/images/github.png',
                  ],
                  desc:
                      '블록체인 재화를 연동한 게임을 개발하였습니다. Python 의 Fast API 를 활용하여 서버 프레임워크를 짜고, 그 위에 다양한 컨텐츠 작업과 코어 시스템들을 개발하였습니다. 서버 아키텍쳐 설계, 메인 웹 서버, 채팅 소켓 서버, 스케쥴러 서버, 스크립트 파일 검사, xslx -> code, code -> xslx, JWT 토큰 시스템, TypeORM 설계, 비동기 통신 등등, 모든 설계에 대한 A to Z 작업을 진행했습니다.',
                ),
                const CompanyHistoryPart(
                  icon: Icons.assistant_rounded,
                  iconColor: Colors.lightBlue,
                  lineSize: 0,
                  headMsg: '퇴사',
                  headDate: '2023.06.30',
                  desc:
                      '회사의 프로젝트를 여러개 진행하였지만, 현실적으로 프로젝트들의 성과가 저조했었고, 이러한 상황속에 작은 규모의 회사에서 지속적으로 투자를 받기에는 어려운 상황이었습니다. 그래서 회사의 경영진과 상의하여 퇴사를 진행하게 되었습니다.',
                ),
              ]),
              const SizedBox(height: 50),
              CompanyBigCard(
                children: [
                  HistoryHeader(
                    imgPath: 'assets/images/jy.jpg',
                    backColor: Colors.black87.withOpacity(0.85),
                    msg: '조이시티',
                    msgColor: Colors.white,
                  ),
                  const CompanyHistoryPart(
                    icon: Icons.assistant_rounded,
                    iconColor: Colors.lightBlue,
                    lineSize: 90,
                    headMsg: '입사',
                    headDate: '2020.09.07',
                    desc:
                        '게임 전체적으로 급하게 리뉴얼 작업을 해야하다보니 일손이 필요하다고 하여, 제의를 받아 입사를 진행했던 회사입니다. 입사하자마자 업무량이 몰려있는 리뉴얼 작업을 담당했었고, 그와 함께 필요한 각종 이벤트 및 컨텐츠 작업들도 같이 작업하며 리뉴얼 업무를 했던 회사입니다.',
                  ),
                  const CompanyHistoryPart(
                    icon: Icons.assistant_rounded,
                    iconColor: Colors.lightBlue,
                    lineSize: 500,
                    headMsg: 'Free Style',
                    headDate: ' ',
                    tableDesc: [
                      'Arcade',
                      'Desktop PC',
                      '3D Top View',
                    ],
                    skillPath: [
                      'assets/images/cpp.png',
                      'assets/images/mssql.png',
                      'assets/images/windows.png',
                      'assets/images/svn.png',
                    ],
                    desc:
                        '오랫동안 라이브 서비스 하던 게임에 다양한 컨텐츠 작업들을 진행했습니다. 프로젝트 특성상 너무 낡고 오래되어 다양한 개선 작업 툴을 만들고, 효율적으로 일을 하기 위한 고민을 많이 하였습니다. 그 외에는 기본적인 컨텐츠 작업들을 진행하였습니다.',
                  ),
                  const CompanyHistoryPart(
                    icon: Icons.assistant_rounded,
                    iconColor: Colors.lightBlue,
                    lineSize: 0,
                    headMsg: '퇴사',
                    headDate: '2021.04.13',
                    desc:
                        '특별히 불화가 있거나 문제가 있었던 부분이 있었던 것은 아니었으나, 준비하고 있었던 대학원과 병행하기에는 야근이 너무 많았었고, 어느정도 큰 업무 처리들은 잘 마무리 되었다고 판단하여 퇴사를 진행하게 되었습니다.',
                  ),
                ],
              ),
              const SizedBox(height: 50),
              CompanyBigCard(
                children: [
                  HistoryHeader(
                    imgPath: 'assets/images/hb.png',
                    backColor: Colors.black87.withOpacity(0.85),
                    msg: '한빛소프트',
                    msgColor: Colors.white,
                  ),
                  const CompanyHistoryPart(
                    icon: Icons.assistant_rounded,
                    iconColor: Colors.lightBlue,
                    lineSize: 90,
                    headMsg: '입사',
                    headDate: '2020.02.03',
                    desc:
                        '일손이 필요하다고 요청받아 지인을 통해 입사하게 되었습니다. 프로젝트 개발 초기에 합류하게 되었습니다.',
                  ),
                  const CompanyHistoryPart(
                    icon: Icons.assistant_rounded,
                    iconColor: Colors.lightBlue,
                    lineSize: 530,
                    headMsg: 'Gunslinger Stratos',
                    headDate: ' ',
                    tableDesc: [
                      'TPS',
                      'Desktop PC',
                      '3D Full View',
                    ],
                    skillPath: [
                      'assets/images/cpp.png',
                      'assets/images/js.png',
                      'assets/images/ueicon.png',
                      'assets/images/mysql.png',
                      'assets/images/centos.jpg',
                      'assets/images/aws.png',
                      'assets/images/svn.png',
                    ],
                    desc:
                        '해당 프로젝트는 일본의 글로벌 기업인 Square Enix 와 함께 협업으로 진행되는 대형 프로젝트였습니다. 프로젝트가 약 1년정도 진행이 되고 있던 상황에 합류하였으며, TPS 게임 장르의 게임이었습니다. 언리얼의 데디케이티드 서버 + 웹 서버를 활용하여 게임이 제작되었으며, 제가 주로 담당했던 업무는 AWS의 GameLift 기능 중 Flexmatch 라는 매치메이킹 관련 기능을 웹 서버와 데디케이티드 서버에 각각 구현하는 역할이 주 업무였습니다. 기타 업무는 라이브 서비스를 위한 운영툴에서 정보 조회 기능을 구현하는 역할도 담당하였습니다.',
                  ),
                  const CompanyHistoryPart(
                    icon: Icons.assistant_rounded,
                    iconColor: Colors.lightBlue,
                    lineSize: 0,
                    headMsg: '퇴사',
                    headDate: '2020.05.01',
                    desc:
                        '입사하고 나서 얼마 있지 않아 몸이 금방 아프게되어 아쉽게 퇴사하게 된 회사입니다. 몸이 아파서 퇴사를 고민하던 시점에 함께 계속 일을 했으면 좋겠다는 요청을 주시며 아쉬움을 표하셨지만, 저 스스로도 일단 몸의 휴식이 최우선이라고 생각하여 원래 계획대로 나오게 되었습니다.',
                  ),
                ],
              ),
              const SizedBox(height: 50),
              CompanyBigCard(
                children: [
                  HistoryHeader(
                    imgPath: 'assets/images/moai.jpg',
                    backColor: Colors.black87.withOpacity(0.85),
                    msg: '모아이 게임즈',
                    msgColor: Colors.white,
                  ),
                  const CompanyHistoryPart(
                    icon: Icons.assistant_rounded,
                    iconColor: Colors.lightBlue,
                    lineSize: 90,
                    headMsg: '입사',
                    headDate: '2017.08.07',
                    desc: '개발 초기 시점에 MMORPG 개발을 경험해보고 싶어서, 직접 지원하여 합류하게 되었습니다.',
                  ),
                  const CompanyHistoryPart(
                    icon: Icons.assistant_rounded,
                    iconColor: Colors.lightBlue,
                    lineSize: 550,
                    headMsg: 'TRAHA',
                    headDate: '2018.04.18',
                    tableDesc: [
                      'MMORPG',
                      'Mobile',
                      '3D Full View',
                    ],
                    skillPath: [
                      'assets/images/cpp.png',
                      'assets/images/cpppp.png',
                      'assets/images/ueicon.png',
                      'assets/images/mssql.png',
                      'assets/images/windows.png',
                      'assets/images/azure.jpg',
                      'assets/images/svn.png',
                    ],
                    desc:
                        '트라하 개발 초창기에 입사하여 서버의 시스템 설계 및 컨텐츠 관련 작업을 주로 진행하였습니다. 거의 대부분 C++로 작업을 진행하였고, 구현했던 컨텐츠를 기반으로, 넥슨 사에서 제공되는 운영툴 양식에 맞게 C#으로 컨텐츠 내용을 연동하여 라이브 서비스에서 활용할 수 있도록 하는 작업을 담당하였습니다. 핵심 코어 코드들은 입사하기 전에 구현이 되어 있었고, 기존에 존재하는 코어 시스템 위에 이를 활용한 새 컨텐츠를 올리는 형태의 작업이 많았습니다. DB의 경우 MSSQL을 활용했었고, 프로시저를 미리 구현하여 필요한 때에 프로시저를 활용하는 형태로 사용하였습니다. 게임 출시는 4월 18일에 출시하여 퇴사를 할 때까지 라이브 서비스 또한 진행하였습니다.',
                  ),
                  const CompanyHistoryPart(
                    icon: Icons.assistant_rounded,
                    iconColor: Colors.lightBlue,
                    lineSize: 0,
                    headMsg: '퇴사',
                    headDate: '2019.12.13',
                    desc:
                        '회사의 경영난과 함께 대규모 구조조정이 진행되었습니다. 제가 대상자는 아니었지만 많은 분들께서 회사를 떠나게 되다보니 분위기도 많이 바뀌게 되고, 그에 따라 계속 회사 내에 있기 보다는 새로운 회사를 통해 더 많은 경험을 하는게 좋다고 생각되어 퇴사하게 되었습니다.',
                  ),
                ],
              ),
              const SizedBox(height: 500),
            ],
          ),
        ),
      ),
    );
  }
}
