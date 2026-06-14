import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_admin/models/event.dart';
import 'package:news_admin/tabs/admin_tabs/comments/comments_selection_provider.dart';
import 'package:news_admin/tabs/admin_tabs/comments/filter_comments_event.dart';
import 'package:news_admin/tabs/admin_tabs/comments/filter_comments_target.dart';
import 'package:news_admin/tabs/admin_tabs/comments/filter_muted_users.dart';
import 'package:news_admin/tabs/admin_tabs/comments/muted_users_view.dart';
import 'package:news_admin/tabs/admin_tabs/comments/sort_comments.dart';
import '../../../configs/constants.dart';
import '../../../mixins/appbar_mixin.dart';
import '../../../mixins/comment_mixin.dart';
import '../../../mixins/user_mixin.dart';
import '../../../services/firebase_service.dart';

final commentsQueryprovider = StateProvider<Query>((ref) {
  final query = FirebaseService.commentsQuery();
  return query;
});

final sortByCommentTextProvider =
    StateProvider<String>((ref) => sortByComments.entries.first.value);

/// Currently-selected target type filter on the admin Comments tab.
/// `'all'`, `'article'`, or `'event'`.
final commentsTargetFilterProvider = StateProvider<String>((ref) => 'all');

/// Currently-selected event to filter by, or `null` for no event filter.
/// When set, the target filter is implicitly `'event'`.
final commentsEventFilterProvider = StateProvider<Event?>((ref) => null);

/// Rebuilds [commentsQueryprovider] from the currently-selected filter
/// and sort state. Call after any filter / sort change.
void rebuildCommentsQuery(WidgetRef ref) {
  final target = ref.read(commentsTargetFilterProvider);
  final event = ref.read(commentsEventFilterProvider);
  final sortText = ref.read(sortByCommentTextProvider);
  final descending = sortText != sortByComments['old'];

  Query base = FirebaseFirestore.instance.collection('comments');
  if (event != null) {
    base = base
        .where('target_type', isEqualTo: 'event')
        .where('target_id', isEqualTo: event.id);
  } else if (target != 'all') {
    base = base.where('target_type', isEqualTo: target);
  }
  ref.read(commentsQueryprovider.notifier).state =
      base.orderBy('created_at', descending: descending);
}

class Comments extends ConsumerWidget with CommentMixin, UserMixin {
  const Comments({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reset selection whenever the underlying query (filters/sort) changes.
    ref.listen<Query>(commentsQueryprovider, (prev, next) {
      ref.read(commentsSelectionModeProvider.notifier).state = false;
      ref.read(commentsSelectedIdsProvider.notifier).state = <String>{};
    });

    final selectionMode = ref.watch(commentsSelectionModeProvider);
    final selectedCount = ref.watch(commentsSelectedIdsProvider).length;
    final mutedView = ref.watch(mutedUsersFilterProvider);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AppBarMixin.buildTitleBar(context,
              title: mutedView
                  ? 'Muted Users'
                  : (selectionMode
                      ? '$selectedCount selected'
                      : 'All Comments'),
              buttons: [
                if (mutedView) ...[
                  const FilterMutedUsersButton(),
                ] else ...[
                  if (!selectionMode) ...[
                    FilterCommentsByTargetButton(ref: ref),
                    const SizedBox(width: 10),
                    const FilterCommentsByEventButton(),
                    const SizedBox(width: 10),
                    SortCommentsButton(ref: ref),
                    const SizedBox(width: 10),
                    const FilterMutedUsersButton(),
                    const SizedBox(width: 10),
                  ],
                  _selectionToggleButton(context, ref, selectionMode),
                ],
              ]),
          if (mutedView)
            const MutedUsersView()
          else
            buildComments(context,
                ref: ref,
                isAuthorArticles: false,
                selectable: true,
                queryProvider: commentsQueryprovider),
        ],
      ),
    );
  }

  Widget _selectionToggleButton(
      BuildContext context, WidgetRef ref, bool selectionMode) {
    if (selectionMode) {
      return TextButton.icon(
        onPressed: () {
          ref.read(commentsSelectionModeProvider.notifier).state = false;
          ref.read(commentsSelectedIdsProvider.notifier).state = <String>{};
        },
        icon: const Icon(Icons.close, size: 18),
        label: const Text('Cancel'),
      );
    }
    return OutlinedButton.icon(
      onPressed: () {
        ref.read(commentsSelectionModeProvider.notifier).state = true;
      },
      icon: const Icon(Icons.check_box_outlined, size: 18),
      label: const Text('Select'),
    );
  }
}
