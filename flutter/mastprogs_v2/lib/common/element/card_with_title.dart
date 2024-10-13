import 'package:flutter/material.dart';
import 'package:mastprogs_v2/common/font_style.dart';

class CardWithTitle extends StatelessWidget {
  final String title;
  final TextStyle? titleStyle;
  final Widget content;

  const CardWithTitle({
    super.key,
    required this.title,
    this.titleStyle,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitleStyle = titleStyle ??
        FontStyleYouandiModernTR.getStyle(
          context: context,
          fontSize: 28,
        );

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              title: Text(
                title,
                style: effectiveTitleStyle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: content,
          ),
        ],
      ),
    );
  }
}
