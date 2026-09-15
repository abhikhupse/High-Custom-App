const MailComposer = require("nodemailer/lib/mail-composer");
const {
  replaceLeadPlaceholders,
  resolvePublicAssetUrl,
  buildSequenceEmail,
} = require("../templates/sequenceEmail.template");

function buildSequenceText({
  sequence = {},
  lead = {},
  notInterestedUrl,
  baseUrl,
  actionLinkTrackingBaseUrl,
  includeExtras = true,
}) {
  const parts = [replaceLeadPlaceholders(sequence.content || "", lead)];
  if (includeExtras) {
    for (const item of [
      sequence.actionLinks?.cta,
      sequence.actionLinks?.whatsapp,
    ]) {
      if (item?.enabled && /^https?:\/\//i.test(item.url || "")) {
        const type =
          item === sequence.actionLinks?.whatsapp ? "whatsapp" : "website";
        const destination = actionLinkTrackingBaseUrl
          ? `${actionLinkTrackingBaseUrl}/${encodeURIComponent(type)}`
          : item.url;
        parts.push(`${item.text || "WhatsApp"}: ${destination}`);
      }
    }
    const attachment = resolvePublicAssetUrl(sequence.attachment?.url, baseUrl);
    if (attachment)
      parts.push(`${sequence.attachment?.name || "Document"}: ${attachment}`);
  }
  if (notInterestedUrl) parts.push(`Unsubscribe: ${notInterestedUrl}`);
  return parts.join("\n\n");
}

function escapeHtml(value = "") {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function buildPersonalSequenceHtml({
  sequence = {},
  lead = {},
  trackingUrl,
  interestedUrl,
  notInterestedUrl,
}) {
  const content = escapeHtml(
    replaceLeadPlaceholders(sequence.content || "", lead),
  ).replace(/\r\n|\r|\n/g, "<br>");
  const validInterested = /^https?:\/\//i.test(interestedUrl || "");
  const validUnsubscribe = /^https?:\/\//i.test(notInterestedUrl || "");
  const showTrackingPixel =
    process.env.EMAIL_OPEN_TRACKING_ENABLED !== "false" &&
    sequence.tracking?.enabled !== false &&
    /^https?:\/\//i.test(trackingUrl || "");
  const showButtons =
    process.env.EMAIL_RESPONSE_BUTTONS_ENABLED !== "false" &&
    validInterested &&
    validUnsubscribe;
  const buttons = showButtons
    ? `
    <p style="margin:24px 0 16px">
      <a href="${escapeHtml(interestedUrl)}" style="display:inline-block;margin:0 8px 8px 0;padding:10px 16px;border-radius:6px;background:#157347;color:#fff;text-decoration:none">Interested</a>
      <a href="${escapeHtml(notInterestedUrl)}" style="display:inline-block;padding:10px 16px;border-radius:6px;background:#667085;color:#fff;text-decoration:none">Unsubscribe</a>
    </p>`
    : "";
  const unsubscribe = validUnsubscribe
    ? `<p style="margin:24px 0 0;font-size:12px;color:#667085"><a href="${escapeHtml(notInterestedUrl)}" style="color:#667085">Unsubscribe</a> from future emails.</p>`
    : "";
  const trackingPixel = showTrackingPixel
    ? `<img src="${escapeHtml(trackingUrl)}" width="1" height="1" alt="" style="display:block;width:1px;height:1px;border:0;margin:0;padding:0">`
    : "";
  return `<!doctype html><html><body style="margin:0;padding:24px;background:#fff;color:#111;font:16px/1.6 Arial,sans-serif"><div style="max-width:620px">${content}${buttons}${unsubscribe}</div>${trackingPixel}</body></html>`;
}

async function createMimeMessage({ from, to, subject, html, text }) {
  const message = await new MailComposer({
    from,
    to,
    replyTo: from,
    subject: String(subject || "").replace(/[\r\n]+/g, " "),
    text,
    html,
  })
    .compile()
    .build();
  return message.toString("base64url");
}

function buildSequenceBodies(options, provider = "gmail") {
  const format =
    provider === "zoho" && process.env.EMAIL_ZOHO_PLAIN_TEXT === "true"
      ? "plain"
      : process.env.EMAIL_SEQUENCE_FORMAT || "personal_html";
  // Sequences created from saved Business Link settings have an enabled brand
  // logo. They must use the rich template so the saved logo and CTA links are
  // preserved in the actual email—not only in the editor preview.
  const rich =
    format === "html" ||
    (format === "personal_html" && options.sequence?.brand?.enabled === true);
  const html = rich
    ? buildSequenceEmail(options)
    : format === "plain"
      ? undefined
      : buildPersonalSequenceHtml(options);
  return {
    text: buildSequenceText({ ...options, includeExtras: rich }),
    html,
  };
}

module.exports = {
  buildSequenceText,
  createMimeMessage,
  buildSequenceBodies,
  buildPersonalSequenceHtml,
};
