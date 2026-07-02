import 'package:flutter_test/flutter_test.dart';
import 'package:mastprogs_v2/service/resume_pdf_service.dart';

void main() {
  testWidgets('Resume PDF service creates a valid PDF',
      (WidgetTester tester) async {
    final bytes = await const ResumePdfService().buildResumePdf();

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
