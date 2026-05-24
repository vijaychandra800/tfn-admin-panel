import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final sortByCommentTextProvider = StateProvider<String>((ref) => sortByComments.entries.first.value);

class Comments extends ConsumerWidget with CommentMixin, UserMixin {
  const Comments({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AppBarMixin.buildTitleBar(context, title: 'All Comments', buttons: [
            SortCommentsButton(ref: ref),
          ]),
          buildComments(context, ref: ref, isAuthorArticles: false, queryProvider: commentsQueryprovider),
        ],
      ),
    );
  }
}
