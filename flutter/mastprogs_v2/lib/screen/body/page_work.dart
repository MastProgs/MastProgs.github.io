import 'package:flutter/material.dart';
import 'package:mastprogs_v2/common/font_style.dart';

class ContentItem {
  final String? description;
  final String? imagePath;

  ContentItem({this.description, this.imagePath});
}

class ExpandableImageCard extends StatefulWidget {
  final String title;
  final List<ContentItem> contentItems;

  const ExpandableImageCard({
    super.key,
    required this.title,
    required this.contentItems,
  });

  @override
  _ExpandableImageCardState createState() => _ExpandableImageCardState();
}

class _ExpandableImageCardState extends State<ExpandableImageCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(15),
                  topRight: const Radius.circular(15),
                  bottomLeft:
                      _isExpanded ? Radius.zero : const Radius.circular(15),
                  bottomRight:
                      _isExpanded ? Radius.zero : const Radius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: FontStyleYouandiModernTR.getStyle(
                      context: context,
                      fontSize: 18,
                      lightColor: Colors.grey.shade700,
                      darkColor: Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.expand_more),
                  ),
                ],
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
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.contentItems.map((item) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.imagePath != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 10.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: Image.asset(
                                item.imagePath!,
                                fit: BoxFit.fitWidth,
                              ),
                            ),
                          ),
                        if (item.description != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 10.0),
                            child: Text(
                              item.description!,
                              style: FontStyleNotoSans.getStyle(
                                context: context,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 사용 예시
class WorkScreen extends StatelessWidget {
  const WorkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '리치포켓',
                  style: FontStyleYouandiModernTR.getStyle(
                    context: context,
                    fontSize: 24,
                  ),
                ),
                const Divider(),
                ExpandableImageCard(
                  title: '스톡마스터 플로우차트',
                  contentItems: [
                    ContentItem(
                      description: '이것은 스톡마스터의 플로우차트입니다.',
                      imagePath: 'assets/images/stockmaster-flowchart.png',
                    ),
                    ContentItem(description: '이 플로우차트는 주식 거래 프로세스를 보여줍니다.'),
                  ],
                ),
                // 여기에 더 많은 ExpandableImageCard를 추가할 수 있습니다.
              ],
            ),
          ),
        ),
      ),
    );
  }
}
