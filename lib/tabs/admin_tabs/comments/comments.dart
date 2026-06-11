import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_admin/models/event.dart';
import 'package:news_admin/tabs/admin_tabs/comments/filter_comments_event.dart';
import 'package:news_admin/tabs/admin_tabs/comments/filter_comments_target.dart';
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
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AppBarMixin.buildTitleBar(context, title: 'All Comments', buttons: [
            FilterCommentsByTargetButton(ref: ref),
            const SizedBox(width: 10),
            const FilterCommentsByEventButton(),
            const SizedBox(width: 10),
            SortCommentsButton(ref: ref),
          ]),
          buildComments(context,
              ref: ref,
              isAuthorArticles: false,
              queryProvider: commentsQueryprovider),
        ],
      ),
    );
  }
}
