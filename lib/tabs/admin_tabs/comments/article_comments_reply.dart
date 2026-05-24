import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_admin/mixins/comment_mixin.dart';
import 'package:news_admin/mixins/textfields.dart';
import 'package:news_admin/mixins/user_mixin.dart';
import 'package:news_admin/models/article.dart';
import 'package:news_admin/tabs/admin_tabs/dashboard/dashboard_providers.dart';
import 'package:news_admin/utils/toasts.dart';
import '../../../models/comment.dart';
import '../../../models/comment_user.dart';
import '../../../providers/user_data_provider.dart';
import '../../../services/firebase_service.dart';

final articleCommentsQueryprovider = StateProvider.family.autoDispose<Query, Article>((ref, article) {
  final query = FirebaseService.articleCommentsQuery(article);
  return query;
});

class ArticleCommentsAndReply extends ConsumerWidget with TextFields, CommentMixin {
  const ArticleCommentsAndReply({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    return Scaffold(
        appBar: AppBar(
          elevation: 0.5,
          centerTitle: false,
          titleSpacing: 20,
          toolbarHeight: 65,
          backgroundColor: Theme.of(context).primaryColor,
          leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comments',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
              ),
              Text(
                article.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        bottomNavigationBar: commentTextField(context, controller: textController, onSubmitted: () => _onSubmitted(context, ref, textController)),
        body: Column(
          children: [
            buildComments(
              context,
              isAuthorArticles: false,
              queryProvider: articleCommentsQueryprovider(article),
              ref: ref,
              isSingleArticle: true,
            ),
          ],
        ));
  }

  _onSubmitted(context, ref, textController) async {
    final user = ref.read(userDataProvider);

    if (UserMixin.hasAccess(user)) {
      if (textController.text.isNotEmpty) {
        final String id = FirebaseService.getUID('comments');
        final createdAt = DateTime.now();

        final commentUser = CommentUser(id: user!.id, name: user.name, imageUrl: user.imageUrl);
        final Comment comment = Comment(
          id: id,
          articleId: article.id,
          articleAuthorId: user.id,
          articleTitle: article.title,
          commentUser: commentUser,
          createdAt: createdAt,
          comment: textController.text,
        );

        await FirebaseService().saveComment(comment);
        textController.clear();
        ref.invalidate(commnetsCountProvider);
        openToast(context, 'Added Successfully');
      } else {
        openFailureToast(context, "Comment can't be empty");
      }
    } else {
      openTestingToast(context);
    }
  }
}
