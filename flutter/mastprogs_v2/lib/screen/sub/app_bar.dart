import 'package:flutter/material.dart';
import 'package:mastprogs_v2/common/color_style.dart';
import 'package:mastprogs_v2/common/font_style.dart';
import 'package:mastprogs_v2/common/provider.dart';
import 'package:provider/provider.dart';

class FrontAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FrontAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    const bool isJobSeeking = true;
    const String lastModified = '25.05.31';

    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.menu, color: ColorStyle.getColor(context)),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
              Icon(
                isJobSeeking ? Icons.hail_outlined : Icons.home_repair_service,
                color: ColorStyle.getColor(context),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isJobSeeking ? '구직중' : '재직중',
                    style: FontStyleNotoSans.getStyle(
                      context: context,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    isJobSeeking ? '연락주세요' : '안녕하세요',
                    style: FontStyleNotoSans.getStyle(
                      context: context,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            children: [
              Text(
                '서버 프로그래머',
                style: FontStyleNotoSans.getStyle(
                  context: context,
                  fontSize: 12,
                ),
              ),
              Text(
                '김형준',
                style: FontStyleYouandiModernTR.getStyle(
                  context: context,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '수정일',
                    style: FontStyleNotoSans.getStyle(
                      context: context,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    lastModified,
                    style: FontStyleNotoSans.getStyle(
                      context: context,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Provider.of<ThemeProvider>(context).themeMode ==
                          ThemeMode.light
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: ColorStyle.getColor(context),
                ),
                onPressed: () {
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
