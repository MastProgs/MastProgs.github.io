import 'package:flutter/material.dart';

import '../elements/row_skill_list.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Icon(Icons.person),
            Text('서버 프로그래머 - 김형준'),
            Text(
              '2023.02.16',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w100,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            RowSkillCard(
              title: 'Language',
              titleSize: 45,
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
            ),
            RowSkillCard(
              title: 'Database',
              titleSize: 45,
              elemList: [
                'assets/images/mssql.webp',
                'assets/images/mysql.png',
                'assets/images/mongo.png',
                'assets/images/redis.jpg',
              ],
            ),
            RowSkillCard(
              title: 'Environment',
              titleSize: 45,
              elemList: [
                'assets/images/vs.png',
                'assets/images/vsc.png',
                'assets/images/windows.png',
                'assets/images/linux.png',
                'assets/images/azure.jpg',
                'assets/images/aws.png',
              ],
            ),
          ],
        ),
      ),
    );
  }
}
