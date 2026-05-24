import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../forms/article_form.dart';
import '../../../../models/article.dart';

class ArticleTags extends ConsumerWidget {
  const ArticleTags({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagsProvider);
    return tags.when(
      skipError: true,
      error: (error, stackTrace) => Container(),
      loading: () => Container(),
      data: (data) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: data.where((element) => article.tagIDs!.contains(element.id)).map((e) {
              return Chip(
                padding: const EdgeInsets.all(10),
                elevation: 0,
                label: Text(
                  e.name,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Theme.of(context).primaryColor,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
