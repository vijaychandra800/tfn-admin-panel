# Track Field Network — Social Features Plan

> **Purpose of this file.** This is the canonical, cross-project implementation plan for the
> social layer of Track Field Network: **(1) Profiles + Follow**, **(2) User-generated Posts
> with image/video**, **(3) Messaging MVP**. It is written so that a fresh chat can be handed
> the three context files — [../../tfn-app/docs/CONTEXT_ANDROID_APP.md](../../tfn-app/docs/CONTEXT_ANDROID_APP.md),
> [CONTEXT_ADMIN_PANEL.md](CONTEXT_ADMIN_PANEL.md), and **this file** —
> and immediately implement any named phase without re-discovering the design.
>
> **How to use in a new chat:** attach the two context files + this plan, then say e.g.
> _"Implement Phase 3 (Follow graph) from SOCIAL_FEATURES_PLAN.md on dev."_
>
> **Status legend:** ☐ not started · ◐ in progress · ☑ done. Update the checkboxes as phases land.
>
> **This plan is the roadmap, not the spec.** As each phase starts it is converted into an
> OpenSpec change — `openspec/changes/<id>/` in **both** repos, same id in each. Once a phase
> has a change folder, that folder wins on any detail the two disagree about, and this file
> keeps only the phase summary and its status. After a change is archived, its requirements
> live in `openspec/specs/`, which is what keeps the specs from drifting away from the code.
>
> | Phase | Change id | Status |
> | --- | --- | --- |
> | 1 | `add-profile-foundation` | specced in both repos |

---

## Scope at a glance — now vs. future

**🎯 Targeting now — Milestone: Profiles + Follow (Feature 1, Phases 1–6)**

| Phase | Scope                                                                                                                                                                  | Status |
| ----- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| 1     | Profile foundation — `UserModel` fields, `UserRef`, edit-profile (bio/cover/links), `user_covers/` storage, backfill (counters=0, auto-handles), reserve `mentions:[]` | ◐ specced: `add-profile-foundation` |
| 2     | Handle system — `usernames/` collection, reservation transaction, rules, validation                                                                                    | ☐      |
| 3     | Follow graph — `follows` collection, rules, indexes, service/providers, `FollowButton`, counter functions                                                              | ☐      |
| 4     | Profile UI — public profile screen, followers/following lists, tap-through wiring                                                                                      | ☐      |
| 5     | Follow notifications — generalized `sendUserNotification` + follow push + app routing                                                                                  | ☐      |
| 6     | Block (minimal) + admin moderation actions                                                                                                                             | ☐      |

**🔜 Deferred (designed-for, not this milestone)**

| Item                                                                     | Where captured                                       | Status |
| ------------------------------------------------------------------------ | ---------------------------------------------------- | ------ |
| Phase 7 — Mentions (`@username`)                                         | §12; `mentions:[]` placeholder reserved from Phase 1 | ☐      |
| Phase 8 — Privacy hardening (email/fcmToken/muted_until private sub-doc) | Decision #2, §9                                      | ☐      |
| Private accounts + follow requests                                       | Decision #1, §9                                      | ☐      |
| Follow suggestions (authors, most-followed)                              | §9                                                   | ☐      |

**🗺️ Future features (outlined only — full spec when they start)**

| Feature                                        | Scope                                                                                                                                   | Status |
| ---------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| Feature 2 — User-generated Posts (image/video) | §"FEATURE 2" outline; hooks (feed from follow graph, `posts_count`, `target_type:"post"` comments, media fan-out) reserved by Feature 1 | ☐      |
| Feature 3 — Messaging MVP                      | §"FEATURE 3" outline; hooks (follow+block gating, `UserRef` participants, conversation ids, `message` push) reserved by Features 1–2    | ☐      |

---

## 0. Ground rules (inherited from the context files)

- **Dev-first, always.** Every Firestore rule, index, Cloud Function, Storage path, and Auth
  change lands on **`track-network-dev`** first and is verified there before any prod deploy.
  Prod (`the-track-and-field-network`) is only touched when the user explicitly says so.
- **Model convention.** Every model exposes `fromFirebase()/fromFirestore()` + a static
  `getMap()`. Firestore fields are `snake_case`; Dart fields are `camelCase`.
- **Denormalized user embed.** The existing pattern is `CommentUser {id, name, image_url}`
  copied onto each comment. The social layer generalizes this into a reusable `UserRef`.
- **Single service layer.** All Firestore/Storage access goes through `FirebaseService`
  (each project has its own). No repository layer.
- **State.** Riverpod, one small provider per concern.
- **Server-authoritative counters & notifications.** Counters (`followers_count`, etc.) and
  push notifications are written/sent **only** by 2nd-gen Cloud Functions in
  [../functions/index.js](../functions/index.js), reusing the existing
  `sendCommentNotification`-style token lookup + stale-token pruning helper.
- **Package namespaces stay legacy:** app = `news_app`, admin = `news_admin`.
- **First 2nd-gen trigger deploy** may fail with the Eventarc Service Agent permission
  propagation error — retry after a few minutes (already documented in the context files).

---

## 1. Resolved product decisions

These were agreed during design and are now fixed for the roadmap:

| #   | Decision                                | Choice                                                                                                                                                                     |
| --- | --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Follow model for MVP                    | **Public accounts, instant follow** (no approval). Private accounts + follow-requests are designed-for but deferred.                                                       |
| 2   | Email / sensitive-field privacy         | Harden in a dedicated pass: move `email` / `fcmToken` / `muted_until` behind an owner/admin-only private sub-doc. Tracked as **Phase 8** (does not block Phases 1–6).      |
| 3   | Handle (@username) rollout              | **Auto-generate** handles for existing users via a one-time backfill; users can change later.                                                                              |
| 4   | Future DM gating                        | Design **block** + **mutual** signals now; final DM policy (open-with-block vs mutuals-only) decided when Messaging starts. Block graph is built in Phase 6.               |
| 5   | Milestone scope for "Profiles + Follow" | **Phases 1–6.** Private accounts, suggestions, mentions are deferred phases.                                                                                               |
| 6   | Mentions                                | Deferred to **Phase 7**, but a `mentions: []` placeholder field is reserved in the profile/comment/post/message write paths from the start (additive, no migration later). |

---

## 2. Shared foundations (used by all three features)

### 2.1 `UserRef` — the canonical lightweight user embed

Superset of `CommentUser`; dropped onto follow edges, posts, messages, notifications.

```jsonc
{ "id": "uid", "name": "Vijay", "username": "vijay", "image_url": "https://…" }
```

- New model `user_ref.dart` in **both** projects.
- `CommentUser` remains for back-compat; it can later be aliased to `UserRef`.

### 2.2 Block graph — `blocks/{blockerId}_{blockedId}`

Single choke point consulted by follow-create now, and by posts feeds + DM gating later.

```jsonc
{ "blocker_id": "A", "blocked_id": "B", "created_at": <ts> }
```

### 2.3 Generalized notification helper

Extract `sendUserNotification(uid, title, body, data)` from the existing
`sendCommentNotification` so follow / mention / post-like / message pushes share one tested,
token-pruning code path. Routing payload stays all-string values, consumed by
[../../tfn-app/lib/models/notification_model.dart](../../tfn-app/lib/models/notification_model.dart) and the app `NotificationService`.

New routing types to add:
| notification_type | extra keys | opens |
|---|---|---|
| `follow` | `type:"profile"`, `profile_id` | public profile |
| `mention` (Phase 7) | `type:"profile"` + source ctx | source content |
| `post_like` / `post_comment` (Feature 2) | `type:"post"`, `post_id` | post detail |
| `message` (Feature 3) | `type:"conversation"`, `conversation_id` | conversation |

---

# FEATURE 1 — Profiles + Follow (Phases 1–8)

Fully specified. This is the current milestone.

## 3. Data model

### 3.1 Extend `users/{uid}` (no new profile collection)

Keeps the existing world-readable `users` pattern; avoids a mirror-sync function.

```jsonc
{
  // existing: name, email, image_url, role, fcmToken, muted_until, disabled, subscription…
  "username": "vijay",
  "username_lower": "vijay",       // case-insensitive lookup + @mention prefix search
  "bio": "Track & field fan",
  "cover_url": "https://…",
  "links": { "website": "…", "instagram": "…" },
  "is_private": false,             // reserved for private-account phase
  "followers_count": 0,            // function-maintained only
  "following_count": 0,            // function-maintained only
  "posts_count": 0,                // reserved for Feature 2
  "profile_updated_at": <ts>
}
```

All fields nullable/defaulted so existing docs keep working before backfill.

### 3.2 Handle reservation — `usernames/{usernameLower}`

```jsonc
// doc id = "vijay"
{ "uid": "…", "created_at": <ts> }
```

Global uniqueness enforced atomically (transaction: create username doc **and** set
`users.username`/`username_lower` together). Validation: `^[a-z0-9_]{3,20}$` + reserved-word list.

### 3.3 Follow edges — flat `follows/{followerId}_{followeeId}` (canonical)

```jsonc
{
  "follower_id": "A",
  "followee_id": "B",
  "created_at": <ts>,
  "follower": { UserRef },   // denormalized → followers/following list = 1 query
  "followee": { UserRef }
}
```

Chosen over subcollections because: O(1) "does A follow B?" via `get(follows/A_B)`; one rule
set (doc id encodes ownership); both directions index-queryable; clean input for a future feed
fan-out.

### 3.4 Counters

`followers_count` / `following_count` live on `users/{uid}`, written **only** by Cloud Functions.

## 4. Cloud Functions (add to functions/index.js, dev first)

- ☐ **`onFollowCreate`** — `onDocumentCreated('follows/{edgeId}')`: batch `increment(+1)` on
  followee `followers_count` and follower `following_count`; push
  `"{name} started following you"` to `followee_id` via `sendUserNotification`; self-follow guard.
- ☐ **`onFollowDelete`** — `onDocumentDeleted('follows/{edgeId}')`: decrement both counters
  (floor at 0); no notification.
- ☐ _(reserved)_ **`onUserProfileUpdate`** — optional re-denormalization of recent embeds when
  name/username/avatar change. MVP accepts mild staleness on old embeds (same trade-off as
  `CommentUser` today).

## 5. Security rules (append to firestore.rules)

```
match /usernames/{username} {
  allow read: if true;
  allow create: if isUserSignedIn() && request.resource.data.uid == request.auth.uid;
  allow delete: if isUserSignedIn() && resource.data.uid == request.auth.uid;
}

match /follows/{edgeId} {
  allow read: if true;
  allow create: if isUserSignedIn()
    && request.resource.data.follower_id == request.auth.uid
    && request.resource.data.follower_id != request.resource.data.followee_id
    && !exists(/databases/$(database)/documents/blocks/$(request.resource.data.followee_id + '_' + request.auth.uid));
  allow delete: if isUserSignedIn() && resource.data.follower_id == request.auth.uid;
  // no update
}

match /blocks/{blockId} {
  allow read: if isUserSignedIn()
    && (resource.data.blocker_id == request.auth.uid || resource.data.blocked_id == request.auth.uid);
  allow create: if isUserSignedIn() && request.resource.data.blocker_id == request.auth.uid;
  allow delete: if isUserSignedIn() && resource.data.blocker_id == request.auth.uid;
}
```

Harden the existing `users` update rule so clients cannot forge counters/role:

```
allow update: if isUserSignedIn()
  && ( (request.auth.uid == request.resource.id
        && !request.resource.data.diff(resource.data).affectedKeys()
              .hasAny(['followers_count','following_count','posts_count','role','disabled']))
     || isAdmin() );
```

(Cloud Functions use the Admin SDK and bypass rules, so counter writes still succeed.)

## 6. Indexes (append to firestore.indexes.json)

```jsonc
{ "collectionGroup":"follows","queryScope":"COLLECTION","fields":[
  {"fieldPath":"follower_id","order":"ASCENDING"},{"fieldPath":"created_at","order":"DESCENDING"}]},
{ "collectionGroup":"follows","queryScope":"COLLECTION","fields":[
  {"fieldPath":"followee_id","order":"ASCENDING"},{"fieldPath":"created_at","order":"DESCENDING"}]}
```

## 7. App changes (tfn-app)

**Models** (`lib/models/`)

- ☐ `user_ref.dart` — `UserRef`.
- ☐ `follow_edge.dart` — `FollowEdge`.
- ☐ Extend `UserModel` ([../../tfn-app/lib/models/user_model.dart](../../tfn-app/lib/models/user_model.dart)) with
  `username`, `bio`, `coverUrl`, `links`, `isPrivate`, `followersCount`, `followingCount`,
  `postsCount` (+ `mentions` placeholder where write paths gain it).

**Service** (`FirebaseService`, [../../tfn-app/lib/services/firebase_service.dart](../../tfn-app/lib/services/firebase_service.dart))

- ☐ `followUser(UserRef me, UserRef target)` — writes `follows/{me}_{target}`, idempotent.
- ☐ `unfollowUser(meId, targetId)`.
- ☐ `isFollowingStream(meId, targetId)` — `follows/A_B` doc snapshot.
- ☐ `getFollowersSnapshot(uid, {lastDocument})` / `getFollowingSnapshot(...)` — paginated like comments.
- ☐ `getPublicProfileByUsername(username)`.
- ☐ `reserveUsername(...)` — transaction against `usernames/`.
- ☐ `blockUser / unblockUser`.
- ☐ `uploadCoverImage(XFile)` — same pattern as `uploadImageToHosting`, into Storage `user_covers/`.

**Providers** (`lib/providers/`)

- ☐ `publicProfileProvider(uid)`, `followStatusProvider(targetId)` (stream),
  `followersProvider` / `followingProvider` (paginated notifiers).

**Screens / components**

- ☐ `screens/profile/public_profile_screen.dart` — header (avatar, cover, counts, `FollowButton`);
  a stubbed "Posts" tab (empty state now → filled by Feature 2).
- ☐ `screens/profile/followers_list_screen.dart` — shared followers/following list with per-row `FollowButton`.
- ☐ `components/follow_button.dart` — watches `followStatusProvider`, optimistic toggle.
- ☐ Enhance `EditProfile` (opened from [../../tfn-app/lib/screens/tabs/profile_tab/user_info.dart](../../tfn-app/lib/screens/tabs/profile_tab/user_info.dart))
  with username, bio, cover, links.
- ☐ **Entry points:** make comment avatars/names (`CommentTile`), author info, and event-chat
  rows tap through to `public_profile_screen`. (Same navigation posts/DMs will reuse.)

## 8. Admin panel changes (tfn_admin-panel)

- ☐ Extend admin `UserModel` symmetrically.
- ☐ Users tab ([../lib/tabs/admin_tabs/users/users.dart](../lib/tabs/admin_tabs/users/users.dart)):
  show `username`, follower/following counts; add **verify badge**, **reset username**,
  **block/unban** actions, reusing the overflow-menu + `UserMixin.hasAdminAccess` pattern from
  [../lib/mixins/comment_mixin.dart](../lib/mixins/comment_mixin.dart).
- ☐ _(optional)_ Dashboard cards: total follows, most-followed (later).

## 9. Phased delivery — Feature 1

Each phase is independently shippable to dev.

- ◐ **Phase 1 — Profile foundation:** `UserModel` fields, `UserRef`, edit-profile (bio/cover/links),
  `user_covers/` storage path, backfill script (init counters = 0, generate handles). Reserve
  `mentions: []` in write paths.
  **Specced as `add-profile-foundation`** — see `openspec/changes/add-profile-foundation/`
  in this repo (schema, rules, storage, backfill, admin UI) and in `../tfn-app`
  (models, edit-profile UI). Those artifacts supersede this summary.
- ☐ **Phase 2 — Handle system:** `usernames/` collection, reservation transaction, rules, validation.
- ☐ **Phase 3 — Follow graph:** `follows` collection, rules, indexes, service + providers,
  `FollowButton`, `onFollowCreate` / `onFollowDelete` counters.
- ☐ **Phase 4 — Profile UI:** public profile screen, followers/following lists, tap-through wiring.
- ☐ **Phase 5 — Follow notifications:** generalize `sendUserNotification`, add follow push + app routing.
- ☐ **Phase 6 — Block (minimal) + admin moderation actions.**
- ☐ **Phase 7 — Mentions** (see §12). Deferred.
- ☐ **Phase 8 — Privacy hardening** (email/fcmToken/muted_until private sub-doc). Deferred.
- ☐ _(future)_ Private accounts + follow requests; follow suggestions.

**Milestone acceptance (Phases 1–6):** a signed-in user can set a unique @handle + bio + cover,
open anyone's profile, follow/unfollow with live server counts, browse followers/following, and
receive a push when followed — all enforced server-side, deployed to `track-network-dev`.

---

# FEATURE 2 — User-generated Posts (image/video) — forward-compat outline

> Not yet specced in full. This section captures the hooks Feature 1 must leave in place so Posts
> is additive. Expand this into full phases when Posts begins.

- **Author** = `UserRef`. **Feed source** = the follow graph.
- **Collection** `posts/{postId}`: `{ author: UserRef, text, media: [{type, url, thumb, w, h}],
created_at, like_count, comment_count, mentions: [] }`. Media in Storage `post_media/{uid}/…`.
- **Comments** reuse the existing flat `comments` collection via a new `target_type: "post"`
  (mirrors the article/event pattern already in place — add matching composite indexes).
- **Counters** (`like_count`, `comment_count`, user `posts_count`) via Cloud Functions, same as follows.
- **Feed strategy:** MVP = read-time query `posts where author.id in (myFollowing)` (fine for small
  follow counts). At scale, add a `feed/{uid}/items/{postId}` fan-out function triggered on
  post-create, driven by the `follows` edges built in Feature 1.
- **Profile "Posts" tab** stub from Phase 4 becomes the per-user post list
  (`posts where author.id == uid order by created_at desc`).
- **Notifications:** `post_like` / `post_comment` via `sendUserNotification`.
- **Admin:** posts moderation tab (list, view media, delete, hide) mirroring the comments tab.
- **Video:** capture/transcode approach (client compress vs. server) to be decided at spec time.

---

# FEATURE 3 — Messaging MVP — forward-compat outline

> Not yet specced in full. Hooks from Features 1–2 that make it additive:

- **Gating** reads the **follow** + **block** graphs from Feature 1 (final policy per Decision #4).
- **Participants** stored as `UserRef` maps.
- **Collections:** `conversations/{conversationId}` (participant ids + last-message preview +
  per-user unread counts) and `conversations/{conversationId}/messages/{messageId}`.
- **1:1 first;** deterministic conversation id from sorted participant uids (like follow edge ids).
- **Notifications:** `message` type via `sendUserNotification`; `fcmToken` already on user docs.
- **Presence/last-seen** (optional) can hang off the profile doc.
- **Admin:** report/abuse review surface reusing the moderation/mute infrastructure.

---

## 10. Deployment checklist (run per phase, dev first)

1. `firebase deploy --only firestore:rules --project=track-network-dev`
2. `firebase deploy --only firestore:indexes --project=track-network-dev`
3. `firebase deploy --only functions --project=track-network-dev` (retry once if Eventarc perms error)
4. App: `flutter run --flavor dev --dart-define=FLAVOR=dev`
5. Admin: `flutter run -d chrome --dart-define=FLAVOR=dev`
6. Verify on dev, then promote to prod **only when explicitly requested**.

---

## 11. Cross-cutting: notifications routing summary

New payloads to add to the app `NotificationService` routing (all-string values), consumed by
[../../tfn-app/lib/models/notification_model.dart](../../tfn-app/lib/models/notification_model.dart):
`follow` → profile · `mention` → source · `post_like`/`post_comment` → post ·
`message` → conversation. See §2.3 table.

## 12. Mentions (Phase 7 detail)

`@username` becomes a tappable profile link + optional "X mentioned you" push. Three capabilities:
autocomplete (prefix query on `username_lower`), linkification (RichText spans → profile route),
notification (Cloud Function reads `mentions[]`, self-mention + block guarded).

**Storage:** keep raw `text` plus a structured array so links survive display-name changes:

```jsonc
"mentions": [ { "uid": "abc123", "username": "vijay", "offset": 14, "length": 6 } ]
```

Storing `uid` (not just handle) keeps links correct after renames and lets notifications fan out
directly. Because the `mentions: []` placeholder is reserved in write paths from Phase 1, adding
mentions later is purely additive — same strategy as the `target_*` comment fields.
