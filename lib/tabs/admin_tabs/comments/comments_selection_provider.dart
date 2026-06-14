import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True when the admin Comments tab is in bulk-selection mode.
final commentsSelectionModeProvider = StateProvider<bool>((ref) => false);

/// IDs of currently-selected comments in the admin Comments tab.
final commentsSelectedIdsProvider =
    StateProvider<Set<String>>((ref) => <String>{});

/// True when the admin Comments tab is showing the "Muted Users" view
/// instead of the comments list.
final mutedUsersFilterProvider = StateProvider<bool>((ref) => false);

/// IDs of currently-selected muted users in the "Muted Users" view.
final mutedUsersSelectedIdsProvider =
    StateProvider<Set<String>>((ref) => <String>{});

/// Streams whether [userId] is currently muted by an admin.
///
/// A user is considered muted while the `muted_until` field is set. The field
/// is removed entirely on unmute, so its mere presence indicates a mute.
final userMutedProvider = StreamProvider.family<bool, String>((ref, userId) {
  if (userId.isEmpty) return Stream.value(false);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((snap) {
    final data = snap.data();
    return data != null && data['muted_until'] != null;
  });
});
