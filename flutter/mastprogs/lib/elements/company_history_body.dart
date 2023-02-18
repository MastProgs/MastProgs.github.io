import 'package:flutter/material.dart';
import 'package:mastprogs/elements/skill_box_icon.dart';

import 'desc_box.dart';

class CompanyHistoryPart extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String headMsg, headDate, desc;
  final double lineSize;
  final List<String> skillPath, tableDesc;

  const CompanyHistoryPart({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.lineSize,
    required this.headMsg,
    required this.headDate,
    required this.desc,
    this.tableDesc = const ['', '', ''],
    this.skillPath = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 50,
                  height: 57,
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 30,
                  ),
                ),
              ),
              Container(
                height: lineSize,
                width: 2,
                color: Colors.grey,
              )
            ],
          ),
          const SizedBox(width: 15),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            width: 890,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    const SizedBox(width: 10),
                    Text(
                      headMsg,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 15),
                        Text(
                          headDate,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                            fontFamily: 'YouandiModernTR',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (skillPath.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          '프로젝트 정보',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                            // border: Border.all(
                            //   width: 1,
                            //   color: Colors.grey,
                            // ),
                          ),
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('분류')),
                                DataColumn(label: Text('설명')),
                              ],
                              rows: [
                                DataRow(cells: [
                                  const DataCell(Text('프로젝트 장르')),
                                  DataCell(Text(tableDesc[0])),
                                ]),
                                DataRow(cells: [
                                  const DataCell(Text('출시 플랫폼')),
                                  DataCell(Text(tableDesc[1])),
                                ]),
                                DataRow(cells: [
                                  const DataCell(Text('그래픽 뷰')),
                                  DataCell(Text(tableDesc[2])),
                                ]),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          '사용 기술',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            for (String p in skillPath)
                              SkillBox(imgUrl: p, imgSize: 50),
                          ],
                        ),
                      ],
                    ),
                  ),
                DescriptionBox(
                  title: '',
                  titleSize: 1,
                  desc: desc,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
