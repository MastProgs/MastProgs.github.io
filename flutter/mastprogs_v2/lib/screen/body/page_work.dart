import 'package:flutter/material.dart';
import 'package:mastprogs_v2/common/font_style.dart';

class ExpandableImageCard extends StatefulWidget {
  final String title;
  final String imagePath;

  const ExpandableImageCard({
    super.key,
    required this.title,
    required this.imagePath,
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
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                width: double.infinity,
                child: Image.asset(
                  widget.imagePath,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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
                const ExpandableImageCard(
                  title: '스톡마스터 플로우차트',
                  imagePath: 'assets/images/stockmaster-flowchart.png',
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
