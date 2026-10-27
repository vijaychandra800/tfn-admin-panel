---
applyTo: "lib/models/**"
---

# Firestore model conventions

Models are hand-written Firestore mappers. There is no code generation — do not introduce
`json_serializable` or `freezed` here.

## Required shape

```dart
class Thing {
  final String id;
  final String? coverUrl;

  Thing({required this.id, this.coverUrl});

  factory Thing.fromFirebase(DocumentSnapshot snap) {
    final d = snap.data() as Map<String, dynamic>;
    return Thing(
      id: snap.id,
      coverUrl: d['cover_url'],
    );
  }

  static Map<String, dynamic> getMap(Thing d) => {
        'cover_url': d.coverUrl,
      };
}
```

- `factory X.fromFirebase(DocumentSnapshot)` for documents.
- `factory X.fromFirestore(Map<String, dynamic>)` for **nested** maps (e.g. `Subscription`,
  `CommentUser`).
- `static Map<String, dynamic> getMap(X)` for writes. Keep it symmetric with the factory.
- Nested models compose: `CommentUser.fromFirebase(d['user'])` / `CommentUser.getMap(d.user)`.

## Naming

Firestore fields are **`snake_case`**; Dart fields are **`camelCase`**. Never let a
`snake_case` name leak into a Dart identifier, or vice versa.

## Adding a field — the rules that prevent outages

1. **New fields must be nullable or defaulted.** Existing documents will not have them, and
   `fromFirebase` runs against unmigrated data.
2. **Renaming is additive.** Keep writing the legacy field as a mirror and make reads fall
   back to it, as the comments collection does with `target_*` / `article_*`. This avoids a
   backfill and keeps existing composite indexes valid.
3. **Mirror the change in the other repo.** `tfn-app` and `tfn_admin-panel` each keep their
   own copy of the shared models (`UserModel`, `Article`, `Event`, `Comment`,
   `AppSettingsModel`, …). Changing one without the other produces a silent runtime
   mismatch. Call out the counterpart file explicitly when you change a shared model.
4. **Server-owned fields are read-only here.** Counters maintained by Cloud Functions must
   never appear in a client `getMap()` write path.
5. **Timestamps:** store as Firestore `Timestamp`, expose as Dart `DateTime?` via
   `(d['field'] as Timestamp?)?.toDate()`.
