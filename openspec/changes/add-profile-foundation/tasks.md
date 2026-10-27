# Tasks — profile foundation (backend and admin surface)

All tasks land in **`tfn_admin-panel`** unless stated otherwise. Deploy targets
`track-network-dev` only.

Ordering matters: the model and the backfill must be in place before the rules tighten,
otherwise the hardened rule rejects writes for fields nothing has populated yet.

## 1. Models

- [ ] 1.1 Add `lib/models/user_ref.dart` — `UserRef { id, name, username, imageUrl }` with
      `fromFirebase` / `fromFirestore` / `getMap`, mirroring the existing `CommentUser`
      shape. Leave `CommentUser` untouched for back-compat.
- [ ] 1.2 Extend `lib/models/user_model.dart` with `username`, `usernameLower`, `bio`,
      `coverUrl`, `links`, `isPrivate`, `followersCount`, `followingCount`, `postsCount`,
      `profileUpdatedAt`. All nullable or defaulted; counters default to `0`.
- [ ] 1.3 Keep the three counters out of `UserModel.getMap` so the admin client can never
      write them.

## 2. Backfill

- [ ] 2.1 Add `functions/scripts/backfill_profiles.js` — Admin SDK, paged in batches of 450,
      requires an explicit `--project` argument and refuses to run without it.
- [ ] 2.2 Set each counter to `0` only when the field is absent, so a re-run cannot reset
      live counts once Phase 3 increments them.
- [ ] 2.3 Derive `username` / `username_lower` by slugifying the display name to
      `^[a-z0-9_]{3,20}$`; pad short results, truncate long ones.
- [ ] 2.4 Log handle collisions to stdout and continue. Do not auto-resolve — Phase 2's
      registry owns uniqueness.
- [ ] 2.5 Write `mentions: []` where the profile write path touches a record.
- [ ] 2.6 Verify idempotency: run twice against dev, confirm the second run reports every
      record as skipped.

## 3. Storage rules

- [ ] 3.1 Add a `user_covers/{uid}/{fileName}` block to `storage.rules`: public read,
      write only when `request.auth.uid == uid`, `request.resource.size` under the cap,
      `contentType` must match `image/.*`.
- [ ] 3.2 Deploy: `firebase deploy --only storage --project=track-network-dev`.
- [ ] 3.3 Verify on dev: owner upload succeeds; upload to another uid is rejected;
      oversized and non-image uploads are rejected; a stored cover is readable signed out.

## 4. Firestore rules — the risky step

- [ ] 4.1 **Before changing anything**, audit write paths that touch `users` in both repos
      for the five denied fields (`followers_count`, `following_count`, `posts_count`,
      `role`, `disabled`). Record what is found; this determines whether 4.2 is safe.
- [ ] 4.2 Harden the `users` update rule with the deny-list from design.md, keeping the
      admin bypass.
- [ ] 4.3 Deploy: `firebase deploy --only firestore:rules --project=track-network-dev`.
- [ ] 4.4 Verify on dev that **`AuthService.createAuthor` still works** — it writes a user
      document through a secondary Firebase app and is the most likely regression.
- [ ] 4.5 Verify on dev: owner can edit bio/cover/links/handle; owner cannot change a
      counter, `role`, or `disabled`; an admin can.

## 5. Admin UI

- [ ] 5.1 Surface `username` and the follower/following counts as read-only columns in
      `lib/tabs/admin_tabs/users/users.dart`.
- [ ] 5.2 Render users with no handle and no counters without failing (pre-backfill records).

## 6. Cross-repo coordination

- [ ] 6.1 Confirm the sibling `add-profile-foundation` change in `../tfn-app` has landed its
      matching `UserModel` fields before the rules deploy.
- [ ] 6.2 Confirm the app's cover upload writes to `user_covers/{uid}/` and nowhere else.

## 7. Sign-off

- [ ] 7.1 `flutter analyze` clean.
- [ ] 7.2 `cd functions && npm run lint` clean.
- [ ] 7.3 Backfill run against `track-network-dev`; collision count recorded in the change.
- [ ] 7.4 Tick Phase 1 in [docs/SOCIAL_FEATURES_PLAN.md](../../../docs/SOCIAL_FEATURES_PLAN.md).
- [ ] 7.5 Confirm no index was needed, matching design.md. If a query appeared that needs
      one, add it to `firestore.indexes.json` in this change rather than later.

## Explicitly not in this change

`usernames/` registry and uniqueness (Phase 2) · follow graph and counter functions
(Phase 3) · follow notifications (Phase 5) · prod deploy of anything above.
