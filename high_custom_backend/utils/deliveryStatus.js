// Only machine-readable permanent DSN failures qualify; never infer bounces
// from a subject, free text, or an out-of-office response.
function permanentFailures(payload) {
  const recipients = new Set();
  function visit(part) {
    if (part?.mimeType?.toLowerCase() === "message/delivery-status" && part.body?.data) {
      const text = Buffer.from(part.body.data, "base64url").toString("utf8").replace(/\r\n/g, "\n").replace(/\n[ \t]+/g, " ");
      for (const block of text.split(/\n\s*\n/)) {
        // Authentication/policy blocks and full mailboxes are not evidence of
        // an invalid recipient. Only permanent address/disabled-mailbox codes.
        if (!/^Action:\s*failed\s*$/im.test(block) || !/^Status:\s*5\.(?:1\.[1236]|2\.1)\s*$/im.test(block)) continue;
        const match = block.match(/^Final-Recipient:\s*rfc822;\s*([^\s<>]+@[^\s<>]+)\s*$/im);
        if (match) recipients.add(match[1].toLowerCase());
      }
    }
    for (const child of part?.parts || []) visit(child);
  }
  visit(payload);
  return [...recipients];
}
module.exports = { permanentFailures };
