# AGENTS.md — tfn_admin-panel (Track Field Network admin + backend)

Canonical, tool-agnostic agent instructions for this repo. Any AI assistant working here
should read this file first. Other entry points (`.github/copilot-instructions.md`,
`CLAUDE.md`) are thin pointers back to this file — **edit this file, not the pointers.**

Deep architecture reference: [CONTEXT_ADMIN_PANEL.md](CONTEXT_ADMIN_PANEL.md).
Roadmap / feature plan: [SOCIAL_FEATURES_PLAN.md](SOCIAL_FEATURES_PLAN.md).

## What this is

Flutter **web** admin panel for Track Field Network, **plus the entire Firebase backend**
shared with the mobile app (`../tfn-app`):

- `firestore.rules`, `firestore.indexes.json`, `storage.rules`
- `functions/` — 2nd-gen Cloud Functions (Node 22)

Package namespace is **`news_admin`** (legacy — do not rename).

## Non-negotiable rules

1. **Dev-first, always.** Every change targets the dev Firebase project
   `track-network-dev`. Never deploy to prod (`the-track-and-field-network`) unless the
   user explicitly says "prod".
2. **Never run `firebase deploy` without an explicit `--project` flag.** An unqualified
   deploy can hit the wrong project.
3. **This repo owns the backend contract.** A schema/rule/index/function change here is a
   breaking change for `../tfn-app`. When you change a Firestore field, check whether the
   app's model and read paths need the matching change, and say so.
4. **Counters and push notifications are server-authoritative.** Denormalized counters and
   FCM sends happen only in `functions/index.js`, never from a client. Client-writable
   fields must be blocked in `firestore.rules`.
5. **Additive schema changes only.** When renaming a Firestore field, keep writing the
   legacy field as a mirror and make reads fall back to it (the existing
   `target_*` / `article_*` comment pattern). This avoids backfills and index churn.
6. **All Firestore/Storage access goes through `lib/services/firebase_service.dart`.**
   No repository layer; no raw `FirebaseFirestore.instance` in widgets.

## Commands

```bash
# Dev — the default for all everyday work
flutter run -d chrome --dart-define=FLAVOR=dev
flutter build web     --dart-define=FLAVOR=dev

firebase deploy --only firestore:rules   --project=track-network-dev
firebase deploy --only firestore:indexes --project=track-network-dev
firebase deploy --only functions         --project=track-network-dev

# Prod — only on explicit request
flutter build web --dart-define=FLAVOR=prod
firebase deploy --project=the-track-and-field-network

flutter analyze              # run before declaring work complete
cd functions && npm run lint # eslint (google config) for Cloud Functions
```

`lib/main.dart` reads `String.fromEnvironment('FLAVOR', defaultValue: 'prod')`, so omitting
`--dart-define` silently selects **prod**. Always pass it.

Full phase-deploy runbook: [.github/prompts/deploy-dev.prompt.md](.github/prompts/deploy-dev.prompt.md).

## Firebase account hygiene (matters on a new machine)

Firebase/GCP identity is **separate** from the GitHub identity and may legitimately differ.
Never "fix" one to match the other. The Firebase MCP server caches credentials and can
report a stale account/project list — verify with the CLI before any create or deploy:

```bash
firebase login:list
firebase projects:list
```

## Conventions

- **State:** Riverpod, one small provider per concern, in `lib/providers/` (plus
  per-tab provider files such as `lib/tabs/admin_tabs/app_settings/app_setting_providers.dart`).
- **Models:** `lib/models/`. Every model exposes `factory X.fromFirebase(DocumentSnapshot)`
  and `static Map<String, dynamic> getMap(X)`. Firestore `snake_case` ↔ Dart `camelCase`.
  New fields nullable/defaulted so existing docs keep parsing.
- **Shell / navigation:** sidebar structure lives in `lib/configs/constants.dart`, driven by
  `lib/pages/home.dart` and `lib/components/side_menu.dart`. Role gating (`admin` / `author`)
  is resolved in `lib/pages/splash.dart` via `AuthService.checkUserRole`.
- **Reusable UI logic** goes in `lib/mixins/`, not inheritance.
- **Admin settings are the mobile app's control plane.** A new app-behavior toggle usually
  means: new key in `settings/app` → `AppSettingsModel` in **both** repos →
  `app_setting_providers.dart` hydration → `app_settings_view.dart` persistence.

## Scoped rules

Additional rules apply to specific paths. Copilot/VS Code loads these automatically via
`applyTo` frontmatter; other tools should read the relevant one on demand.

| Path scope                                         | File                                                                                                           |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `firestore.rules`, `firestore.indexes.json`, `storage.rules` | [.github/instructions/firebase-backend.instructions.md](.github/instructions/firebase-backend.instructions.md) |
| `functions/**`                                     | [.github/instructions/cloud-functions.instructions.md](.github/instructions/cloud-functions.instructions.md)   |
| `lib/models/**`                                    | [.github/instructions/dart-models.instructions.md](.github/instructions/dart-models.instructions.md)           |

## Git identity

This is a personal project. Commit and push as `Vijay Chandra <vijaychandra800@gmail.com>`
using the GitHub account `vijaychandra800` — **never** a work account. If a push fails with
"Repository not found", that is a wrong-token problem, not a missing repo.

## Working agreements

- Verify claims against `git diff` / `flutter analyze` before reporting work as done.
- Do not create summary markdown files unless asked.
- When a phase in [SOCIAL_FEATURES_PLAN.md](SOCIAL_FEATURES_PLAN.md) lands, update its
  status checkbox in the same change.
