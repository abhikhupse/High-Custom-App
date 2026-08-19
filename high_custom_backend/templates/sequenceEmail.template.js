// ============================================================
// SEQUENCE EMAIL TEMPLATE
// ============================================================

function escapeHtml(value = "") {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

// ============================================================
// TEXT COLOR
// ============================================================

function getTextColor(color) {
  switch (color) {
    case "White":
      return "#FFFFFF";

    case "Gray":
      return "#667085";

    case "Red":
      return "#FF0000";

    case "Blue":
      return "#0000FF";

    case "Green":
      return "#008000";

    case "Gold":
      return "#D4AF37";

    case "Black":
    default:
      return "#000000";
  }
}

// ============================================================
// FONT
// ============================================================

function getFont(font) {
  switch (font) {
    case "Roboto":
      return "Roboto, Arial, sans-serif";

    case "Helvetica":
      return "Helvetica, Arial, sans-serif";

    case "Times New Roman":
      return "'Times New Roman', Times, serif";

    case "Georgia":
      return "Georgia, serif";

    case "Verdana":
      return "Verdana, Arial, sans-serif";

    case "Arial":
    default:
      return "Arial, Helvetica, sans-serif";
  }
}

// ============================================================
// LOGO ALIGNMENT
// ============================================================

function getLogoAlignment(position) {
  switch (position) {
    case "Left":
      return "left";

    case "Right":
      return "right";

    case "Center":
    default:
      return "center";
  }
}

// ============================================================
// CONTENT FORMAT
// ============================================================

function formatContent(content = "") {
  let html = escapeHtml(content);

  /*
   * Preserve line breaks from Flutter text editor.
   */
  html = html.replace(/\r\n/g, "\n");
  html = html.replace(/\r/g, "\n");
  html = html.replace(/\n/g, "<br>");

  return html;
}

// ============================================================
// MAIN TEMPLATE
// ============================================================

function buildSequenceEmail({ sequence, lead, trackingUrl, baseUrl }) {
  const brand = sequence.brand || {};
  const heroImage = sequence.heroImage || {};
  const editor = sequence.editor || {};
  const attachment = sequence.attachment || {};
  const actionLinks = sequence.actionLinks || {};

  const subject = escapeHtml(sequence.subject || "");

  const logoUrl = brand.logoUrl || "";
  const logoPosition = getLogoAlignment(brand.logoPosition || "Center");

  const heroUrl = heroImage.url || "";

  const font = getFont(editor.font || "Arial");

  const fontSize = editor.fontSize || "16px";

  const textColor = getTextColor(editor.textColor || "Black");

  const fontWeight = editor.bold ? "700" : "400";

  const fontStyle = editor.italic ? "italic" : "normal";

  const textDecoration = editor.underline ? "underline" : "none";

  const content = formatContent(sequence.content || "");

  // ==========================================================
  // CTA
  // ==========================================================

  let ctaHtml = "";

  if (actionLinks.cta && actionLinks.cta.text && actionLinks.cta.url) {
    ctaHtml = `
      <div style="
        padding: 6px 20px;
      ">
        <a
          href="${escapeHtml(actionLinks.cta.url)}"
          target="_blank"
          style="
            display:block;
            width:100%;
            box-sizing:border-box;
            background:#315BEF;
            color:#FFFFFF;
            text-decoration:none;
            text-align:center;
            padding:11px 10px;
            border-radius:6px;
            font-family:Arial,Helvetica,sans-serif;
            font-size:13px;
            font-weight:700;
          "
        >
          ${escapeHtml(actionLinks.cta.text)}
        </a>
      </div>
    `;
  }

  // ==========================================================
  // WHATSAPP
  // ==========================================================

  let whatsappHtml = "";

  if (actionLinks.whatsapp) {
    whatsappHtml = `
      <div style="
        padding:5px 20px;
      ">
        <a
          href="${escapeHtml(actionLinks.whatsapp)}"
          target="_blank"
          style="
            display:block;
            width:100%;
            box-sizing:border-box;
            background:#25D366;
            color:#FFFFFF;
            text-decoration:none;
            text-align:center;
            padding:11px 10px;
            border-radius:6px;
            font-family:Arial,Helvetica,sans-serif;
            font-size:13px;
            font-weight:700;
          "
        >
          WhatsApp
        </a>
      </div>
    `;
  }

  // ==========================================================
  // ATTACHMENT
  // ==========================================================

  let attachmentHtml = "";

  if (attachment.url && attachment.name) {
    attachmentHtml = `
      <div style="
        padding:10px 20px;
        font-family:Arial,Helvetica,sans-serif;
        font-size:12px;
      ">
        <a
          href="${escapeHtml(attachment.url)}"
          target="_blank"
          style="
            color:#315BEF;
            text-decoration:none;
          "
        >
          📎 ${escapeHtml(attachment.name)}
        </a>
      </div>
    `;
  }

  // ==========================================================
  // LOGO
  // ==========================================================

  let logoHtml = "";

  if (logoUrl) {
    logoHtml = `
      <div style="
        width:100%;
        box-sizing:border-box;
        padding:8px 20px;
        text-align:${logoPosition};
      ">
        <img
          src="${escapeHtml(logoUrl)}"
          alt="Company Logo"
          style="
            max-width:170px;
            max-height:68px;
            width:auto;
            height:auto;
            display:inline-block;
            border:0;
          "
        />
      </div>
    `;
  }

  // ==========================================================
  // HERO
  // ==========================================================

  let heroHtml = "";

  if (heroUrl) {
    const heroLink = heroImage.link || "";

    const heroImageHtml = `
      <img
        src="${escapeHtml(heroUrl)}"
        alt="Hero Image"
        style="
          display:block;
          width:100%;
          max-width:100%;
          height:auto;
          border:0;
          border-radius:8px;
        "
      />
    `;

    if (heroLink) {
      heroHtml = `
        <div style="
          padding:0 18px;
        ">
          <a
            href="${escapeHtml(heroLink)}"
            target="_blank"
            style="text-decoration:none;"
          >
            ${heroImageHtml}
          </a>
        </div>
      `;
    } else {
      heroHtml = `
        <div style="
          padding:0 18px;
        ">
          ${heroImageHtml}
        </div>
      `;
    }
  }

  // ==========================================================
  // TRACKING PIXEL
  // ==========================================================

  const trackingPixel = trackingUrl
    ? `
      <img
        src="${escapeHtml(trackingUrl)}"
        width="1"
        height="1"
        alt=""
        style="
          display:block;
          width:1px;
          height:1px;
          border:0;
          margin:0;
          padding:0;
        "
      />
    `
    : "";

  // ==========================================================
  // FINAL HTML
  // ==========================================================

  return `
<!DOCTYPE html>

<html>

<head>

<meta
  http-equiv="Content-Type"
  content="text/html; charset=UTF-8"
/>

<meta
  name="viewport"
  content="width=device-width, initial-scale=1.0"
/>

<title>${subject}</title>

</head>

<body
  style="
    margin:0;
    padding:0;
    background:#F2F4F7;
    font-family:${font};
  "
>

<table
  width="100%"
  cellpadding="0"
  cellspacing="0"
  border="0"
  style="
    background:#F2F4F7;
    margin:0;
    padding:20px 0;
  "
>

<tr>

<td
  align="center"
>

<table
  width="680"
  cellpadding="0"
  cellspacing="0"
  border="0"
  style="
    width:100%;
    max-width:680px;
    background:#FFFFFF;
    border:1px solid #E4E7EC;
    border-radius:10px;
    overflow:hidden;
  "
>

<!-- ====================================================== -->
<!-- BRAND HEADER -->
<!-- ====================================================== -->

<tr>

<td
  style="
    padding:14px 20px;
    border-bottom:1px solid #E4E7EC;
    background:#FFFFFF;
  "
>

<table
  width="100%"
  cellpadding="0"
  cellspacing="0"
  border="0"
>

<tr>

<td
  width="36"
  valign="middle"
>

<div
  style="
    width:36px;
    height:36px;
    background:#F0F3FF;
    border-radius:8px;
    text-align:center;
    line-height:36px;
    font-family:Arial,Helvetica,sans-serif;
    color:#315BEF;
  "
>
  ✉
</div>

</td>

<td
  style="
    padding-left:9px;
  "
>

<div
  style="
    color:#101828;
    font-size:12px;
    font-weight:800;
    line-height:18px;
  "
>
  Your Company
</div>

<div
  style="
    color:#667085;
    font-size:9px;
    line-height:13px;
  "
>
  Email communication
</div>

</td>

<td
  width="20"
  align="right"
  valign="middle"
  style="
    color:#667085;
    font-size:18px;
  "
>
  ⋯
</td>

</tr>

</table>

</td>

</tr>

<!-- ====================================================== -->
<!-- LOGO -->
<!-- ====================================================== -->

${logoHtml}

<!-- ====================================================== -->
<!-- HERO -->
<!-- ====================================================== -->

${heroHtml}

<!-- ====================================================== -->
<!-- CONTENT -->
<!-- ====================================================== -->

<tr>

<td
  style="
    padding:18px 20px 10px 20px;
    color:${textColor};
    font-family:${font};
    font-size:${fontSize};
    line-height:1.5;
    font-weight:${fontWeight};
    font-style:${fontStyle};
    text-decoration:${textDecoration};
  "
>

${content}

</td>

</tr>

<!-- ====================================================== -->
<!-- CTA -->
<!-- ====================================================== -->

<tr>

<td>

${ctaHtml}

</td>

</tr>

<!-- ====================================================== -->
<!-- WHATSAPP -->
<!-- ====================================================== -->

<tr>

<td>

${whatsappHtml}

</td>

</tr>

<!-- ====================================================== -->
<!-- ATTACHMENT -->
<!-- ====================================================== -->

<tr>

<td>

${attachmentHtml}

</td>

</tr>

<!-- ====================================================== -->
<!-- FOOTER -->
<!-- ====================================================== -->

<tr>

<td
  style="
    padding:11px 10px;
    background:#F8FAFC;
    border-top:1px solid #E4E7EC;
    text-align:center;
    color:#667085;
    font-family:Arial,Helvetica,sans-serif;
    font-size:8px;
    line-height:1.3;
  "
>

You are receiving this email because you subscribed
to our updates.

</td>

</tr>

</table>

</td>

</tr>

</table>

${trackingPixel}

</body>

</html>
`;
}

module.exports = {
  buildSequenceEmail,
};
