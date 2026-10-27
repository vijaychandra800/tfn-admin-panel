---
applyTo: "functions/**"
---

# Cloud Functions (functions/index.js)

2nd-gen Firebase Functions on **Node 22**, CommonJS (`require`, `exports.x = ...`).
Single file: `functions/index.js`. ESLint uses `eslint-config-google` — run
`cd functions && npm run lint` before finishing.

## Existing building blocks — reuse, don't re-implement

| Helper                                            | Use for                                                                      |
| ------------------------------------------------- | ---------------------------------------------------------------------------- |
| `sendCommentNotification(ownerId, title, body, data)` | Token lookup from `users/{uid}.fcmToken`, send, and prune stale tokens        |
| `buildCommentTargetData(commentData)`             | Building the all-string routing payload for a comment push                   |
| `deleteEventComments(eventId)`                    | Batched comment deletion                                                     |
| `htmlToPlainText(html)`                           | Notification body from rich article content                                  |
| Collection-name consts (`commentsCollection`, …)  | Never hardcode a collection string                                           |

When a new notification type is needed, **generalize** `sendCommentNotification` into a
shared `sendUserNotification(uid, title, body, data)` rather than copying the token-lookup
and pruning logic. Stale-token pruning keys off the
`messaging/registration-token-not-registered` and `invalid-registration-token` error codes.

## Trigger conventions

- Scheduled: `onSchedule("every N minutes")` from `firebase-functions/v2/scheduler`.
- Firestore: `onDocumentCreated` / `onDocumentUpdated` from `firebase-functions/v2/firestore`.
- **Guard early and return.** Every trigger starts with cheap filters — wrong
  `target_type`, missing field, self-action (`ownerId === actorId`) — before any read.
- **Diff, don't assume.** On `onDocumentUpdated`, compare before/after to find only the
  newly-added entries (the reactions pattern). Removals must not notify.
- FCM payload `data` values must **all be strings**. Routing keys are consumed by
  `../tfn-app/lib/models/notification_model.dart`.

## Counters

Denormalized counters (`followers_count`, `like_count`, `posts_count`, …) are written
**only** here, via `FieldValue.increment()` in a batch, and floored at 0 on decrement.
`firestore.rules` must reject client writes to those fields.

## Deploy

```bash
firebase deploy --only functions --project=track-network-dev
```

The **first** Firestore/Eventarc 2nd-gen trigger deployed to a project can fail with an
Eventarc Service Agent permission-propagation error. This is expected — wait a few minutes
and retry the same command. Do not restructure the function in response to it.

Prod (`the-track-and-field-network`) only on explicit request.

## Security

- Never log an auth response body, an FCM token, or a raw API response that may contain
  credentials. If an error must reference a response, log only the **keys**.
- Functions run with the Admin SDK and bypass security rules — validate inputs explicitly.
