# Track Field Network Admin Panel Context

## Purpose

This project is the Flutter web admin surface for Track Field Network. It is used by admins and authors to manage content, users, notifications, purchases, ads, and app settings stored in Firebase.

## Stack Summary

- Flutter with Riverpod for state management.
- Firebase Core, Auth, Firestore, Storage, and Cloud Messaging.
- Web-oriented admin UI with responsive sidebar layout.
- Rich content editing through `html_editor_enhanced`.

## Startup And App Boot Flow

### Entry point

- `lib/main.dart`
  - Initializes Flutter bindings.
  - Enables path URL strategy for web.
  - Initializes Firebase with `firebase_options.dart`.
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
  - `lib/tabs/admin_tabs/comments/`
  - `lib/tabs/author_tabs/author_article_comments.dart`
- Behavior:
  - Admins can moderate globally.
  - Authors have access to comments tied to their own articles.

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