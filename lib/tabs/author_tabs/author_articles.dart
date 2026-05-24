import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../mixins/appbar_mixin.dart';
import '../../mixins/article_mixin.dart';
import '../../forms/article_form.dart';
import '../../components/custom_buttons.dart';
import '../../components/dialogs.dart';
import '../../providers/user_data_provider.dart';

final authorArticlesQueryprovider = StateProvider.family<Query, String>((ref, authorId) {
  final query = FirebaseFirestore.instance.collection('articles').where('author.id', isEqualTo: authorId);
  return query;
});

class AuthorArticles extends ConsumerWidget with ArticleMixin {
  const AuthorArticles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userDataProvider);
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AppBarMixin.buildTitleBar(context, title: 'My Articles', buttons: [
            CustomButtons.customOutlineButton(
              context,
              icon: Icons.add,
              bgColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              text: 'Create Article',
              onPressed: () {
                CustomDialogs.openFullScreenDialog(
                  context,
                  widget: const ArticleForm(
                    article: null,
                    isAuthorTab: true,
                  ),
                );
              },
            ),
          ]),
          buildArticles(context, ref: ref, isAuthorTab: true, queryProvider: authorArticlesQueryprovider(user!.id)),
        ],
      ),
    );
  }
}
