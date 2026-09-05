const MailComposer = require("nodemailer/lib/mail-composer");
const { replaceLeadPlaceholders, resolvePublicAssetUrl } = require("../templates/sequenceEmail.template");

function buildSequenceText({ sequence = {}, lead = {}, notInterestedUrl, baseUrl }) {
  const parts = [replaceLeadPlaceholders(sequence.content || "", lead)];
  for (const item of [sequence.actionLinks?.cta, sequence.actionLinks?.whatsapp]) {
    if (item?.enabled && /^https?:\/\//i.test(item.url || "")) {
      parts.push(`${item.text || "WhatsApp"}: ${item.url}`);
    }
  }
  const attachment = resolvePublicAssetUrl(sequence.attachment?.url, baseUrl);
  if (attachment) parts.push(`${sequence.attachment?.name || "Document"}: ${attachment}`);
  if (notInterestedUrl) parts.push(`Unsubscribe: ${notInterestedUrl}`);
  return parts.join("\n\n");
}

async function createMimeMessage({ from, to, subject, html, text, unsubscribeUrl }) {
  const message = await new MailComposer({
    from, to, replyTo: from,
    subject: String(subject || "").replace(/[\r\n]+/g, " "),
    text, html,
    ...(unsubscribeUrl?.startsWith("https://") ? { headers: {
      "List-Unsubscribe": `<${unsubscribeUrl}>`,
      "List-Unsubscribe-Post": "List-Unsubscribe=One-Click",
    }} : {}),
  }).compile().build();
  return message.toString("base64url");
}

module.exports = { buildSequenceText, createMimeMessage };
