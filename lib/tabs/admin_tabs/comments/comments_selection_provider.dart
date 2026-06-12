import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True when the admin Comments tab is in bulk-selection mode.
final commentsSelectionModeProvider = StateProvider<bool>((ref) => false);

/// IDs of currently-selected comments in the admin Comments tab.
final commentsSelectedIdsProvider =
    StateProvider<Set<String>>((ref) => <String>{});
