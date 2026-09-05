const test = require("node:test");
const assert = require("node:assert/strict");
const { buildSequenceEmail, replaceLeadPlaceholders } = require("../templates/sequenceEmail.template");
const { buildSequenceText, createMimeMessage } = require("../utils/emailMessage");
const { permanentFailures } = require("../utils/deliveryStatus");
const { buildSequenceBodies } = require("../utils/emailMessage");

test("default sequence format keeps response buttons without promotional extras or tracking", async () => {
  const previous = process.env.EMAIL_SEQUENCE_FORMAT;
  delete process.env.EMAIL_SEQUENCE_FORMAT;
  try {
    const options = {
      sequence: { content: "Hi {{firstName}},\nCan we talk?", tracking: { enabled: false }, brand: { logoUrl: "https://example.com/logo" },
        actionLinks: { cta: { enabled: true, text: "Buy", url: "https://example.com/buy" } },
        attachment: { name: "Brochure", url: "/brochure.pdf" } },
      lead: { firstName: "Ana" }, baseUrl: "https://example.com",
      trackingUrl: "https://example.com/pixel", interestedUrl: "https://example.com/interested",
      notInterestedUrl: "https://example.com/unsubscribe",
    };
    for (const provider of ["gmail", "zoho"]) {
      const bodies = buildSequenceBodies(options, provider);
      assert.match(bodies.html, />Interested<\/a>/);
      assert.match(bodies.html, />Unsubscribe<\/a>/);
      assert.doesNotMatch(bodies.html, /example.com\/logo|example.com\/buy|brochure.pdf|example.com\/pixel/);
      assert.equal(bodies.text, "Hi Ana,\nCan we talk?\n\nUnsubscribe: https://example.com/unsubscribe");
      const raw = await createMimeMessage({ from: "sender@example.com", to: "ana@example.com", subject: "Hello", ...bodies });
      const mime = Buffer.from(raw, "base64url").toString();
      assert.match(mime, /Content-Type: text\/plain/);
      assert.match(mime, /multipart\/alternative/);
      assert.match(mime, /Content-Type: text\/html/);
      assert.doesNotMatch(mime, /example.com\/buy|brochure.pdf|example.com\/pixel/);
    }
    process.env.EMAIL_SEQUENCE_FORMAT = "html";
    assert.match(buildSequenceBodies(options).html, /example.com\/logo/);
  } finally {
    if (previous === undefined) delete process.env.EMAIL_SEQUENCE_FORMAT;
    else process.env.EMAIL_SEQUENCE_FORMAT = previous;
  }
});

test("personal HTML includes a unique open pixel when sequence tracking is enabled", () => {
  const previous = process.env.EMAIL_OPEN_TRACKING_ENABLED;
  delete process.env.EMAIL_OPEN_TRACKING_ENABLED;
  try {
    const enabled = buildSequenceBodies({
      sequence: { content: "Hello", tracking: { enabled: true } }, lead: {},
      trackingUrl: "https://example.com/open/unique?v=123",
    });
    assert.match(enabled.html, /src="https:\/\/example.com\/open\/unique\?v=123"/);
    const disabled = buildSequenceBodies({
      sequence: { content: "Hello", tracking: { enabled: false } }, lead: {},
      trackingUrl: "https://example.com/open/unique?v=123",
    });
    assert.doesNotMatch(disabled.html, /open\/unique/);
  } finally {
    if (previous === undefined) delete process.env.EMAIL_OPEN_TRACKING_ENABLED;
    else process.env.EMAIL_OPEN_TRACKING_ENABLED = previous;
  }
});

test("DSN parser suppresses invalid recipients but not policy blocks, full mailboxes, or text claims", () => {
  const part = (status, action = "failed") => ({ mimeType: "message/delivery-status", body: {
    data: Buffer.from(`Final-Recipient: rfc822; lead@example.com\r\nAction: ${action}\r\nStatus: ${status}\r\n`).toString("base64url"),
  }});
  assert.deepEqual(permanentFailures({ parts: [part("5.1.1")] }), ["lead@example.com"]);
  for (const status of ["4.1.1", "5.7.1", "5.2.2"]) assert.deepEqual(permanentFailures(part(status)), []);
  assert.deepEqual(permanentFailures(part("5.1.1", "delayed")), []);
  assert.deepEqual(permanentFailures({ ...part("5.1.1"), mimeType: "text/plain" }), []);
});

test("placeholder names never become a greeting", () => {
  for (const firstName of ["-", " — ", "N/A", "unknown", "", "  "]) {
    assert.equal(replaceLeadPlaceholders("Hi {{firstName}},", { firstName }), "Hi there,");
  }
  assert.equal(replaceLeadPlaceholders("Hi {{fullName}},", { firstName: "Ana", lastName: "-" }), "Hi Ana,");
});

test("multipart message has encoded text and HTML, safe subject, and no list headers", async () => {
  const raw = await createMimeMessage({
    from: "sender@example.com", to: "lead@example.com",
    subject: "Hello é\r\nBcc: victim@example.com",
    text: "Hi Ana,\nA plain text message.", html: "<p>Hi Ana,</p>",
  });
  const mime = Buffer.from(raw, "base64url").toString();
  assert.match(mime, /multipart\/alternative/);
  assert.match(mime, /Content-Type: text\/plain/);
  assert.match(mime, /Content-Type: text\/html/);
  assert.doesNotMatch(mime, /List-Unsubscribe(?:-Post)?:/i);
  assert.match(mime, /Reply-To: sender@example.com/);
  assert.doesNotMatch(mime, /^Bcc:/m);
});

test("tracking-free HTML still includes unsubscribe and text preserves document links", () => {
  const oldPixel = process.env.EMAIL_OPEN_TRACKING_ENABLED;
  const oldButtons = process.env.EMAIL_RESPONSE_BUTTONS_ENABLED;
  process.env.EMAIL_OPEN_TRACKING_ENABLED = "false";
  process.env.EMAIL_RESPONSE_BUTTONS_ENABLED = "false";
  try {
    const options = {
      sequence: { content: "Hi {{firstName}},", attachment: { url: "/file.pdf", name: "Brochure" } },
      lead: { firstName: "-" }, baseUrl: "https://example.com",
      trackingUrl: "https://example.com/pixel", interestedUrl: "https://example.com/yes",
      notInterestedUrl: "https://example.com/unsubscribe",
    };
    const html = buildSequenceEmail(options);
    assert.doesNotMatch(html, /example.com\/pixel|example.com\/yes/);
    assert.match(html, />Unsubscribe<\/a>/);
    assert.match(html, /Hi there,/);
    const text = buildSequenceText(options);
    assert.match(text, /Brochure: https:\/\/example.com\/file.pdf/);
    assert.match(text, /Unsubscribe: https:\/\/example.com\/unsubscribe/);
  } finally {
    for (const [key, value] of [["EMAIL_OPEN_TRACKING_ENABLED", oldPixel], ["EMAIL_RESPONSE_BUTTONS_ENABLED", oldButtons]]) {
      if (value === undefined) delete process.env[key]; else process.env[key] = value;
    }
  }
});
