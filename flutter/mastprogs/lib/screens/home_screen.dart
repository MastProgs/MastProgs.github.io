import 'package:flutter/material.dart';

import 'company_history_screen.dart';
import 'intro_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.person),
                  SizedBox(width: 10),
                  Text('자기 소개')
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.business),
                  SizedBox(width: 10),
                  Text('회사 경력')
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.handyman_rounded),
                  SizedBox(width: 10),
                  Text('작업 내역')
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.polyline_sharp),
                  SizedBox(width: 10),
                  Text('개인 프로젝트')
                ],
              ),
            ),
          ],
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.red,
          indicatorWeight: 5,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.hail_outlined),
                const SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '재직중 - 위메이드',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                    Text(
                      '이직 관심 있음',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                  ],
                )
              ],
            ),
            const Text(
              '서버 프로그래머 - 김형준',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
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
                    fontFamily: 'YouandiModernTR',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: TabBarView(children: [
        IntroScreen(),
        const CompanyHistoryScreen(),
        const Text('data'),
        const Text('data'),
      ]),
    );
  }
}
