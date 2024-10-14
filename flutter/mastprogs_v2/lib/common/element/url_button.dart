import 'package:flutter/material.dart';
import 'package:mastprogs_v2/common/font_style.dart';
import 'package:mastprogs_v2/common/provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class UrlButton extends StatefulWidget {
  final String imageAsset;
  final double imageSize;
  final String title;
  final String description;
  final String url;
  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;
  final bool isWide;
  const UrlButton({
    super.key,
    required this.imageAsset,
    this.imageSize = 50,
    required this.title,
    required this.description,
    required this.url,
    this.titleStyle,
    this.descriptionStyle,
    this.isWide = true,
  });

  @override
  _UrlButtonState createState() => _UrlButtonState();
}

class _UrlButtonState extends State<UrlButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final theme = Theme.of(context);

    // 기본 색상과 호버 색상 정의
    //final baseColor = theme.cardColor;
    final hoverColor = isDarkMode
        ? LinearGradient(
            colors: [
              Colors.purple.shade900,
              Colors.blue.shade900,
              Colors.red.shade900,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              Colors.lightBlue.shade100,
              Colors.lightGreen.shade100,
              Colors.pink.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    // 화면 너비 가져오기
    final screenWidth = MediaQuery.of(context).size.width;
    // 버튼 너비 계산 (예: 화면 너비에서 32px 뺀 값)
    final buttonWidth = screenWidth > 900 ? 710.0 : screenWidth - 185;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () => _launchURL(widget.url),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                gradient: _isHovering ? hoverColor : null, // 그라데이션 적용
                //color: !_isHovering ? baseColor : null, // 기본 색상 적용
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      widget.imageAsset,
                      fit: BoxFit.contain,
                      width: widget.imageSize,
                      height: widget.imageSize,
                    ),
                    const SizedBox(width: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: widget.isWide ? buttonWidth : 200,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: widget.titleStyle ??
                                    FontStyleNotoSans.getStyle(
                                        context: context, fontSize: 24),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                widget.description,
                                style: widget.descriptionStyle ??
                                    FontStyleNotoSans.getStyle(
                                      context: context,
                                      fontSize: 12,
                                      lightColor: Colors.grey.shade700,
                                      darkColor: Colors.grey,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        //if (widget.isWide) SizedBox(width: buttonWidth),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: _isHovering
                              ? theme.colorScheme.primary
                              : theme.iconTheme.color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } else {
      throw '해당 URL을 열 수 없습니다: $url';
    }
  }
}
