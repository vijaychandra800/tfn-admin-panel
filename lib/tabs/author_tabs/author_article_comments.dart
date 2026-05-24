import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../mixins/appbar_mixin.dart';
import '../../mixins/comment_mixin.dart';
import '../../mixins/user_mixin.dart';
import '../../services/firebase_service.dart';

import '../../providers/user_data_provider.dart';

final authorArticleCommentsQueryprovider = StateProvider<Query>((ref) {
  final user = ref.read(userDataProvider);
  final query = FirebaseService.authorArticleCommentsQuery(user!.id);
  return query;
});

class AuthorArticleComments extends ConsumerWidget with CommentMixin, UserMixin{
  const AuthorArticleComments({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AppBarMixin.buildTitleBar(context, title: 'All Comments', buttons: [
            // sortButton(context, ref: ref),
          ]),
          buildComments(context, ref: ref, isAuthorArticles: true, queryProvider: authorArticleCommentsQueryprovider),
        ],
      ),
    );
  }
}
