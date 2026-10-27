---
mode: agent
description: Deploy the current change to the dev Firebase project (track-network-dev) and verify it.
---

# Deploy to dev

Deploy the current change to **`track-network-dev`**. Never to prod.

If the user has not said which parts changed, work it out from `git status` / `git diff`
and only deploy what actually changed.

## Steps

1. **Confirm identity and project.** Firebase credentials can be stale or belong to another
   account, and the Firebase MCP server caches them. Verify with the CLI, not the cache:

   ```bash
   firebase login:list
   firebase projects:list
   ```

   Stop and ask if `track-network-dev` is not present or the account looks wrong.

2. **Static checks.**

   ```bash
   flutter analyze
   cd functions && npm run lint && cd ..
   ```

3. **Rules** (only if `firestore.rules` / `storage.rules` changed):

   ```bash
   firebase deploy --only firestore:rules --project=track-network-dev
   ```

4. **Indexes** (only if `firestore.indexes.json` changed):

   ```bash
   firebase deploy --only firestore:indexes --project=track-network-dev
   ```

   Composite index builds are asynchronous — a query can still fail for a few minutes after
   a successful deploy. Note this rather than treating it as a bug.

5. **Functions** (only if `functions/` changed):

   ```bash
   firebase deploy --only functions --project=track-network-dev
   ```

   The first Firestore/Eventarc 2nd-gen trigger on a project can fail with an Eventarc
   Service Agent permission-propagation error. Retry the same command once after a few
   minutes before investigating anything else.

6. **Run the clients against dev.**

   ```bash
   # admin panel (this repo)
   flutter run -d chrome --dart-define=FLAVOR=dev

   # mobile app (../tfn-app)
   flutter run --flavor dev --dart-define=FLAVOR=dev
   ```

7. **Report**: what was deployed, what was skipped, what still needs manual verification in
   the Firebase console.

## Do not

- Do not run `firebase deploy` without `--project`.
- Do not deploy to `the-track-and-field-network` unless the user explicitly says "prod" in
  this conversation.
- Do not mark the work complete on a successful deploy alone — deploy is not verification.
