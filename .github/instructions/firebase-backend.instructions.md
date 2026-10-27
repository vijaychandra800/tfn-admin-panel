---
applyTo: "firestore.rules,firestore.indexes.json,storage.rules"
---

# Firestore rules, indexes, and Storage rules

This repo owns the backend contract shared with `../tfn-app`. Changes here can break the
mobile app at runtime with no compile-time signal.

## Deploy

Always dev first, always with an explicit project:

```bash
firebase deploy --only firestore:rules   --project=track-network-dev
firebase deploy --only firestore:indexes --project=track-network-dev
```

Prod (`the-track-and-field-network`) only on explicit request.

## Rules conventions

Reuse the existing helpers at the bottom of `firestore.rules` rather than inlining checks:

- `isUserSignedIn()`
- `isAdmin()` / `isAuthor()`
- `isMuted()` — reads the user doc; `true` when `'muted_until' in userDoc && userDoc.muted_until > request.time`
- `chatReadOnlyHours()` / `eventChatWritable(commentData)` — Fanzone chat lifespan gate

Patterns to follow:

- Content collections are world-readable (`allow read: if true`) and admin/author-writable.
- Ownership is encoded in the document id where possible (e.g. `follows/{followerId}_{followeeId}`),
  so a single rule can authorize without an extra `get()`.
- **Block client writes to server-owned fields.** Denormalized counters, `role`, and
  `disabled` must be rejected on `update` via
  `!request.resource.data.diff(resource.data).affectedKeys().hasAny([...])`.
  Cloud Functions use the Admin SDK and bypass rules, so they still write fine.
- Prefer deleting a field with `FieldValue.delete()` over setting it to `null`, so
  `where(field, isNull: false)` queries stay clean (this is why unmute deletes `muted_until`).
- Every `get()` / `exists()` inside a rule is a billed read and counts against the rule
  evaluation limit — keep lookups to one per request path.

## Index conventions

- Add composite indexes to `firestore.indexes.json` **in the same change** as the query
  that needs them. A missing index is a runtime failure in the app.
- When mirroring a renamed field (the `target_*` / `article_*` comment pattern), keep the
  legacy indexes so existing queries keep working without a backfill.
- Field order in a composite index must match the query's equality-then-range/order shape.

## Checklist before finishing

1. Named the matching mobile-app read path in `../tfn-app/lib/services/firebase_service.dart`?
2. Added or confirmed the composite index for every new query?
3. Confirmed no client-writable path can forge a server-owned field?
4. Deployed to `track-network-dev` and verified there?
