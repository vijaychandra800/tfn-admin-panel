# Design — profile foundation (backend and admin surface)

## Context

Phase 1 of the Profiles + Follow milestone. The goal is to get the user record's shape and
its write protection right *before* anything depends on it, because every later phase
(follow graph, posts, messaging) denormalizes from it.

Sibling change: `add-profile-foundation` in `../tfn-app`, which owns the mobile `UserModel`,
`UserRef`, and the edit-profile UI.

## Decisions

### Extend `users/{uid}`; do not add a profile collection

Profiles live on the existing `users/{uid}` document rather than a parallel `profiles/`
collection. The `users` collection is already world-readable and already carries the
denormalized identity the app reads. A separate collection would require a mirror-sync
Cloud Function and a second read on every profile view, for no gain at this scale.

The cost is that `users/{uid}` also holds `email`, `fcmToken`, and `muted_until`, which are
world-readable today. That is a real privacy gap, consciously deferred to Phase 8 rather
than solved here — splitting the document now would churn every existing read path in both
repos and block Phase 1 behind a migration.

### Field shape

```jsonc
// users/{uid} — additive; existing documents remain valid
{
  "username":           "vijay",      // display form
  "username_lower":     "vijay",      // case-insensitive lookup + future @mention prefix search
  "bio":                "Track & field fan",
  "cover_url":          "https://…",
  "links":              { "website": "…", "instagram": "…" },
  "is_private":         false,        // stored, not yet read — reserved for private accounts
  "followers_count":    0,            // server-owned
  "following_count":    0,            // server-owned
  "posts_count":        0,            // server-owned
  "profile_updated_at": "<timestamp>",
  "mentions":           []            // reserved for Phase 7
}
```

`username_lower` is stored rather than computed at query time because Firestore has no
case-insensitive operator and no expression indexes; prefix search in Phase 7 needs a
literal field to range over.

### Server-owned versus client-writable

| Field | Writer |
| --- | --- |
| `username`, `username_lower`, `bio`, `cover_url`, `links`, `profile_updated_at`, `mentions` | Owner |
| `followers_count`, `following_count`, `posts_count` | Cloud Functions / Admin SDK only |
| `role`, `disabled` | Admin only |
| `is_private` | Owner (stored, unread) |

Enforced with a deny-list on the diff rather than an allow-list:

```
allow update: if isUserSignedIn()
  && ( (request.auth.uid == resource.id
        && !request.resource.data.diff(resource.data).affectedKeys()
              .hasAny(['followers_count','following_count','posts_count','role','disabled']))
     || isAdmin() );
```

A deny-list is chosen deliberately: an allow-list would reject every field the app already
writes today (`subscription`, `fcmToken`, and others) and turn a Phase 1 schema change into
an audit of every existing user write. The deny-list closes the escalation paths that
matter now and leaves the broader audit to the security pass.

**Risk:** `AuthService.createAuthor` writes a user document through a secondary Firebase app
while an admin is signed in. Under the new rule that write is evaluated as the *new* user,
not the admin. This must be verified on dev before the rule ships — it is the most likely
way this change breaks something that currently works.

### Storage layout

`user_covers/{uid}/{fileName}` — world-readable, owner-writable, images only, size-capped.
Keying by uid lets the rule authorize from the path alone with no Firestore lookup, which
matters because every `get()` inside a rule is a billed read.

### Indexes

**None.** Phase 1 adds no new query — profiles are fetched by document id, and the admin
user list reuses its existing ordering. Handle lookup (`username_lower`) and the follow
graph queries arrive in Phases 2 and 3 with their own indexes.

### Backfill

A one-off Node script using the Admin SDK, not a Cloud Function: it runs once, needs no
trigger, and should not be deployable by accident.

- Pages `users` in batches of 450 (Firestore's 500-write batch limit, with headroom).
- Sets the three counters to `0` **only when absent**, so a re-run cannot reset live counts
  once Phase 3 starts incrementing them.
- Derives a handle by slugifying the display name to `^[a-z0-9_]{3,20}$`, padding short
  results and truncating long ones.
- Logs collisions instead of resolving them. Uniqueness is Phase 2's job, and silently
  renaming a user's handle here would be a worse outcome than a reported duplicate.
- Idempotent: a record that already has counters and a handle is skipped.

Run against `track-network-dev` only.

## Risks

| Risk | Mitigation |
| --- | --- |
| Rules hardening breaks `createAuthor` | Verify the author-creation flow on dev before deploying rules; it writes a user doc as a secondary app |
| Rules hardening breaks an existing app write | Audit the sibling change's write paths for the five denied fields before the rules deploy |
| Handle collisions from the backfill | Reported, not auto-resolved; Phase 2's registry is the real fix |
| Counters reset by a re-run | Script writes counters only when the field is absent |

## Open questions

- Reserved-handle list (`admin`, `support`, …) — needed in Phase 2 with the registry, not here.
- Whether the backfill should run against prod at all, or whether prod users get handles
  lazily on first profile edit. Deferred until dev results are in.
