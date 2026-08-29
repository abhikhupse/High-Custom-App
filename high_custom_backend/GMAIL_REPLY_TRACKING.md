# Gmail recipient reply tracking

The backend now supports event-driven reply tracking through Gmail API push
notifications and Google Cloud Pub/Sub.

## Processing flow

1. A sequence email is sent and its Gmail `messageId` and `threadId` are saved.
2. Connecting Gmail registers an `INBOX` watch when `GMAIL_PUBSUB_TOPIC` is set.
3. Gmail publishes mailbox changes to the configured Pub/Sub topic.
4. Pub/Sub calls `POST /api/integrations/gmail/notifications`.
5. The backend acknowledges the webhook immediately, reads Gmail history, and
   retrieves only newly added inbox messages.
6. A message is counted as a reply only when its thread matches a sent delivery,
   its sender matches that delivery's lead, and it is not an automated response.
7. The delivery is updated atomically with reply metadata. Duplicate Pub/Sub
   notifications and Gmail message IDs do not create duplicate replies.

## Google Cloud setup

1. Create a Pub/Sub topic in the same Google Cloud project as the Gmail OAuth
   client.
2. Grant `gmail-api-push@system.gserviceaccount.com` permission to publish to
   that topic.
3. Create a push subscription pointing to:

   `https://YOUR_BACKEND/api/integrations/gmail/notifications?token=YOUR_SECRET`

4. Copy the variables from `.env.reply.example` into the deployment environment.
5. Redeploy or restart the backend.
6. Reconnect Gmail, or call the authenticated endpoint below once to register
   the watch for an already connected account:

   `POST /api/integrations/gmail/reply-watch`

For production, use an authenticated Pub/Sub push subscription and configure
`GMAIL_PUBSUB_OIDC_AUDIENCE`. The shared verification token can remain enabled
as a second check.

## Reliability behavior

- Gmail watches are renewed daily and whenever the backend starts if they are
  missing or expire within 24 hours.
- MongoDB and in-process locks prevent overlapping mailbox synchronization.
- Out-of-order Pub/Sub notifications are ignored safely.
- If a Gmail history cursor expires, the backend recovers by checking recent
  inbox messages from the previous 30 days.
- Reply processing stores metadata and a short Gmail snippet, not the full body.

## Local verification

The Pub/Sub webhook requires a valid verification token or OIDC token. A sample
push body contains Base64URL-encoded JSON with `emailAddress` and `historyId` in
`message.data`. A real end-to-end test also requires a public HTTPS endpoint,
the configured Pub/Sub subscription, and two Gmail accounts.
