"""Generate the four-section, print-oriented portfolio PDF from bundled data.

Requires reportlab 4.4.9, fonttools 4.60.1, and pypdf 6.10.0.
Run from the Flutter project root: python tools/generate_portfolio_pdf.py
"""

from __future__ import annotations

import hashlib
import io
import json
from pathlib import Path
import re
import tempfile
from xml.sax.saxutils import escape

from fontTools.ttLib import TTFont as FontToolsFont
from fontTools.varLib import instancer
from pypdf import PdfReader, PdfWriter
from pypdf.generic import BooleanObject, NameObject, TextStringObject
from reportlab import rl_config
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
from reportlab.platypus import Flowable, HRFlowable, Image, PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "assets" / "data"
OUTPUT = ROOT / "web" / "portfolio.pdf"
FONT_SOURCE = ROOT / "assets" / "fonts" / "PretendardVariable.ttf"
SOURCES = ("resume.json", "site.json", "workflowDetail.json", "pixelStudio.json", "subtitles.json", "pixel-palette-sets.json")
TITLE = "김형준 · 이력서"
INK = colors.HexColor("#111111")
MUTED = colors.HexColor("#555555")
RULE = colors.HexColor("#D9430C")
PAGE_WIDTH, PAGE_HEIGHT = A4
MARGIN = 19 * 72 / 25.4
MM = 72 / 25.4
CONTENT_WIDTH = PAGE_WIDTH - 2 * MARGIN - 12
PORTFOLIO_URL = "https://github.com/MastProgs"
# AI-NOTE: 긴 자막 처리 문구를 문서용 한 문장으로 줄였다. 각 문장은 같은 순서의
# subtitles.json SUBTITLE_PIPELINE 항목에 근거하며, 원본 데이터가 바뀌면 함께 검토한다.
SRT_ACTIONS = (
    "FFmpeg로 음성을 추출하고 파형과 VAD를 만듭니다.",
    "로컬 모델로 한국어 음성을 인식하고 후보를 비교합니다.",
    "단어의 시작과 끝을 절대 밀리초로 저장합니다.",
    "표시 시간만 최대 0.3초 넓히고 단어 시각은 유지합니다.",
    "AI는 끊을 위치를 정하고 시간은 단어 시각에서 가져옵니다.",
    "Codex와 Claude가 독립 제안 후 최대 두 번 다시 판단합니다.",
    "사람이 교정 제안을 수락하거나 보류합니다.",
    "시간순 번호를 붙여 SRT로 내보냅니다.",
)
SRT_LEAD = "단어 정렬·AI 제안·사람 승인으로 완성하는 한국어 자막"
WORKFLOW_LEAD = "Master AI가 경로를 정하고 역할별 AI가 기획·검수·개발·QA·통합 검증·Wiki를 거치는 구조"
SRT_PROBLEM = "한국어 대사를 자막으로 만들 때 문구와 시간을 반복해서 손으로 맞춰야 했습니다."
SRT_BOUNDARIES = (
    "자막 시간은 강제 정렬된 단어 시각에서 가져옵니다.",
    "끊을 위치와 이유가 붙은 교정 제안만 돌려줍니다.",
    "교정 제안을 수락·보류하고 되돌릴 수 있습니다.",
)


def source_digest() -> str:
    digest = hashlib.sha256()
    for name in SOURCES:
        digest.update(name.encode("utf-8"))
        digest.update((DATA / name).read_bytes())
    return digest.hexdigest()


def load_data() -> dict[str, dict]:
    return {name.removesuffix(".json"): json.loads((DATA / name).read_text(encoding="utf-8")) for name in SOURCES}


def register_fonts(directory: Path) -> None:
    # AI-NOTE: ReportLab은 가변 글꼴의 wght 축을 직접 고르지 못한다. 같은 번들 글꼴에서
    # 고정 굵기만 임시로 만들고 PDF에 포함한다. 원본 자산은 수정하지 않는다.
    for weight, name in ((400, "Pretendard-Regular"), (600, "Pretendard-Semibold"), (700, "Pretendard-Bold")):
        font = FontToolsFont(FONT_SOURCE)
        instancer.instantiateVariableFont(font, {"wght": weight}, inplace=True)
        font.recalcTimestamp = False
        font["head"].modified = 0
        font["head"].created = 0
        path = directory / f"{name}.ttf"
        font.save(path)
        font.close()
        pdfmetrics.registerFont(TTFont(name, str(path)))
    pdfmetrics.registerFontFamily("Pretendard", normal="Pretendard-Regular", bold="Pretendard-Bold")


def styles() -> dict[str, ParagraphStyle]:
    common = dict(textColor=INK, alignment=TA_LEFT, splitLongWords=0, allowWidows=0, allowOrphans=0)
    return {
        "name": ParagraphStyle("Name", fontName="Pretendard-Bold", fontSize=21, leading=29, spaceAfter=4, keepWithNext=1, **common),
        "identity": ParagraphStyle("Identity", fontName="Pretendard-Regular", fontSize=11, leading=16.5, spaceAfter=4, keepWithNext=1, **common),
        "contact": ParagraphStyle("Contact", fontName="Pretendard-Regular", fontSize=9.7, leading=15, spaceAfter=4, **common),
        "section": ParagraphStyle("Section", fontName="Pretendard-Semibold", fontSize=13.5, leading=20, spaceBefore=18, spaceAfter=4, keepWithNext=1, **common),
        "case": ParagraphStyle("Case", fontName="Pretendard-Bold", fontSize=18, leading=26, spaceAfter=4, keepWithNext=1, **common),
        "lead": ParagraphStyle("Lead", fontName="Pretendard-Regular", fontSize=11, leading=16.5, spaceAfter=10, **common),
        "body": ParagraphStyle("Body", fontName="Pretendard-Regular", fontSize=9.7, leading=15, spaceAfter=4, **common),
        "caption": ParagraphStyle("Caption", fontName="Pretendard-Regular", fontSize=8.5, leading=13, textColor=MUTED, spaceBefore=4, spaceAfter=12, **{k: v for k, v in common.items() if k != "textColor"}),
        "table": ParagraphStyle("Table", fontName="Pretendard-Regular", fontSize=9.2, leading=13.5, **common),
        "tableHead": ParagraphStyle("TableHead", fontName="Pretendard-Bold", fontSize=9.2, leading=13.5, **common),
    }


def paragraph(value: str, style: ParagraphStyle) -> Paragraph:
    return Paragraph(escape(value), style)


def heading(text: str, style: ParagraphStyle, color: colors.Color = RULE) -> list:
    return [
        paragraph(text, style),
        HRFlowable(width="100%", thickness=0.8 if color == RULE else 0.45, color=color, spaceBefore=0, spaceAfter=8),
    ]


def image_for(web_path: str, width_mm: float) -> Image:
    source = ROOT / "assets" / "media" / web_path.lstrip("/")
    from PIL import Image as PillowImage

    with PillowImage.open(source) as original:
        width, height = original.size
    placed_width = width_mm * MM
    return Image(str(source), width=placed_width, height=placed_width * height / width)


def pixel_frame(name: str, width_mm: float = 34) -> Image:
    from PIL import Image as PillowImage

    source = ROOT / "assets/media/pixel/hero/frames" / name
    with PillowImage.open(source) as original:
        enlarged = original.convert("RGBA").resize((original.width * 4, original.height * 4), PillowImage.Resampling.NEAREST)
        output = io.BytesIO()
        enlarged.save(output, format="PNG")
    output.seek(0)
    return Image(output, width=width_mm * MM, height=width_mm * MM * enlarged.height / enlarged.width)


def onion_frame(width_mm: float = 34) -> Image:
    from PIL import Image as PillowImage

    frames = []
    for index in (3, 4, 5):
        path = ROOT / f"assets/media/pixel/hero/frames/attack-{index:02d}.png"
        with PillowImage.open(path) as original:
            frames.append(original.convert("RGBA"))
    canvas_image = PillowImage.new("RGBA", frames[1].size, (255, 255, 255, 0))
    for source, tint in ((frames[0], (220, 60, 60, 150)), (frames[2], (50, 110, 220, 150))):
        alpha = source.getchannel("A").point(lambda value: value * tint[3] // 255)
        ghost = PillowImage.new("RGBA", source.size, tint[:3] + (0,))
        ghost.putalpha(alpha)
        canvas_image.alpha_composite(ghost)
    canvas_image.alpha_composite(frames[1])
    enlarged = canvas_image.resize((canvas_image.width * 4, canvas_image.height * 4), PillowImage.Resampling.NEAREST)
    output = io.BytesIO()
    enlarged.save(output, format="PNG")
    output.seek(0)
    return Image(output, width=width_mm * MM, height=width_mm * MM * enlarged.height / enlarged.width)


class PaletteGrid(Flowable):
    def __init__(self, colors_list: list[str]):
        super().__init__()
        self.colors_list = colors_list
        self.width = 8 * 4.2 * MM
        self.height = 8 * 4.2 * MM

    def draw(self):
        size = 4.2 * MM
        for index, color in enumerate(self.colors_list):
            x = (index % 8) * size
            y = self.height - ((index // 8) + 1) * size
            self.canv.setFillColor(colors.HexColor(color))
            self.canv.setStrokeColor(colors.HexColor("#DDDDDD"))
            self.canv.rect(x, y, size, size, fill=1, stroke=1)


class OutlineGrid(Flowable):
    def __init__(self):
        super().__init__()
        self.width = 7 * 4.2 * MM
        self.height = 7 * 4.2 * MM

    def draw(self):
        size = 4.2 * MM
        body = {(3, 2), (2, 3), (3, 3), (4, 3), (3, 4)}
        outline = {(x + dx, y + dy) for x, y in body for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0))} - body
        for x, y in outline | body:
            self.canv.setFillColor(INK if (x, y) in body else colors.HexColor("#B7B7B7"))
            self.canv.rect(x * size, y * size, size, size, fill=1, stroke=0)


class PipelineFlow(Flowable):
    def __init__(self):
        super().__init__()
        self.width = CONTENT_WIDTH
        self.height = 19 * MM

    def draw(self):
        labels = ("원본 레이어", "포인트 색", "추가 외곽선", "팔레트 세트")
        self.canv.setFont("Pretendard-Semibold", 10)
        self.canv.setFillColor(INK)
        self.canv.setStrokeColor(colors.HexColor("#888888"))
        for index, label in enumerate(labels):
            x = index * self.width / 4
            self.canv.drawString(x, 8 * MM, f"{index + 1:02d}  {label}")
            if index < 3:
                line_x = x + self.width / 4 - 15 * MM
                self.canv.line(line_x, 9 * MM, line_x + 8 * MM, 9 * MM)
                self.canv.line(line_x + 8 * MM, 9 * MM, line_x + 6 * MM, 10.5 * MM)
                self.canv.line(line_x + 8 * MM, 9 * MM, line_x + 6 * MM, 7.5 * MM)


class WorkflowDiagram(Flowable):
    def __init__(self, lanes: list[dict]):
        super().__init__()
        self.lanes = lanes
        self.width = CONTENT_WIDTH
        self.height = 62 * MM

    def draw(self):
        # AI-NOTE: 사용자가 PDF에 표시할 순서를 통합 검증 후 Wiki 기록으로 확정했다.
        # 원본 UI 자료의 서로 다른 표기는 이 문서 도식에서 함께 사용하지 않는다.
        self.canv.setFillColor(INK)
        self.canv.setFont("Pretendard-Semibold", 10.5)
        self.canv.drawString(0, 52 * MM, "사람  →  Master AI  →  Task Planning")
        self.canv.setStrokeColor(colors.HexColor("#B8B8B8"))
        self.canv.setLineWidth(0.5)
        self.canv.line(0, 48 * MM, self.width, 48 * MM)
        for index, lane in enumerate(self.lanes):
            y = (38 - index * 11) * MM
            self.canv.setFont("Pretendard-Semibold", 9.7)
            self.canv.drawString(0, y, f'{lane["key"]}  {lane["title"]}')
            self.canv.setFont("Pretendard-Regular", 9.4)
            self.canv.drawString(55 * MM, y, "기획 → 검수 → 개발 → 검수 → QA")
            self.canv.drawRightString(self.width, y, "READY")
            self.canv.line(0, y - 3 * MM, self.width, y - 3 * MM)
        self.canv.setFont("Pretendard-Semibold", 10.5)
        self.canv.drawString(0, 3 * MM, "병합 게이트  →  통합 검증  →  Wiki 기록")
        self.canv.line(0, 0, self.width, 0)


class SrtBoundaryDiagram(Flowable):
    def __init__(self, labels: list[str], details: tuple[str, ...], style: dict[str, ParagraphStyle]):
        super().__init__()
        self.labels = labels
        self.details = details
        self.style = style
        self.width = CONTENT_WIDTH
        self.height = 32 * MM

    def draw(self):
        column = self.width / 3
        self.canv.setStrokeColor(colors.HexColor("#C9C9C9"))
        self.canv.setLineWidth(0.4)
        self.canv.line(0, 0, self.width, 0)
        for index, (label, detail) in enumerate(zip(self.labels, self.details)):
            x = index * column
            if index:
                self.canv.line(x, 0, x, self.height)
            header = paragraph(label, self.style["tableHead"])
            body = paragraph(detail, self.style["table"])
            header.wrapOn(self.canv, column - 8 * MM, self.height)
            header.drawOn(self.canv, x + 3 * MM, self.height - 9 * MM)
            body_width, body_height = body.wrapOn(self.canv, column - 8 * MM, self.height)
            body.drawOn(self.canv, x + 3 * MM, self.height - 11 * MM - body_height)


def ruled_table(rows: list[list], widths: list[float], padding: float = 5) -> Table:
    table = Table(rows, colWidths=widths, hAlign="LEFT")
    table.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 0),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), padding),
        ("BOTTOMPADDING", (0, 0), (-1, -1), padding),
        ("LINEBELOW", (0, 0), (-1, -1), 0.4, colors.HexColor("#C9C9C9")),
    ]))
    return table


def resume_story(data: dict[str, dict], style: dict[str, ParagraphStyle]) -> list:
    resume = data["resume"]
    site = data["site"]
    about = resume["ABOUT"]
    contact = resume["CONTACT"]
    contacts = []
    for field in contact["fields"]:
        value = (field.get("value") or "").strip() or contact["emptyValue"]
        if field["id"] == "profile":
            if value != resume["PORTFOLIO_URL"] or value != PORTFOLIO_URL:
                raise ValueError("Portfolio URL differs from the authorized value")
            value = f'<link href="{PORTFOLIO_URL}" color="#111111" underline="1">{escape(value)}</link>'
        else:
            value = escape(value)
        contacts.append(f'{escape(field["label"])} {value}')
    contact_lines = [Paragraph(" · ".join(contacts[:-1]), style["contact"]), Paragraph(contacts[-1], style["contact"])]
    header = Table(
        [[
            [paragraph(site["IDENTITY"]["name"], style["name"]), paragraph(about["headline"], style["identity"]), *contact_lines],
            image_for(resume["PHOTO"]["src"], 27),
        ]],
        colWidths=[CONTENT_WIDTH - 31 * MM, 31 * MM],
        hAlign="LEFT",
    )
    header.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 0), ("RIGHTPADDING", (0, 0), (-1, -1), 0), ("TOPPADDING", (0, 0), (-1, -1), 0), ("BOTTOMPADDING", (0, 0), (-1, -1), 0)]))
    story: list = [header, Spacer(1, 3 * MM)]
    story.extend(heading(about["heading"], style["section"]))
    story.append(ruled_table([
        [paragraph(f"{index + 1:02d}", style["tableHead"]), paragraph(item["title"], style["table"])]
        for index, item in enumerate(about["values"])
    ], [10 * MM, CONTENT_WIDTH - 10 * MM], padding=3))
    career = resume["CAREER"]
    story.extend(heading(career["heading"], style["section"]))
    career_rows = []
    for entry in career["entries"]:
        period = f'{entry["start"]}–{entry["end"] or resume["PRESENT_LABEL"]}'
        career_rows.append([
            Paragraph(f'<font name="Pretendard-Semibold">{escape(entry["company"])}</font><br/>{escape(entry["role"])}', style["table"]),
            paragraph(period, style["table"]),
            paragraph(entry["duties"][0], style["table"]),
        ])
    story.append(ruled_table(career_rows, [39 * MM, 33 * MM, CONTENT_WIDTH - 72 * MM], padding=4))
    skills = resume["SKILLS"]
    story.extend(heading(skills["heading"], style["section"]))
    education = [" · ".join(str(item[key]) for key in ("date", "school", "major", "degree") if item.get(key)) for item in skills["education"]]
    story.append(ruled_table([[paragraph(skills["educationHeading"] if index == 0 else "", style["tableHead"]), paragraph(item, style["table"])] for index, item in enumerate(education)], [33 * MM, CONTENT_WIDTH - 33 * MM], padding=2.5))
    skill_rows = [[paragraph(group["label"], style["tableHead"]), paragraph(", ".join(group["items"]), style["table"])] for group in skills["groups"]]
    story.append(ruled_table(skill_rows, [33 * MM, CONTENT_WIDTH - 33 * MM], padding=2.5))
    return story


def case_story(data: dict[str, dict], index: int, style: dict[str, ParagraphStyle]) -> list:
    case = data["site"]["CASES"][index]
    lead = SRT_LEAD if index == 2 else WORKFLOW_LEAD if index == 0 else case["summary"]
    problem = SRT_PROBLEM if index == 2 else case["problem"]
    story: list = [PageBreak(), *heading(f'{case["index"]}  {case["title"]}', style["case"]), paragraph(lead, style["lead"]), paragraph(problem, style["body"])]
    if index == 0:
        story.extend(heading("작업 경로", style["section"], MUTED))
        story.append(WorkflowDiagram(data["workflowDetail"]["DETAIL_LANES"]))
        story.extend(heading("처리 흐름", style["section"], MUTED))
        steps = data["site"]["WORKFLOW_SUMMARY"]["steps"]
        rows = [[paragraph(f'{i + 1:02d}', style["tableHead"]), paragraph(step["label"], style["tableHead"]), paragraph(step["text"], style["table"])] for i, step in enumerate(steps)]
        story.append(ruled_table(rows, [12 * MM, 43 * MM, CONTENT_WIDTH - 55 * MM], padding=8))
        story.extend(heading("판단과 복구", style["section"], MUTED))
        summary = data["site"]["WORKFLOW_SUMMARY"]
        story.append(ruled_table([
            [paragraph("사람 판단", style["tableHead"]), paragraph(summary["humanNote"], style["table"])],
            [paragraph("실패 복구", style["tableHead"]), paragraph(summary["returnNote"], style["table"])],
        ], [30 * MM, CONTENT_WIDTH - 30 * MM], padding=7))
        story.extend(heading("맡은 일", style["section"], MUTED))
        roles = list(case["role"])
        roles[1] = "기획·검수·개발·QA와 단계별 감독·중재 규칙 정의"
        story.append(ruled_table([[paragraph(f'{i + 1:02d}', style["tableHead"]), paragraph(item, style["table"])] for i, item in enumerate(roles)], [10 * MM, CONTENT_WIDTH - 10 * MM], padding=5))
    elif index == 1:
        points = data["site"]["SPRITE_BRIEF"]["points"]
        source_counts = points[0]["text"]
        counts = re.search(r"레이어 (\d+)개와 셀\(걷기 (\d+) · 달리기 (\d+) · 공격 (\d+)\)", source_counts)
        if counts is None:
            raise ValueError("Review layer/frame counts after source data changes")
        palette = next(item for item in data["pixel-palette-sets"] if item["id"] == "aap64")
        story.extend(heading("색 파이프라인", style["section"], MUTED))
        story.append(PipelineFlow())
        outline_panel = [paragraph("추가 외곽선", style["tableHead"]), Spacer(1, 2 * MM), OutlineGrid(), paragraph("검정: 원본 픽셀 · 회색: 추가 외곽선", style["caption"])]
        palette_panel = [paragraph("팔레트 세트", style["tableHead"]), Spacer(1, 2 * MM), PaletteGrid(palette["colors"]), paragraph("AAP-64 · 64색 / 적용 비율 0–100%", style["caption"])]
        color_row = Table([[outline_panel, palette_panel]], colWidths=[CONTENT_WIDTH / 2] * 2, hAlign="LEFT")
        color_row.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 0), ("RIGHTPADDING", (0, 0), (-1, -1), 5 * MM), ("TOPPADDING", (0, 0), (-1, -1), 0), ("BOTTOMPADDING", (0, 0), (-1, -1), 0)]))
        story.append(color_row)
        story.extend(heading("프레임 점검", style["section"], MUTED))
        current = pixel_frame("attack-04.png")
        current.hAlign = "CENTER"
        onion = onion_frame()
        onion.hAlign = "CENTER"
        frame_row = Table([[
            [paragraph("현재 프레임 · 공격 04", style["tableHead"]), current, paragraph("원본 픽셀 프레임", style["caption"])],
            [paragraph("어니언 스킨 · 공격 03 / 04 / 05", style["tableHead"]), onion, paragraph("빨강: 이전 · 파랑: 다음 · 원본: 현재", style["caption"])],
        ]], colWidths=[CONTENT_WIDTH / 2] * 2, hAlign="LEFT")
        frame_row.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 0), ("RIGHTPADDING", (0, 0), (-1, -1), 5 * MM), ("TOPPADDING", (0, 0), (-1, -1), 0), ("BOTTOMPADDING", (0, 0), (-1, -1), 0)]))
        story.append(frame_row)
        story.extend(heading("원본 데이터", style["section"], MUTED))
        story.append(ruled_table([
            [paragraph("원본 레이어", style["tableHead"]), paragraph(f"{counts.group(1)}개", style["table"])],
            [paragraph("미리보기 재생 프레임", style["tableHead"]), paragraph(f"걷기 {counts.group(2)} · 달리기 {counts.group(3)} · 공격 {counts.group(4)}", style["table"])],
        ], [32 * MM, CONTENT_WIDTH - 32 * MM], padding=3))
        story.append(paragraph("원본 편집기는 5가지 모션을 저장합니다. 위 도식은 상세 미리보기의 공격 프레임을 사용합니다.", style["caption"]))
    else:
        pipeline = data["subtitles"]["SUBTITLE_PIPELINE"]
        if len(pipeline) != len(SRT_ACTIONS):
            raise ValueError("Review condensed SRT actions after pipeline changes")
        story.extend(heading("처리 흐름", style["section"], MUTED))
        rows = [[paragraph(f'{i + 1:02d}', style["tableHead"]), paragraph(step["label"], style["tableHead"]), paragraph(SRT_ACTIONS[i], style["table"])] for i, step in enumerate(pipeline)]
        story.append(ruled_table(rows, [12 * MM, 34 * MM, CONTENT_WIDTH - 46 * MM], padding=8))
        story.extend(heading("역할과 경계", style["section"], MUTED))
        points = data["site"]["SRT_BRIEF"]["points"]
        story.append(SrtBoundaryDiagram([point["label"] for point in points], SRT_BOUNDARIES, style))
    return story


class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_pages: list[dict] = []

    def showPage(self):
        self._saved_pages.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        total = len(self._saved_pages)
        for state in self._saved_pages:
            self.__dict__.update(state)
            self.setFont("Pretendard-Regular", 8)
            self.setFillColor(MUTED)
            self.drawCentredString(PAGE_WIDTH / 2, 11 * 72 / 25.4, f"{self._pageNumber} / {total}")
            super().showPage()
        super().save()


def build_pdf() -> None:
    rl_config.invariant = 1
    data = load_data()
    with tempfile.TemporaryDirectory(prefix="portfolio-fonts-") as temporary:
        register_fonts(Path(temporary))
        style = styles()
        story = resume_story(data, style)
        for index in range(3):
            story.extend(case_story(data, index, style))
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4, leftMargin=MARGIN, rightMargin=MARGIN, topMargin=MARGIN, bottomMargin=MARGIN + 6 * 72 / 25.4, title=TITLE, invariant=1)
        doc.build(story, canvasmaker=NumberedCanvas)
        reader = PdfReader(io.BytesIO(buffer.getvalue()))
        writer = PdfWriter()
        writer.clone_document_from_reader(reader)
        writer._root_object[NameObject("/Lang")] = TextStringObject("ko")
        writer._root_object.pop(NameObject("/Metadata"), None)
        for page in writer.pages:
            resources = page.get("/Resources", {})
            for resource in resources.get("/XObject", {}).values():
                image = resource.get_object()
                if image.get("/Subtype") == "/Image":
                    image[NameObject("/Interpolate")] = BooleanObject(False)
        writer.add_metadata({"/Title": TITLE, "/Subject": "", "/Keywords": f"source-sha256:{source_digest()}", "/Author": "", "/Creator": "", "/Producer": "", "/CreationDate": "", "/ModDate": ""})
        with OUTPUT.open("wb") as destination:
            writer.write(destination)
    print(f"Generated {OUTPUT.relative_to(ROOT)} ({len(reader.pages)} pages)")


if __name__ == "__main__":
    build_pdf()
