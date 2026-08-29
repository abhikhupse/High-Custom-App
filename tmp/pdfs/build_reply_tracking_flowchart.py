from reportlab.lib import colors
from reportlab.lib.pagesizes import A3, landscape
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.pdfgen import canvas


OUTPUT = r"C:\High Custom App\output\pdf\recipient-reply-tracking-flowchart.pdf"
PAGE_W, PAGE_H = landscape(A3)

NAVY = colors.HexColor("#07111A")
PANEL = colors.HexColor("#0D1B27")
PANEL_2 = colors.HexColor("#122739")
GOLD = colors.HexColor("#F2C45F")
BLUE = colors.HexColor("#4EA1FF")
GREEN = colors.HexColor("#37D67A")
ORANGE = colors.HexColor("#FF9D3D")
RED = colors.HexColor("#FF6673")
WHITE = colors.HexColor("#F7FAFC")
MUTED = colors.HexColor("#A8B4C0")
LINE = colors.HexColor("#688093")


def wrap(text, font, size, max_width):
    words = text.split()
    lines, current = [], ""
    for word in words:
        candidate = word if not current else f"{current} {word}"
        if stringWidth(candidate, font, size) <= max_width:
            current = candidate
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def node(c, x, y, w, h, title, subtitle=None, stroke=BLUE, fill=PANEL_2):
    c.setFillColor(fill)
    c.setStrokeColor(stroke)
    c.setLineWidth(1.6)
    c.roundRect(x, y, w, h, 10, fill=1, stroke=1)
    title_lines = wrap(title, "Helvetica-Bold", 10, w - 18)
    subtitle_lines = wrap(subtitle, "Helvetica", 8, w - 18) if subtitle else []
    total_h = len(title_lines) * 12 + len(subtitle_lines) * 10
    ty = y + (h + total_h) / 2 - 10
    c.setFillColor(WHITE)
    c.setFont("Helvetica-Bold", 10)
    for line in title_lines:
        c.drawCentredString(x + w / 2, ty, line)
        ty -= 12
    c.setFillColor(MUTED)
    c.setFont("Helvetica", 8)
    for line in subtitle_lines:
        c.drawCentredString(x + w / 2, ty, line)
        ty -= 10


def decision(c, cx, cy, w, h, text):
    pts = [(cx, cy + h / 2), (cx + w / 2, cy), (cx, cy - h / 2), (cx - w / 2, cy)]
    path = c.beginPath()
    path.moveTo(*pts[0])
    for pt in pts[1:]:
        path.lineTo(*pt)
    path.close()
    c.setFillColor(colors.HexColor("#172534"))
    c.setStrokeColor(ORANGE)
    c.setLineWidth(1.6)
    c.drawPath(path, fill=1, stroke=1)
    lines = wrap(text, "Helvetica-Bold", 9, w * 0.66)
    ty = cy + (len(lines) - 1) * 5
    c.setFillColor(WHITE)
    c.setFont("Helvetica-Bold", 9)
    for line in lines:
        c.drawCentredString(cx, ty, line)
        ty -= 10


def arrow(c, x1, y1, x2, y2, label=None, color=LINE):
    c.setStrokeColor(color)
    c.setFillColor(color)
    c.setLineWidth(1.5)
    c.line(x1, y1, x2, y2)
    import math
    angle = math.atan2(y2 - y1, x2 - x1)
    length = 7
    spread = 0.48
    c.line(x2, y2, x2 - length * math.cos(angle - spread), y2 - length * math.sin(angle - spread))
    c.line(x2, y2, x2 - length * math.cos(angle + spread), y2 - length * math.sin(angle + spread))
    if label:
        mx, my = (x1 + x2) / 2, (y1 + y2) / 2
        c.setFont("Helvetica-Bold", 8)
        c.setFillColor(GREEN if label == "YES" else RED)
        c.drawCentredString(mx, my + 5, label)


def poly_arrow(c, points, label=None, color=LINE):
    c.setStrokeColor(color)
    c.setLineWidth(1.5)
    path = c.beginPath()
    path.moveTo(*points[0])
    for point in points[1:]:
        path.lineTo(*point)
    c.drawPath(path, fill=0, stroke=1)
    arrow(c, points[-2][0], points[-2][1], points[-1][0], points[-1][1], label, color)


def branch_label(c, x, y, text):
    c.setFont("Helvetica-Bold", 8)
    c.setFillColor(GREEN if text == "YES" else RED)
    c.drawCentredString(x, y, text)


def build():
    c = canvas.Canvas(OUTPUT, pagesize=(PAGE_W, PAGE_H))
    c.setTitle("Recipient Reply Tracking Flowchart")
    c.setAuthor("High Custom App")
    c.setFillColor(NAVY)
    c.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)

    c.setFillColor(WHITE)
    c.setFont("Helvetica-Bold", 25)
    c.drawString(46, PAGE_H - 52, "Recipient Reply Tracking")
    c.setFillColor(MUTED)
    c.setFont("Helvetica", 11)
    c.drawString(46, PAGE_H - 72, "Recommended first version: periodic Gmail thread checking")

    # Phase labels
    phases = [
        (46, 230, "1  SEND & STORE"),
        (302, 220, "2  CHECK GMAIL"),
        (548, 370, "3  VALIDATE REPLY"),
        (946, 200, "4  SAVE & DISPLAY"),
    ]
    for x, w, title in phases:
        c.setFillColor(colors.HexColor("#0A1721"))
        c.roundRect(x, 62, w, PAGE_H - 160, 12, fill=1, stroke=0)
        c.setFillColor(GOLD)
        c.setFont("Helvetica-Bold", 10)
        c.drawString(x + 14, PAGE_H - 116, title)

    # Phase 1
    node(c, 76, 560, 170, 62, "Sequence sends email", "Through the connected Gmail account", GOLD)
    node(c, 76, 438, 170, 78, "Save delivery identifiers", "messageId, threadId, recipient email and sentAt", BLUE)
    arrow(c, 161, 560, 161, 516)

    # Phase 2
    node(c, 327, 560, 170, 62, "Reply checker runs", "Every 1-5 minutes", GOLD)
    decision(c, 412, 453, 142, 76, "Already marked Replied?")
    decision(c, 412, 318, 142, 76, "Valid Gmail threadId?")
    node(c, 327, 176, 170, 62, "Retrieve Gmail thread", "Use users.threads.get", BLUE)
    arrow(c, 412, 560, 412, 491)
    arrow(c, 412, 415, 412, 356, "NO")
    arrow(c, 412, 280, 412, 238, "YES")

    # Skip lane
    node(c, 313, 92, 198, 46, "Skip and check next delivery", None, LINE, PANEL)
    poly_arrow(c, [(483, 453), (520, 453), (520, 115), (511, 115)])
    poly_arrow(c, [(341, 318), (295, 318), (295, 115), (313, 115)])
    branch_label(c, 497, 461, "YES")
    branch_label(c, 319, 326, "NO")

    # Phase 3 validation chain
    decision(c, 630, 564, 132, 72, "New message found?")
    decision(c, 830, 564, 132, 72, "Received after sentAt?")
    decision(c, 630, 403, 132, 72, "Sent by connected account?")
    decision(c, 830, 403, 132, 72, "From matches recipient?")
    decision(c, 630, 242, 132, 72, "Bounce or automatic reply?")
    decision(c, 830, 242, 132, 72, "Already processed?")

    poly_arrow(c, [(497, 207), (526, 207), (526, 564), (564, 564)])
    arrow(c, 696, 564, 764, 564, "YES")
    poly_arrow(c, [(830, 528), (830, 475), (696, 421)], "YES")
    arrow(c, 696, 403, 764, 403, "NO")
    poly_arrow(c, [(830, 367), (830, 314), (696, 260)], "YES")
    arrow(c, 696, 242, 764, 242, "NO")

    # Invalid outcomes to skip lane
    poly_arrow(c, [(630, 528), (548, 500), (548, 115), (511, 115)])
    poly_arrow(c, [(896, 564), (925, 564), (925, 115), (511, 115)])
    poly_arrow(c, [(630, 367), (548, 340), (548, 115), (511, 115)])
    poly_arrow(c, [(896, 403), (925, 403), (925, 115), (511, 115)])
    poly_arrow(c, [(630, 206), (548, 180), (548, 115), (511, 115)])
    poly_arrow(c, [(830, 206), (830, 144), (511, 115)])
    branch_label(c, 606, 522, "NO")
    branch_label(c, 910, 572, "NO")
    branch_label(c, 606, 361, "YES")
    branch_label(c, 910, 411, "NO")
    branch_label(c, 606, 200, "YES")
    branch_label(c, 838, 184, "YES")

    # Phase 4
    node(c, 971, 520, 150, 74, "Save reply metadata", "repliedAt, replyMessageId, replyFrom and optional snippet", GREEN)
    node(c, 971, 386, 150, 62, "Set status to Replied", "Delivery and lead", GREEN)
    node(c, 971, 250, 150, 76, "Refresh app reporting", "Leads, Tracking Report and Dashboard", GOLD)
    node(c, 971, 112, 150, 62, "Reply visible to user", "Duplicate-safe result", GREEN)

    poly_arrow(c, [(896, 242), (945, 242), (945, 557), (971, 557)], "NO")
    arrow(c, 1046, 520, 1046, 448)
    arrow(c, 1046, 386, 1046, 326)
    arrow(c, 1046, 250, 1046, 174)

    c.setFillColor(MUTED)
    c.setFont("Helvetica", 8)
    c.drawRightString(PAGE_W - 42, 28, "High Custom App - planning document - no application code included")
    c.save()


if __name__ == "__main__":
    build()
