# Track Field Network Admin Panel Context

## Purpose

This project is the Flutter web admin surface for Track Field Network. It is used by admins and authors to manage content, users, notifications, purchases, ads, and app settings stored in Firebase.

## Stack Summary

- Flutter with Riverpod for state management.
- Firebase Core, Auth, Firestore, Storage, and Cloud Messaging.
- Web-oriented admin UI with responsive sidebar layout.
- Rich content editing through `html_editor_enhanced`.

## Environments (Dev / Prod)

**Default policy: any new code, rules, indexes, or Cloud Functions change MUST target the dev environment first. Only touch prod when the user explicitly says so.**

| Env  | Firebase Project ID           | Web App ID                                  | Options file                                                   |
| ---- | ----------------------------- | ------------------------------------------- | -------------------------------------------------------------- |
| Dev  | `track-network-dev`           | `1:199255076107:web:47e54cd5b3cc20ebbb460e` | [lib/firebase_options_dev.dart](lib/firebase_options_dev.dart) |
| Prod | `the-track-and-field-network` | `1:291089351662:web:8f9e830e536532803904ff` | [lib/firebase_options.dart](lib/firebase_options.dart)         |

### Flavor wiring

- [lib/main.dart](lib/main.dart) reads `const _flavor = String.fromEnvironment('FLAVOR', defaultValue: 'prod')` and picks `dev_options.DefaultFirebaseOptions.currentPlatform` vs `prod_options.DefaultFirebaseOptions.currentPlatform`. Both options files are imported with aliases.
- [firebase.json](firebase.json) registers both options files under `flutter.platforms.dart` and includes top-level `firestore` (`firestore.rules` + `firestore.indexes.json`) and `storage` (`storage.rules`) sections used by `firebase deploy`.

### Run / deploy commands

```bash
# Dev (default for everyday work)
flutter run -d chrome --dart-define=FLAVOR=dev
flutter build web   --dart-define=FLAVOR=dev
firebase deploy --project=track-network-dev

# Prod (only when explicitly requested)
flutter run -d chrome --dart-define=FLAVOR=prod
flutter build web   --dart-define=FLAVOR=prod
firebase deploy --project=the-track-and-field-network
```

See [../DEV_ENVIRONMENT.md](../DEV_ENVIRONMENT.md) at the workspace root for the full clone manifest and manual console checklist.

## Startup And App Boot Flow

### Entry point

- `lib/main.dart`
  - Initializes Flutter bindings.
  - Enables path URL strategy for web.
  - Reads the `FLAVOR` dart-define and picks dev vs prod `DefaultFirebaseOptions` (defaults to `prod` if not set).
  - Initializes Firebase with the selected options.
  - Wraps the app with `ProviderScope`.

### Root widget

- `lib/app.dart`
  - Builds `MaterialApp`.
  - Uses `SplashScreen` as the initial screen.
  - Sets the shared theme and scroll behavior for both mouse and touch.

### Authentication and access gate

- `lib/pages/splash.dart`
  - Subscribes to `FirebaseAuth.instance.authStateChanges()`.
  - If signed out, redirects to `Login`.
  - If signed in, calls `AuthService.checkUserRole(uid)`.
  - Only `admin` and `author` roles are allowed into the panel.
  - Loads app settings through `appSettingsProvider` and blocks access when license is missing.
  - Loads current user data through `userDataProvider` before entering `Home`.

### Effective admin boot sequence

1. App starts in `main.dart`.
2. `MyApp` in `lib/app.dart` loads `SplashScreen`.
3. `SplashScreen` checks Firebase auth state.
4. `AuthService.checkUserRole` validates Firestore user roles.
5. `appSettingsProvider` verifies license state.
6. `userDataProvider` loads current user document.
7. User is routed to `Home`, `Login`, or `VerifyInfo`.

## Main Shell And Navigation

### Admin shell

- `lib/pages/home.dart`
  - Main admin scaffold.
  - Uses `pageControllerProvider` to switch between content areas.
  - Loads categories on `initState` through `categoriesProvider`.
  - Builds desktop sidebar plus content area.
  - Selects tab list based on current user role.

### Navigation state

- `lib/components/side_menu.dart`
  - Uses `menuIndexProvider` to track selected drawer item.
  - Renders menu options from `menuList` and `menuListAuthor`.
  - Drives the `PageController` in `Home`.

- `lib/configs/constants.dart`
  - Defines the complete sidebar structure.
  - Admin menu sections:
    - Dashboard
    - Articles
    - Events
    - Featured
    - Categories
    - Tags
    - Comments
    - Users
    - Notifications
    - Purchases
    - Ads
    - Settings
    - License
  - Author menu sections:
    - Dashboard
    - My Articles
    - Comments

### Home tab ownership

- Admin tabs live under `lib/tabs/admin_tabs/`.
- Author tabs live under `lib/tabs/author_tabs/`.
- `lib/pages/home.dart` is the controlling file when changing shell structure, tab order, or role-specific visibility.

## State Management Model

This project uses lightweight Riverpod state rather than a centralized domain layer.

### Global auth and user state

- `lib/providers/auth_state_provider.dart`
  - Stores current role as `UserRoles`.

- `lib/providers/user_data_provider.dart`
  - Loads the signed-in user document from Firestore.

### Shared reference data

- `lib/providers/categories_provider.dart`
  - Loads all categories.
  - Also exposes event-category filtering via parent category lookup.

### Settings hydration

- `lib/tabs/admin_tabs/app_settings/app_setting_providers.dart`
  - Fetches app settings once from Firestore.
  - Fan-outs settings values into many Riverpod state providers.
  - Controls feature toggles, layout selection, social links, and ad configuration.

### Dashboard state

- `lib/tabs/admin_tabs/dashboard/dashboard_providers.dart`
  - Provides counts and chart data for dashboard widgets.
  - This is the first place to inspect when dashboard totals or analytics cards look wrong.

## Firebase And Service Layer

### Core data service

- `lib/services/firebase_service.dart`
  - Main Firestore and Storage abstraction.
  - Owns CRUD for:
    - Articles
    - Events
    - Categories
    - Tags
    - Notifications
    - Users
    - Purchases
    - App settings
  - Handles image uploads to Firebase Storage.
  - Provides query helpers used by lists, dashboards, and forms.

### Auth service

- `lib/services/auth_service.dart`
  - Admin login and logout.
  - Role lookup from Firestore user document.
  - Password changes.
  - Author account creation through a temporary Firebase app instance.

### Notification service

- `lib/services/notification_service.dart`
  - Sends push notifications using FCM HTTP v1.
  - Supports:
    - Topic-based custom notifications.
    - Post notifications for newly published articles.
  - Builds payloads using article metadata and notification models.

### Utility services

- `lib/services/app_service.dart`
  - General helpers such as image picking and content sanitization.
- `lib/services/api_service.dart`
  - External API integration surface if present for app-level remote calls.

## Major Product Areas

### Dashboard

- Main files:
  - `lib/tabs/admin_tabs/dashboard/dashboard.dart`
  - `lib/tabs/admin_tabs/dashboard/dashboard_providers.dart`
- Purpose:
  - Displays aggregate metrics for users, subscribers, purchases, authors, articles, events, and pending content.
  - Shows charts and top content widgets.

### Articles

- Main files:
  - `lib/tabs/admin_tabs/articles/articles.dart`
  - `lib/forms/article_form.dart`
  - `lib/mixins/article_mixin.dart`
  - `lib/tabs/admin_tabs/articles/article_preview/`
- Behavior:
  - Article lists are query-driven and paginated using `FirestoreQueryBuilder`.
  - Article form supports create and edit modes.
  - Supports normal, video, and audio content types.
  - Supports draft, pending, live, and archive statuses.
  - Supports feature flagging, comments toggle, tags, categories, thumbnails, author selection, and optional user notification.

### Events

- Main files:
  - `lib/tabs/admin_tabs/events/events.dart`
  - `lib/forms/event_form.dart`
- Behavior:
  - Event content follows a structure similar to articles.
  - Statuses include draft, upcoming, live, covered, and archive.

### Categories And Tags

- Main files:
  - `lib/tabs/admin_tabs/categories/`
  - `lib/forms/tag_form.dart`
  - `lib/components/category_dropdown.dart`
  - `lib/components/tags_dropdown.dart`
- Behavior:
  - Categories are shared reference data used by both admin and client app.
  - Event categories are modeled as children under the Events parent category.

### Comments

- Main files:
  - `lib/tabs/admin_tabs/comments/comments.dart` — list shell, holds `commentsQueryprovider` + `commentsTargetFilterProvider`.
  - `lib/tabs/admin_tabs/comments/filter_comments_target.dart` — All / Articles / Events dropdown next to the sort button.
  - `lib/tabs/admin_tabs/comments/filter_comments_event.dart` — per-event picker (visible when the target filter is Events); narrows the list to comments for a single event via the `(target_type, target_id, created_at desc)` index.
  - `lib/tabs/admin_tabs/comments/sort_comments.dart` — composes target-type filter with sort order; delegates query assembly to `FirebaseService.rebuildCommentsQuery(...)`.
  - `lib/services/firebase_service.dart` → `commentsQueryByEvent(eventId)` for the per-event filter.
  - `lib/tabs/admin_tabs/comments/article_comments_reply.dart` — admin reply flow; writes new `target_*` fields and mirrors `article_*`.
  - `lib/tabs/author_tabs/author_article_comments.dart` — author scope, unchanged.
  - `lib/mixins/comment_mixin.dart` — per-row Article/Event badge plus an overflow menu (Delete + Mute 1d / 7d / 30d / forever + Unmute), gated by `UserMixin.hasAdminAccess`.
- Firestore shape:
  - Flat `comments` collection. Each doc carries `target_type` (`'article'` | `'event'`), `target_id`, `target_title`.
  - For article comments, legacy `article_id`, `article_title`, `article_author_id` are still written so the existing composite index `(article_id asc, created_at desc)` and the author-articles query keep working without backfill.
  - New composite indexes (deployed via `firestore.indexes.json`): `(target_type asc, created_at desc)`, `(target_type asc, target_id asc, created_at desc)`, and `(target_id asc, target_type asc, created_at asc)`.
- Behavior:
  - Admins can moderate globally across both article and event comments, filter by target, and mute/unmute users from any row.
  - Authors retain access to comments tied to their own articles (legacy `article_author_id` mirror is what powers that query).

### Fanzone Chat Lifespan

- App settings keys: `chat_read_only_hours` and `chat_purge_days` live in `settings/app` and are exposed in the admin App Settings > Others tab.
- Admin UI: `lib/tabs/admin_tabs/app_settings/others_tab_settings.dart` adds the read-only and purge inputs; `app_setting_providers.dart` hydrates them; `app_settings_view.dart` persists them.
- Enforcement: `firestore.rules` uses `eventChatWritable()` to block event comment create/update after `event.end_date_time + chat_read_only_hours` (admins still bypass for moderation).
- Purge: `functions/index.js` schedules `purgeExpiredEventChats` every 24 hours and deletes event comments once the event has been ended for `chat_purge_days`.
- Consumer app behavior: `tfn-app/lib/components/event_comments_section.dart` keeps existing comments visible, but freezes the composer, replies, and reactions after the read-only window.

### Comment Engagement Notifications

- Goal: notify the owner of an event Fanzone comment whenever another user replies to it or reacts to it. Article comment threads are intentionally excluded — only `target_type === 'event'` comments trigger pushes.
- Delivery is server-side via Firestore-triggered 2nd-gen Cloud Functions in [functions/index.js](functions/index.js). Clients never send push directly — the recipient's FCM token is read server-side from `users/{uid}.fcmToken` (written by the mobile app on splash via `FirebaseService.saveFCMToken()`).
- Functions:
  - `onCommentReply` — `onDocumentCreated('comments/{commentId}')`. Fires only when the new comment has a `reply_to.comment_id` **and** `target_type === 'event'`; fetches the parent comment to resolve its owner (`user.id`) and pushes `"{replier} replied to your comment"`.
  - `onCommentReaction` — `onDocumentUpdated('comments/{commentId}')`. Skips non-event comments, then diffs `reactions` before/after, finds newly-added `(userId, emoji)` pairs, and pushes `"{reactor} reacted {emoji} to your comment"` to the comment owner (`after.user.id`). Reaction removals (toggle-off) never notify.
- Shared helpers in the same file: `sendCommentNotification(ownerId, title, body, data)` (token lookup + send + prune stale tokens on `messaging/registration-token-not-registered` / `invalid-registration-token`) and `buildCommentTargetData(commentData)` (routing payload).
- Self-engagement guard: the author is never notified about their own reply/reaction (`ownerId === replierId` / reactor-id check).
- Payload routing (all-string values): `notification_type: "comment"` plus `type: "event"` + `event_id` for event comments, or `type: "article"` + `article_id` for article comments. Consumed by `tfn-app/lib/models/notification_model.dart` and the app's `NotificationService` routing.
- Deploy notes: these are the first Eventarc/Firestore 2nd-gen triggers on a project, so the **first** `firebase deploy --only functions` can fail with an Eventarc Service Agent permission-propagation error — simply retry the deploy after a few minutes. Both functions are deployed to **dev** (`track-network-dev`); prod (`the-track-and-field-network`) still needs an explicit deploy.

### User muting

- Storage: `users.muted_until: Timestamp` on the user doc. Field absent = not muted. Unmute deletes the field via `FieldValue.delete()` rather than setting null, so `where('muted_until', isNull: false)` cleanly lists muted users.
- Service: `FirebaseService.muteUser(userId, DateTime until)` (merge) and `FirebaseService.unmuteUser(userId)`.
- UI entry points: per-row overflow menu in [lib/mixins/comment_mixin.dart](lib/mixins/comment_mixin.dart); a new "Muted Users" option in [lib/tabs/admin_tabs/users/sort_users_button.dart](lib/tabs/admin_tabs/users/sort_users_button.dart) and the `'muted'` entry in `sortByUsers` in [lib/configs/constants.dart](lib/configs/constants.dart).
- Enforcement: [firestore.rules](firestore.rules) — `isMuted()` reads the user doc, returns true when `'muted_until' in userDoc && userDoc.muted_until > request.time`. Comments `create` requires `!isMuted()`; `update` / `delete` remain open to signed-in users.
- Mobile app side: [tfn-app/lib/models/user_model.dart](../tfn-app/lib/models/user_model.dart) parses `muted_until` into `mutedUntil` and both `Comments` and `EventCommentsSection` check it before posting.
- No automated expiry yet — muted users become un-muted by an admin clicking Unmute, or simply by the `request.time > muted_until` check passing once the timer elapses (the field stays on the doc, but rule allows writes again).

### Users And Authors

- Main files:
  - `lib/tabs/admin_tabs/users/users.dart`
  - `lib/forms/create_author_form.dart`
  - `lib/mixins/user_mixin.dart`
- Behavior:
  - Admins can inspect users, disable access, and assign author roles.
  - `AuthService.createAuthor` creates credentials separately from the current admin session.

### Notifications

- Main files:
  - `lib/tabs/admin_tabs/notifications.dart`
  - `lib/forms/notification_form.dart`
  - `lib/services/notification_service.dart`
- Behavior:
  - Admin-triggered push notification authoring.
  - Custom or article-linked notification delivery via FCM topic messaging.

### Purchases, Ads, And Settings

- Main files:
  - `lib/tabs/admin_tabs/purchases/`
  - `lib/tabs/admin_tabs/ads_settings.dart`
  - `lib/tabs/admin_tabs/app_settings/`
- Behavior:
  - Purchases surface premium subscription history.
  - Ads settings feed directly into the mobile app ad behavior.
  - App settings control content visibility, onboarding, layout, social links, and monetization flags.

### License Verification

- Main file:
  - `lib/tabs/admin_tabs/license_tab.dart`
- Behavior:
  - License state is checked during splash and gates admin access.

## Reusable UI And Logic Layers

### Components

- `lib/components/`
  - Shared inputs and widgets for forms and layout.
  - Examples: dropdowns, dialog helpers, switches, buttons, HTML body rendering, side menu.

### Mixins

- `lib/mixins/`
  - Reusable UI logic rather than inheritance-heavy domain modeling.
  - Important examples:
    - `article_mixin.dart` for list rendering and article actions.
    - `user_mixin.dart` for permission and user utility logic.
    - `appbar_mixin.dart` for common app bar behavior.

### Models

- `lib/models/`
  - Firestore-facing data models such as `Article`, `Event`, `Category`, `Tag`, `UserModel`, `NotificationModel`, and `AppSettingsModel`.
  - If a field changes in Firestore, these model classes are one of the first places to update.

## Important Data Flows

### Admin sign-in flow

1. Firebase Auth login.
2. Firestore role lookup in `AuthService.checkUserRole`.
3. License validation through app settings.
4. User model load.
5. Home shell render with role-specific tabs.

### Article publish flow

1. User opens `ArticleForm`.
2. Form gathers metadata, category, tags, content body, pricing, and thumbnail.
3. Optional thumbnail upload goes through `FirebaseService.uploadImageToFirebaseHosting`.
4. Article is saved to Firestore through `FirebaseService.saveArticle`.
5. Optional notification is sent through `NotificationService.sendPostNotificationToAll`.
6. Dashboard and list queries reflect new state via Firestore-backed providers.

### App settings propagation flow

1. Admin changes settings in `app_settings` or ad settings UI.
2. Settings are saved through `FirebaseService`.
3. Mobile app loads these settings through its own `appSettingsProvider` on splash.
4. Home layout, onboarding, ads, and content presentation change accordingly.

## Where To Modify Common Behaviors

### Change login gating or admin routing

- Start with `lib/pages/splash.dart`.
- Then inspect `lib/services/auth_service.dart` and `lib/providers/auth_state_provider.dart`.

### Change sidebar items or tab order

- Start with `lib/configs/constants.dart` and `lib/pages/home.dart`.
- Then inspect `lib/components/side_menu.dart`.

### Change article editing or publishing behavior

- Start with `lib/forms/article_form.dart`.
- Then inspect `lib/services/firebase_service.dart`, `lib/services/notification_service.dart`, and `lib/models/article.dart`.

### Change app settings fields that affect the mobile app

- Start with `lib/tabs/admin_tabs/app_settings/`.
- Then inspect `lib/tabs/admin_tabs/app_settings/app_setting_providers.dart` and `lib/models/app_settings_model.dart`.

### Change user permissions or author capabilities

- Start with `lib/services/auth_service.dart`, `lib/mixins/user_mixin.dart`, and `lib/tabs/admin_tabs/users/`.

## Folder Guide

- `lib/pages/`: app shell and auth routing pages.
- `lib/components/`: shared widgets.
- `lib/forms/`: create and edit surfaces.
- `lib/providers/`: small Riverpod state units.
- `lib/services/`: Firebase, auth, and notification logic.
- `lib/tabs/admin_tabs/`: admin-facing functional modules.
- `lib/tabs/author_tabs/`: author-facing reduced module set.
- `lib/models/`: Firestore/domain models.
- `lib/utils/`: navigation, responsiveness, toasts, and helpers.

## Practical Notes For Future Changes

- The project name in code is still `news_admin`, so package imports use that namespace.
- Most screens read Firestore directly through `FirebaseService` rather than a repository layer.
- Role and license checks are centralized early in startup, which makes `SplashScreen` a high-impact file.
- Admin settings act as the control plane for the mobile app, especially features, onboarding, and ads.
