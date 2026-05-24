import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../configs/constants.dart';
import '/../mixins/appbar_mixin.dart';
import '../../../mixins/article_mixin.dart';
import '/../components/custom_buttons.dart';
import 'sort_articles_button.dart';
import '../../../components/dialogs.dart';
import '../../../forms/article_form.dart';

final articleQueryprovider = StateProvider<Query>((ref) {
  final query = FirebaseFirestore.instance.collection('articles').orderBy('created_at', descending: true);
  return query;
});

final sortByArticleTextProvider = StateProvider<String>((ref) => sortByArticle.entries.first.value);

class Articles extends ConsumerWidget with ArticleMixin {
  const Articles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AppBarMixin.buildTitleBar(context, title: 'All Articles', buttons: [
            CustomButtons.customOutlineButton(
              context,
              icon: Icons.add,
              text: 'Create Article',
              bgColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              onPressed: () {
                CustomDialogs.openFullScreenDialog(context, widget: const ArticleForm(article: null));
              },
            ),
            const SizedBox(width: 10),
            SortArticlesButton(ref: ref),
          ]),
          buildArticles(context, ref: ref, queryProvider: articleQueryprovider)
        ],
      ),
    );
  }
}
