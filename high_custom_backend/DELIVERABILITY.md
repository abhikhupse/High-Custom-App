# Local email sending safeguards

## Registration OTP on Render

Render uses the Gmail HTTPS API automatically (`RENDER` environment variable).
Other environments keep SMTP by default. Set `OTP_EMAIL_TRANSPORT=gmail_api`
explicitly to select the HTTPS transport, or `smtp` only on hosts that permit SMTP.
`OTP_EMAIL_USER` is the dedicated application OTP sender (`EMAIL_USER` remains a
legacy fallback) and must have a connected Gmail
integration using the same Google OAuth client as the deployment. An expired/revoked
connection must be reauthorized in Integrations. Never choose an arbitrary user's mailbox.

The OTP send has a 12-second deadline. A mail failure returns a clear 503 response;
an unverified registration can retry with matching email, phone, employer code, and
password without creating another account or replacing another account's credentials.
Deploy the backend changes and rebuild the frontend to use the improved timeout messages.

Sequence emails default to minimal personal HTML plus a plain-text alternative. This keeps
the authored message and the Interested/Unsubscribe buttons without automatically adding
logos, hero images, CTA, WhatsApp, document links, or open pixels. Links written in the body
are preserved. Existing editor designs remain saved; they are used only in full HTML mode.
Gmail uses Nodemailer's MIME composer and includes both plain text and HTML in HTML mode.
This format does not guarantee Gmail Primary placement; recipient classification still applies.
Sequence emails do not add List-Unsubscribe headers, so Gmail does not render its
header-level unsubscribe control. The visible Unsubscribe button and footer remain.
If the sender reaches bulk-marketing thresholds, restore standards-compliant one-click
unsubscribe headers because mailbox providers can require them.

Defaults (environment overrides require restarting the worker/server):

| Variable | Default | Purpose |
| --- | --- | --- |
| EMAIL_SEQUENCE_FORMAT | personal_html | Use plain for text only or html for the rich template |
| EMAILS_PER_USER_WINDOW | 1 | Attempts allowed per short window |
| EMAIL_USER_WINDOW_MS | 60000 | Short window duration |
| EMAILS_PER_USER_DAY | 50 | Attempts per 24-hour window per app user |
| EMAIL_OPEN_TRACKING_ENABLED | false | Set true to embed the open pixel |
| EMAIL_RESPONSE_BUTTONS_ENABLED | true | Set false to hide Interested/Unsubscribe buttons |
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
