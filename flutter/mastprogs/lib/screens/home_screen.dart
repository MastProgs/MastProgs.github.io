import 'package:flutter/material.dart';
import 'package:mastprogs/screens/private_projects.dart';
import 'package:mastprogs/screens/work_history_screen.dart';

import 'company_history_screen.dart';
import 'intro_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
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
          title: const Text('서버 프로그래머 - 김형준'),
        ),
        body: TabBarView(children: [
          KeepAliveWidget(child: IntroScreen()),
          const KeepAliveWidget(child: CompanyHistoryScreen()),
          const KeepAliveWidget(child: WorkHistory()),
          const KeepAliveWidget(child: PrivateProject()),
        ]),
      ),
    );
  }
}

class KeepAliveWidget extends StatefulWidget {
  final Widget child;

  const KeepAliveWidget({required this.child});

  @override
  _KeepAliveWidgetState createState() => _KeepAliveWidgetState();
}

class _KeepAliveWidgetState extends State<KeepAliveWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
