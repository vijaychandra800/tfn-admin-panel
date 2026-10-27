# Profile foundation — backend and admin surface

> Phase 1 of the Profiles + Follow milestone in
> [docs/SOCIAL_FEATURES_PLAN.md](../../../docs/SOCIAL_FEATURES_PLAN.md).
> Sibling change: `add-profile-foundation` in `../tfn-app/openspec/changes/`, which owns
> the mobile models and the edit-profile UI. Neither change is shippable alone.

## Why

A Track Field Network user is currently little more than a name and an avatar copied onto
each comment. The social milestone — follow graph, user posts, messaging — all hangs off a
durable user profile: a stable handle, a bio, cover media, and counters that only the server
may write. Phase 1 establishes that schema and its server-side protection first, so every
later phase is purely additive and needs no backfill.

## What Changes

**Firestore schema** — extend `users/{uid}` with additive, nullable/defaulted fields:
`username`, `username_lower`, `bio`, `cover_url`, `links`, `is_private`, `followers_count`,
`following_count`, `posts_count`, `profile_updated_at`. Every existing document keeps
parsing untouched.

**Security rules** — **BREAKING** for any client that writes its own user document. The
current `users` update rule lets an owner write *any* field on their own doc, which means a
user can self-grant `role: admin`, clear `disabled`, or forge `followers_count`. This change
restricts owner updates to a non-privileged field set; `role`, `disabled`, and all counters
become admin/Cloud-Function only. This closes a live security gap already recorded against
the project, and it must be verified against `AuthService.createAuthor`, which writes a user
document through a secondary Firebase app.

**Storage** — new `user_covers/{uid}/` path plus a `storage.rules` block: world-readable,
owner-writable, with a size and content-type limit.

**Backfill** — a one-time script run against `track-network-dev` that initializes the three
counters to `0` and derives a starting handle for every existing user. Handles are written
to the user document only; global uniqueness arrives with the `usernames/` registry in
Phase 2, so this change must not claim handles are unique yet.

**Admin UI** — the Users tab surfaces `username` and the follower/following counts as
read-only columns, so an admin can see profile state before the moderation actions arrive in
Phase 6.

**Reserved, not implemented** — `mentions: []` is written as an empty array in profile write
paths so Phase 7 can add mentions without a migration, following the same strategy as the
existing `target_*` / `article_*` comment mirroring.

## Capabilities

### New Capabilities

- `user-profile` — the durable contract for what a user profile *is*: its stored fields,
  which of them are server-owned, where profile media lives, and who may write each.

### Modified Capabilities

None. `openspec/specs/` has no existing capabilities; this is the first.

## Impact

| Area | Files |
| --- | --- |
| Rules | [firestore.rules](../../../firestore.rules), [storage.rules](../../../storage.rules) |
| Models | [lib/models/user_model.dart](../../../lib/models/user_model.dart), new `lib/models/user_ref.dart` |
| Admin UI | [lib/tabs/admin_tabs/users/users.dart](../../../lib/tabs/admin_tabs/users/users.dart) |
| Backfill | new one-off script under `functions/scripts/` |

**Cross-repo impact:** the `users` document shape is a shared contract. `../tfn-app` must
land the matching `UserModel` fields in its sibling change, or the app will simply not read
the new fields — it will not crash, because all fields are nullable. The rules hardening is
the real coupling risk: if the app writes a now-forbidden field on the user document, that
write starts failing. The sibling change must be checked for this before the rules deploy.

**Deployment:** rules and storage rules deploy to `track-network-dev` only. No Cloud
Functions change in this phase — counters are initialized by the backfill and not yet
incremented by anything, since the follow graph arrives in Phase 3.

## Out of scope

- The `usernames/` uniqueness registry and the reservation transaction (Phase 2).
- The follow graph, counter-maintaining Cloud Functions, and follow notifications
  (Phases 3–5).
- Private accounts: `is_private` is stored but nothing reads it yet.
- Moving `email` / `fcmToken` / `muted_until` behind a private sub-document (Phase 8).
