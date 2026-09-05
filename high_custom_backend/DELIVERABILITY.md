# Local email sending safeguards

Sequence emails default to plain text for both Gmail and Zoho. This keeps the authored
message and unsubscribe link, without automatically adding logos, hero images, CTA,
WhatsApp, document links, response buttons, or open pixels. Links written in the body
are preserved. Existing editor designs remain saved; they are used only in HTML mode.
Gmail uses Nodemailer's MIME composer and includes both plain text and HTML in HTML mode.
This format does not guarantee Gmail Primary placement; recipient classification still applies.
HTTPS unsubscribe URLs also receive RFC 8058 headers. Verify the received message:
the provider must DKIM-sign the unsubscribe headers for full one-click compliance.
The visible unsubscribe link remains available when pixels/buttons are disabled.

Defaults (environment overrides require restarting the worker/server):

| Variable | Default | Purpose |
| --- | --- | --- |
| EMAIL_SEQUENCE_FORMAT | plain | Set html to restore the rich template |
| EMAILS_PER_USER_WINDOW | 1 | Attempts allowed per short window |
| EMAIL_USER_WINDOW_MS | 60000 | Short window duration |
| EMAILS_PER_USER_DAY | 50 | Attempts per 24-hour window per app user |
| EMAIL_OPEN_TRACKING_ENABLED | false | Set true to embed the open pixel |
| EMAIL_RESPONSE_BUTTONS_ENABLED | false | Set true to show response buttons |
| EMAIL_ZOHO_PLAIN_TEXT | false | Set true to send plain text through Zoho |

The daily limit starts with the first reserved attempt; retries consume permits.
This is a conservative cap, not automatic account warm-up or a guaranteed safe volume.
Limits are per app user, not aggregated across users sharing a sender/domain.

Zoho's current JSON send endpoint documents one body format (HTML or plaintext),
not multipart alternatives or custom List-Unsubscribe headers. Both formats include
a visible unsubscribe link; full MIME/header parity requires another supported transport.

Replies suppress further sequence sends for that lead. Permanent failed deliveries
are not automatically requeued. Existing failures without retryability are held for review.
Unsubscribes persist by user/email so deleting and reimporting a lead does not opt it back in.
Gmail suppresses machine-readable permanent invalid-address DSNs only when they match
an outgoing thread and recipient. Separate/unmatched DSN threads, attachment-only DSNs,
Zoho bounce ingestion, and complaint feedback still require provider-specific integration.
Provider acceptance means sent, not delivered to the recipient's inbox.

DNS authentication, reputation, consent/list quality, and production environment settings
still need operational verification. No live messages are sent by the local test suite.
