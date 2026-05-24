import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../mixins/appbar_mixin.dart';
import '../../mixins/article_mixin.dart';

final featuredArticlesQueryprovider = StateProvider<Query>((ref) {
  final query = FirebaseFirestore.instance.collection('articles').where('featured', isEqualTo: true);
  return query;
});

class FeaturedArticles extends ConsumerWidget with ArticleMixin {
  const FeaturedArticles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AppBarMixin.buildTitleBar(context, title: 'Featured Articles', buttons: []),
          buildArticles(context, ref: ref, isFeaturedPosts: true, queryProvider: featuredArticlesQueryprovider)
        ],
      ),
    );
  }
}
