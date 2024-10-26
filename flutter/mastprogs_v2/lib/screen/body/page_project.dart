import 'package:flutter/material.dart';
import 'package:mastprogs_v2/common/provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class Project {
  final String title;
  final String description;
  final String url;

  Project({required this.title, required this.description, required this.url});
}

class ProjectScreen extends StatelessWidget {
  ProjectScreen({super.key});

  final ScrollController _scrollController = ScrollController();

  final List<Project> projects = [
    Project(
      title: "SNS 자동 글 쓰기",
      description: "실시간 트렌드를 기반으로 내용을 요약하여 자동으로 SNS에 글을 쓰는 프로세스를 구축하였습니다.",
      url: "https://naver.me/5bV09fiw",
    ),
    Project(
      title: "분류 모델 AI 차트 분석",
      description:
          "대학원에서 졸업 논문 연구 주제로 진행한 프로젝트입니다. 코인 차트를 분류 모델을 통해 구분하고, 이에 대한 예측을 하는 연구 자료 입니다.",
      url:
          "http://ggram.ipdisk.co.kr/dl/a2674a4d052c7cb0227ce38cbecf3654/66704ad4/657465726e616c3b706c61796578706f32/2O7x4Mi787y9M3EHZ18sLn1s0B1pT04/%EC%A1%B8%EC%97%85_%EB%B0%9C%ED%91%9C%EC%9E%90%EB%A3%8C.pdf",
    ),
    Project(
      title: "애니메이션 추천 시스템",
      description:
          "대학원에서 과제로 작업한 애니메이션 추천 시스템 기능을 간략하게 구현하였습니다. 데이터를 분석하고 평가 관계도를 활용하여 특정 애니메이션을 선택하면, 그에 알맞는 애니메이션을 추천해주는 시스템을 구현하였습니다.",
      url: "https://naver.me/51YeJXCy",
    ),
    Project(
      title: "자동 트레이딩 봇 및 데이터 분석",
      description: "비트코인 차트 분석을 통한 매매 지표 정보를 분석하고, 그에 대응되는 트레이딩 봇도 만들어 보았습니다.",
      url: "https://naver.me/GKoLX1eX",
    ),
    Project(
      title: "쿠팡 파트너스 글쓰기 자동화",
      description: "쿠팡 파트너스 상품 홍보를 자동으로 작성하는 프로그램을 구현하였습니다.",
      url: "https://naver.me/Fx40a9ii",
    ),
  ];

  Widget _buildBottomButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 맨 위로 가는 버튼 추가
        ElevatedButton(
          onPressed: () {
            // 페이지의 맨 위로 스크롤
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          },
          child: const Text('맨 위로'),
        ),
        // 다음 화면 보기 버튼 추가
        ElevatedButton(
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          child: const Text('다른 페이지'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return SingleChildScrollView(
      controller: _scrollController,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '개인 프로젝트',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Divider(),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    return ProjectCard(
                      project: projects[index],
                      isDarkMode: isDarkMode,
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildBottomButton(context),
                const SizedBox(height: 250),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  final Project project;
  final bool isDarkMode;

  const ProjectCard({
    super.key,
    required this.project,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _launchURL(project.url),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                project.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }
}
