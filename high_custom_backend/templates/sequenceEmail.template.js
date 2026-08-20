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
// URL VALIDATION
// ============================================================

function isValidUrl(value) {
  if (typeof value !== "string" || value.trim() === "") {
    return false;
  }

  const url = value.trim();

  return url.startsWith("https://") || url.startsWith("http://");
}

// ============================================================
// CONTENT FORMAT
// ============================================================

function formatContent(content = "") {
  let html = escapeHtml(content);

  html = html.replace(/\r\n/g, "\n");
  html = html.replace(/\r/g, "\n");

  html = html.replace(/\n/g, "<br>");

  return html;
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
// MAIN EMAIL TEMPLATE
// ============================================================

function buildSequenceEmail({
  sequence = {},
  lead = {},
  trackingUrl = null,
  baseUrl = null,
}) {
  // ==========================================================
  // SAFE OBJECTS
  // ==========================================================

  const brand =
    sequence.brand && typeof sequence.brand === "object" ? sequence.brand : {};

  const heroImage =
    sequence.heroImage && typeof sequence.heroImage === "object"
      ? sequence.heroImage
      : {};

  const editor =
    sequence.editor && typeof sequence.editor === "object"
      ? sequence.editor
      : {};

  const attachment =
    sequence.attachment && typeof sequence.attachment === "object"
      ? sequence.attachment
      : {};

  const actionLinks =
    sequence.actionLinks && typeof sequence.actionLinks === "object"
      ? sequence.actionLinks
      : {};

  // ==========================================================
  // SUBJECT
  // ==========================================================

  const subject = escapeHtml(sequence.subject || "");

  // ==========================================================
  // LOGO
  // ==========================================================

  const logoUrl = typeof brand.logoUrl === "string" ? brand.logoUrl.trim() : "";

  const logoPosition = getLogoAlignment(brand.logoPosition || "Center");

  // ==========================================================
  // HERO / BANNER
  // ==========================================================

  const heroUrl = typeof heroImage.url === "string" ? heroImage.url.trim() : "";

  const heroLink =
    typeof heroImage.link === "string" ? heroImage.link.trim() : "";

  // ==========================================================
  // EDITOR
  // ==========================================================

  const font = getFont(editor.font || "Arial");

  const fontSize = editor.fontSize || "16px";

  const textColor = getTextColor(editor.textColor || "Black");

  const fontWeight = editor.bold === true ? "700" : "400";

  const fontStyle = editor.italic === true ? "italic" : "normal";

  const textDecoration = editor.underline === true ? "underline" : "none";

  // ==========================================================
  // CONTENT
  // ==========================================================

  const content = formatContent(sequence.content || "");

  // ==========================================================
  // OPTIONAL LOGO
  // ==========================================================

  let logoHtml = "";

  if (isValidUrl(logoUrl)) {
    logoHtml = `
      <tr>
        <td
          style="
            padding:20px;
            text-align:${logoPosition};
          "
        >
          <img
            src="${escapeHtml(logoUrl)}"
            alt=""
            style="
              display:inline-block;
              max-width:180px;
              max-height:80px;
              width:auto;
              height:auto;
              border:0;
            "
          />
        </td>
      </tr>
    `;
  }

  // ==========================================================
  // OPTIONAL HERO / BANNER
  // ==========================================================

  let heroHtml = "";

  if (isValidUrl(heroUrl)) {
    const imageHtml = `
      <img
        src="${escapeHtml(heroUrl)}"
        alt=""
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

    if (isValidUrl(heroLink)) {
      heroHtml = `
        <tr>
          <td
            style="
              padding:0 20px 20px 20px;
            "
          >
            <a
              href="${escapeHtml(heroLink)}"
              target="_blank"
              rel="noopener noreferrer"
              style="
                text-decoration:none;
              "
            >
              ${imageHtml}
            </a>
          </td>
        </tr>
      `;
    } else {
      heroHtml = `
        <tr>
          <td
            style="
              padding:0 20px 20px 20px;
            "
          >
            ${imageHtml}
          </td>
        </tr>
      `;
    }
  }

  // ==========================================================
  // OPTIONAL CTA BUTTON
  // ==========================================================

  let ctaHtml = "";

  const cta =
    actionLinks.cta && typeof actionLinks.cta === "object"
      ? actionLinks.cta
      : null;

  const ctaText = cta && typeof cta.text === "string" ? cta.text.trim() : "";

  const ctaUrl = cta && typeof cta.url === "string" ? cta.url.trim() : "";

  if (ctaText !== "" && isValidUrl(ctaUrl)) {
    ctaHtml = `
      <tr>
        <td
          style="
            padding:0 20px 20px 20px;
          "
        >
          <a
            href="${escapeHtml(ctaUrl)}"
            target="_blank"
            rel="noopener noreferrer"
            style="
              display:block;
              width:100%;
              box-sizing:border-box;
              background:#315BEF;
              color:#FFFFFF;
              text-decoration:none;
              text-align:center;
              padding:12px 10px;
              border-radius:6px;
              font-family:Arial,Helvetica,sans-serif;
              font-size:13px;
              font-weight:700;
            "
          >
            ${escapeHtml(ctaText)}
          </a>
        </td>
      </tr>
    `;
  }

  // ==========================================================
  // OPTIONAL WHATSAPP BUTTON
  // ==========================================================

  let whatsappHtml = "";

  const whatsappUrl =
    typeof actionLinks.whatsapp === "string" ? actionLinks.whatsapp.trim() : "";

  if (isValidUrl(whatsappUrl)) {
    whatsappHtml = `
      <tr>
        <td
          style="
            padding:0 20px 20px 20px;
          "
        >
          <a
            href="${escapeHtml(whatsappUrl)}"
            target="_blank"
            rel="noopener noreferrer"
            style="
              display:block;
              width:100%;
              box-sizing:border-box;
              background:#25D366;
              color:#FFFFFF;
              text-decoration:none;
              text-align:center;
              padding:12px 10px;
              border-radius:6px;
              font-family:Arial,Helvetica,sans-serif;
              font-size:13px;
              font-weight:700;
            "
          >
            WhatsApp
          </a>
        </td>
      </tr>
    `;
  }

  // ==========================================================
  // OPTIONAL FILE
  // ==========================================================

  let attachmentHtml = "";

  const attachmentUrl =
    typeof attachment.url === "string" ? attachment.url.trim() : "";

  const attachmentName =
    typeof attachment.name === "string" ? attachment.name.trim() : "";

  if (isValidUrl(attachmentUrl) && attachmentName !== "") {
    attachmentHtml = `
      <tr>
        <td
          style="
            padding:0 20px 20px 20px;
            font-family:Arial,Helvetica,sans-serif;
            font-size:13px;
          "
        >
          <a
            href="${escapeHtml(attachmentUrl)}"
            target="_blank"
            rel="noopener noreferrer"
            style="
              color:#315BEF;
              text-decoration:none;
            "
          >
            📎 ${escapeHtml(attachmentName)}
          </a>
        </td>
      </tr>
    `;
  }

  // ==========================================================
  // TRACKING PIXEL
  // ==========================================================

  let trackingPixel = "";

  if (isValidUrl(trackingUrl)) {
    trackingPixel = `
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
    `;
  }

  // ==========================================================
  // FINAL EMAIL HTML
  //
  // IMPORTANT:
  // There is NO hard-coded:
  // - logo
  // - banner
  // - image
  // - WhatsApp
  // - CTA
  // - attachment
  // - company header
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
    background:#FFFFFF;
  "
>

<table
  width="100%"
  cellpadding="0"
  cellspacing="0"
  border="0"
  style="
    width:100%;
    margin:0;
    padding:0;
    background:#FFFFFF;
  "
>

<tr>

<td align="center">

<table
  width="680"
  cellpadding="0"
  cellspacing="0"
  border="0"
  style="
    width:100%;
    max-width:680px;
    margin:0 auto;
    background:#FFFFFF;
  "
>

<!-- ====================================================== -->
<!-- LOGO - ONLY IF ADDED -->
<!-- ====================================================== -->

${logoHtml}

<!-- ====================================================== -->
<!-- BANNER - ONLY IF ADDED -->
<!-- ====================================================== -->

${heroHtml}

<!-- ====================================================== -->
<!-- CONTENT -->
<!-- ====================================================== -->

<tr>

<td
  style="
    padding:20px;
    color:${textColor};
    font-family:${font};
    font-size:${fontSize};
    line-height:1.6;
    font-weight:${fontWeight};
    font-style:${fontStyle};
    text-decoration:${textDecoration};
  "
>

${content}

</td>

</tr>

<!-- ====================================================== -->
<!-- CTA - ONLY IF ADDED -->
<!-- ====================================================== -->

${ctaHtml}

<!-- ====================================================== -->
<!-- WHATSAPP - ONLY IF ADDED -->
<!-- ====================================================== -->

${whatsappHtml}

<!-- ====================================================== -->
<!-- FILE - ONLY IF ADDED -->
<!-- ====================================================== -->

${attachmentHtml}

</table>

</td>

</tr>

</table>

${trackingPixel}

</body>

</html>
`;
}

// ============================================================
// EXPORT
// ============================================================

module.exports = {
  buildSequenceEmail,
};
