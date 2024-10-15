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
        'Flutter 앱 개발',
      ),
      Job(
        '디자이너',
        '2020.01.01',
        'UI/UX 디자인',
        isFinal: true,
      ),
    ]),
    Company('회사 B', 'assets/images/linux.png', [
      Job(
        '개발자',
        '2021.01.01',
        'Flutter 앱 개발',
      ),
      Job(
        '디자이너',
        '2020.01.01',
        'UI/UX 디자인',
        isFinal: true,
      ),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
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
  final String description;
  final bool isFinal;

  Job(this.title, this.date, this.description, {this.isFinal = false});
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
    return Card(
      child: Column(
        children: [
          ListTile(
            title: GestureDetector(
              // GestureDetector를 ListTile의 title로 이동
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
                          color: Provider.of<ThemeProvider>(context)
                                      .themeMode ==
                                  ThemeMode.light
                              ? Colors.grey.shade300
                              : Colors.grey.shade900, // 다크 모드와 라이트 모드에 따라 색상 설정
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10), // 오른쪽 위 둥글게
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
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
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
          ),
          if (_isExpanded)
            Column(
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
                                      Text(job.description),
                                      Text(job.date),
                                      Text(job.description),
                                      Text(job.description),
                                      Text(job.description),
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
        ],
      ),
    );
  }
}
