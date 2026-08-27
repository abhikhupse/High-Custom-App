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
// VALID URL
// ============================================================

function isValidUrl(value) {
  if (typeof value !== "string" || value.trim() === "") {
    return false;
  }

  const url = value.trim();

  return url.startsWith("https://") || url.startsWith("http://");
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
// LOGO POSITION
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
// CONTENT
// ============================================================

function formatContent(content = "") {
  let html = escapeHtml(content);

  html = html.replace(/\r\n/g, "\n");
  html = html.replace(/\r/g, "\n");
  html = html.replace(/\n/g, "<br>");

  return html;
}

function resolvePublicAssetUrl(value, baseUrl) {
  const assetUrl = typeof value === "string" ? value.trim() : "";

  if (isValidUrl(assetUrl)) {
    return assetUrl;
  }

  if (!assetUrl.startsWith("/") || !isValidUrl(baseUrl)) {
    return "";
  }

  try {
    return new URL(assetUrl, baseUrl).toString();
  } catch (_) {
    return "";
  }
}

// ============================================================
// PERSONALIZE LEAD PLACEHOLDERS
// ============================================================

function replaceLeadPlaceholders(value = "", lead = {}) {
  const firstName = String(lead.firstName || "").trim();
  const lastName = String(lead.lastName || "").trim();
  const fullName = [firstName, lastName].filter(Boolean).join(" ");

  const replacements = {
    firstName: firstName || "there",
    lastName,
    fullName: fullName || "there",
    email: String(lead.email || "").trim(),
    company: String(lead.company || "").trim(),
    businessType: String(lead.businessType || "").trim(),
  };

  return String(value).replace(
    /{{\s*(firstName|lastName|fullName|email|company|businessType)\s*}}/gi,
    (_, key) => {
      const normalizedKey = Object.keys(replacements).find(
        (item) => item.toLowerCase() === key.toLowerCase(),
      );

      return normalizedKey ? replacements[normalizedKey] : "";
    },
  );
}

// ============================================================
// MAIN
// ============================================================

function buildSequenceEmail({
  sequence = {},
  lead = {},
  trackingUrl = null,
  baseUrl = null,
}) {
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

  const subject = escapeHtml(
    replaceLeadPlaceholders(sequence.subject || "", lead),
  );

  // ==========================================================
  // CONTENT
  // ==========================================================

  const content = formatContent(
    replaceLeadPlaceholders(sequence.content || "", lead),
  );

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
  // LOGO
  // ==========================================================

  let logoHtml = "";

  const logoUrl = resolvePublicAssetUrl(brand.logoUrl, baseUrl);

  const logoPosition = getLogoAlignment(brand.logoPosition || "Center");

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
  // HERO
  // ==========================================================

  let heroHtml = "";

  const heroUrl = resolvePublicAssetUrl(heroImage.url, baseUrl);

  const heroLink =
    typeof heroImage.link === "string" ? heroImage.link.trim() : "";

  if (isValidUrl(heroUrl)) {
    const imageHtml = `
      <img
        src="${escapeHtml(heroUrl)}"
        alt=""
        referrerpolicy="no-referrer"
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
  // WHATSAPP
  // ==========================================================

  let whatsappHtml = "";

  const whatsapp =
    actionLinks.whatsapp && typeof actionLinks.whatsapp === "object"
      ? actionLinks.whatsapp
      : {};

  const whatsappUrl =
    typeof whatsapp.url === "string" ? whatsapp.url.trim() : "";

  if (whatsapp.enabled === true && isValidUrl(whatsappUrl)) {
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
  // DOCUMENT
  // ==========================================================

  let attachmentHtml = "";

  const attachmentUrl = resolvePublicAssetUrl(attachment.url, baseUrl);

  const attachmentName =
    typeof attachment.name === "string" ? attachment.name.trim() : "";

  if (
    isValidUrl(attachmentUrl) &&
    attachmentName !== ""
  ) {
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
  // CTA
  // ==========================================================

  let ctaHtml = "";

  const cta =
    actionLinks.cta && typeof actionLinks.cta === "object"
      ? actionLinks.cta
      : {};

  const ctaText = typeof cta.text === "string" ? cta.text.trim() : "";

  const ctaUrl = typeof cta.url === "string" ? cta.url.trim() : "";

  if (cta.enabled === true && ctaText !== "" && isValidUrl(ctaUrl)) {
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
  // TRACKING
  // ==========================================================

  let trackingPixel = "";

  if (isValidUrl(trackingUrl)) {
    trackingPixel = `
      <img
        src="${escapeHtml(trackingUrl)}"
        width="1"
        height="1"
        alt=""
        referrerpolicy="no-referrer"
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
  // FINAL EMAIL
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

${logoHtml}

${heroHtml}

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

${ctaHtml}

${whatsappHtml}

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

module.exports = {
  buildSequenceEmail,
  replaceLeadPlaceholders,
};
