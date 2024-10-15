import 'package:flutter/material.dart';
import 'package:mastprogs_v2/common/font_style.dart';
import 'package:mastprogs_v2/common/provider.dart';
import 'package:provider/provider.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  final List<Company> companies = [
    Company('회사 A', 'assets/images/linux.png', [
      Job(
        '입사',
        '2021.01.01',
        projectInfo: {
          '프로젝트명': '모바일 앱 개발',
          '기간': '2021.01 - 2021.06',
          '역할': '프론트엔드 개발자',
          '사용 기술': 'Flutter, Dart',
          '주요 성과': '사용자 경험 20% 향상',
        },
        skills: [
          'cpp.png',
          'flutter.png',
          'python.png',
          'cpppp.png',
          'unreal.png',
          'ts.png',
          'linux.png',
          'mssql.png'
        ],
        description: 'Flutter 앱 개발',
      ),
      Job(
        '디자이너',
        '2020.01.01',
        description: 'UI/UX 디자인',
        isFinal: true,
      ),
    ]),
    Company('회사 B', 'assets/images/linux.png', [
      Job(
        '개발자',
        '2021.01.01',
        description: 'Flutter 앱 개발',
      ),
      Job(
        '디자이너',
        '2020.01.01',
        description: 'UI/UX 디자인',
        isFinal: true,
      ),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    //final themeProvider = Provider.of<ThemeProvider>(context);
    return Center(
      child: Padding(
        // Padding 위젯 추가
        padding: const EdgeInsets.only(top: 20.0), // 상단 여유 공간
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView.builder(
            itemCount: companies.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: CompanyCard(company: companies[index]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class Company {
  final String name;
  final String logo;
  final List<Job> jobs;

  Company(this.name, this.logo, this.jobs);
}

class Job {
  final String title;
  final String date;
  final List<String>? skills;
  final String? description;
  final bool isFinal;
  final Map<String, String>? projectInfo; // 프로젝트 정보 추가

  Job(
    this.title,
    this.date, {
    this.skills,
    this.description,
    this.isFinal = false,
    this.projectInfo,
  });

  List<String> get skillsImagePaths {
    return skills?.map((skill) => 'assets/images/$skill').toList() ?? [];
  }
}

class CompanyCard extends StatefulWidget {
  final Company company;

  const CompanyCard({super.key, required this.company});

  @override
  _CompanyCardState createState() => _CompanyCardState();
}

class _CompanyCardState extends State<CompanyCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Card(
      child: Column(
        children: [
          ListTile(
            title: GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(
                  children: [
                    Image.asset(widget.company.logo, width: 50, height: 50),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: themeProvider.themeMode == ThemeMode.light
                              ? Colors.grey.shade300
                              : Colors.grey.shade900,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 5),
                          child: Text(widget.company.name,
                              style: FontStyleYouandiModernTR.getStyle(
                                  context: context, fontSize: 28)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            trailing: AnimatedRotation(
              duration: const Duration(milliseconds: 300),
              turns: _isExpanded ? 0.5 : 0,
              child: IconButton(
                icon: const Icon(Icons.expand_more),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
            ),
          ),
          ClipRect(
            child: AnimatedAlign(
              alignment:
                  _isExpanded ? Alignment.topCenter : Alignment.bottomCenter,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.bounceOut,
              heightFactor: _isExpanded ? 1 : 0,
              child: Column(
                children: widget.company.jobs.map((job) {
                  return ListTile(
                    title: Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Row(
                        children: [
                          const Icon(Icons.assistant,
                              size: 28, color: Colors.blue),
                          const SizedBox(width: 10),
                          Text(job.title,
                              style: FontStyleNotoSans.getStyle(
                                  context: context, fontSize: 18)),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(height: 8),
                              Text(job.date,
                                  style: FontStyleYouandiModernTR.getStyle(
                                      context: context,
                                      fontSize: 14,
                                      lightColor: Colors.grey.shade700,
                                      darkColor: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    subtitle: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        return IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (!job.isFinal)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 23.5),
                                    child: Container(
                                      width: 2.5,
                                      color: Colors.grey,
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 23.5),
                                    child: Container(
                                      width: 2.5,
                                      color: Colors.transparent,
                                    ),
                                  ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (job.projectInfo != null &&
                                            job.projectInfo!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 20),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 10),
                                                  child: Text(
                                                    '프로젝트 정보',
                                                    style: FontStyleNotoSans
                                                        .getStyle(
                                                            context: context,
                                                            fontSize: 14),
                                                  ),
                                                ),
                                                ProjectInfoTable(
                                                    projectInfo:
                                                        job.projectInfo!),
                                              ],
                                            ),
                                          ),
                                        if (job.skillsImagePaths.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('사용 기술',
                                                    style: FontStyleNotoSans
                                                        .getStyle(
                                                            context: context,
                                                            fontSize: 14)),
                                                const SizedBox(height: 10),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: job.skillsImagePaths
                                                      .map((skill) {
                                                    return Tooltip(
                                                      message: skill
                                                          .split('/')
                                                          .last
                                                          .split('.')
                                                          .first,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(6),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: themeProvider
                                                                      .themeMode ==
                                                                  ThemeMode
                                                                      .light
                                                              ? Colors
                                                                  .grey.shade200
                                                              : Colors.grey
                                                                  .shade800,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.1),
                                                              blurRadius: 2,
                                                              offset:
                                                                  const Offset(
                                                                      0, 1),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Image.asset(
                                                          skill,
                                                          width: 60,
                                                          height: 60,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (job.description != null)
                                          Container(
                                            width: double
                                                .infinity, // 가로 길이를 끝까지 채우기
                                            decoration: BoxDecoration(
                                              color: themeProvider.themeMode ==
                                                      ThemeMode.light
                                                  ? Colors.grey.shade200
                                                  : Colors
                                                      .grey.shade800, // 배경색 설정
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      10), // 모서리 둥글게
                                            ),
                                            padding: const EdgeInsets.all(
                                                20.0), // 내부 여백
                                            child: Text(job.description!),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProjectInfoTable extends StatelessWidget {
  final Map<String, String> projectInfo;

  const ProjectInfoTable({super.key, required this.projectInfo});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Card(
      margin: EdgeInsets.zero, // 추가
      shape: RoundedRectangleBorder(
        // 추가
        borderRadius: BorderRadius.circular(8),
      ),
      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0), // 수정
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: projectInfo.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0), // 수정
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      entry.key,
                      style: FontStyleNotoSans.getStyle(
                        context: context,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        lightColor: Colors.black87,
                        darkColor: Colors.white70,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.value,
                      style: FontStyleNotoSans.getStyle(
                        context: context,
                        fontSize: 14,
                        lightColor: Colors.black54,
                        darkColor: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
