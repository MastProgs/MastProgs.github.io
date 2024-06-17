import 'package:flutter/material.dart';
import 'package:mastprogs/screens/private_projects.dart';
import 'package:mastprogs/screens/work_history_screen.dart';

import 'company_history_screen.dart';
import 'intro_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 10),
                  Text('자기 소개')
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business),
                  SizedBox(width: 10),
                  Text('회사 경력')
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.handyman_rounded),
                  SizedBox(width: 10),
                  Text('작업 내역')
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                //Icon(Icons.hail_outlined),
                Icon(Icons.home_repair_service_rounded),
                SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '근무중',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                    Text(
                      '이직 관심 없음',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                  ],
                )
              ],
            ),
            Text(
              '서버 프로그래머 - 김형준',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '최종 수정 날짜',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w100,
                  ),
                ),
                Text(
                  '2024.06.17',
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
        const WorkHistory(),
        const PrivateProject(),
      ]),
    );
  }
}
