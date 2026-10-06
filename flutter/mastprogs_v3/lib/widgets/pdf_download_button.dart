// 네 경로에 공통으로 보이는 이력서 PDF 다운로드 조작.
// AI-NOTE: PDF는 빌드에 포함된 단일 정적 파일이고, 이 버튼은 외부 URL 링크를 추가하지 않는다.
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../app/app_scope.dart';
import '../app/theme/palette.dart';
import '../core/constants.dart';
import 'pressable.dart';

class PdfDownloadButton extends StatelessWidget {
  const PdfDownloadButton({super.key});

  @override
  Widget build(BuildContext context) {
    void download() => AppServices.of(context).platform.downloadFile(portfolioPdfPath, portfolioPdfFilename);
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Pressable(
      radius: BorderRadius.circular(28),
      focusColor: context.palette.ink,
      semanticLabel: '이력서와 상세 3개 PDF 다운로드',
      excludeChildSemantics: true,
      onPressed: download,
      builder: (context, state) => Container(
        height: 56,
        width: compact ? 56 : null,
        padding: compact ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: context.palette.orange,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(PhosphorIconsRegular.filePdf, color: Colors.white, size: 22),
            if (!compact) ...[
              const SizedBox(width: 8),
              const Text(
                'PDF 다운로드',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
