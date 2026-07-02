import 'dart:typed_data';

import 'package:mastprogs_v2/data/resume_document_data.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ResumePdfService {
  const ResumePdfService();

  Future<void> exportResumePdf({
    ResumeDocumentData? data,
  }) async {
    // AI-NOTE: PDF는 화면 캡처가 아니라 이력 데이터 모델을 문서 레이아웃으로 다시 조립한다.
    final bytes = await buildResumePdf(data: data);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '김형준_이력서.pdf',
    );
  }

  Future<Uint8List> buildResumePdf({
    ResumeDocumentData? data,
  }) async {
    final documentData = data ?? resumeDocumentData;
    final font = await fontFromAssetBundle(
      'assets/fonts/YouandiModernTR.ttf',
    );
    final theme = pw.ThemeData.withFont(base: font, bold: font);
    final pdf = pw.Document(theme: theme);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 34, 36, 40),
        header: (context) => _buildHeader(documentData.profile),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildProfile(documentData.profile),
          _buildSectionTitle('이력서'),
          ...documentData.resumeSections.map(_buildDocumentSection),
          _buildSectionTitle('기술소개서'),
          ...documentData.skillSections.map(_buildSkillSection),
          ...documentData.technicalSections.map(_buildTechnicalSection),
          _buildSectionTitle('이력 정보'),
          ...documentData.experiences.map(_buildExperience),
          _buildSectionTitle('개인 프로젝트'),
          ...documentData.projects.map(_buildProject),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(ResumeProfile profile) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                profile.name,
                style: pw.TextStyle(
                  fontSize: 21,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                profile.title,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Text(
            '${profile.phone} | ${profile.email}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        '${context.pageNumber} / ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
      ),
    );
  }

  pw.Widget _buildProfile(ResumeProfile profile) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 16),
        pw.Text(
          '자기소개 및 기본 정보',
          style: pw.TextStyle(
            fontSize: 15,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey800,
          ),
        ),
        pw.SizedBox(height: 8),
        ...profile.summary.map(_buildBullet),
        pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 10,
          runSpacing: 4,
          children: profile.links
              .map((link) => pw.Text(
                    '${link.label}: ${link.url}',
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      color: PdfColors.blueGrey700,
                    ),
                  ))
              .toList(),
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12, bottom: 8),
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey900,
        ),
      ),
    );
  }

  pw.Widget _buildDocumentSection(DocumentSection section) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSubTitle(section.title),
          ...section.items.map(_buildBullet),
        ],
      ),
    );
  }

  pw.Widget _buildSkillSection(SkillSectionData section) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSubTitle(section.title),
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: section.skills.map(_buildSkillChip).toList(),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSkillChip(SkillData skill) {
    return pw.Container(
      width: 166,
      padding: const pw.EdgeInsets.all(7),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  skill.name,
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                'Lv.${skill.proficiency}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.blueGrey700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            skill.description,
            style: const pw.TextStyle(
              fontSize: 7.5,
              color: PdfColors.grey800,
              lineSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTechnicalSection(TechnicalSectionData section) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSubTitle(section.title),
          ...section.items.map(_buildBullet),
        ],
      ),
    );
  }

  pw.Widget _buildExperience(ExperienceData experience) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(left: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: PdfColors.blueGrey200, width: 2),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  '${experience.company} - ${experience.role}',
                  style: pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                experience.period,
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 3),
          ...experience.highlights.map(_buildBullet),
        ],
      ),
    );
  }

  pw.Widget _buildProject(ProjectData project) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSubTitle(project.title),
          _buildBullet(project.description),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 10, top: 2),
            child: pw.Text(
              project.url,
              style: const pw.TextStyle(
                fontSize: 7.5,
                color: PdfColors.blueGrey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSubTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey900,
        ),
      ),
    );
  }

  pw.Widget _buildBullet(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 4, bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '- ',
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: const pw.TextStyle(
                fontSize: 8.5,
                color: PdfColors.grey800,
                lineSpacing: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
