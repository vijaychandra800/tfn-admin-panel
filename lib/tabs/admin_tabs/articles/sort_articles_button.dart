import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../configs/constants.dart';
import '/../utils/reponsive.dart';
import '/../models/user_model.dart';
import '../../../models/category.dart';
import '../../../services/firebase_service.dart';
import 'articles.dart';

final CollectionReference colRef = FirebaseFirestore.instance.collection('articles');

class SortArticlesButton extends StatelessWidget {
  const SortArticlesButton({
    super.key,
    required this.ref,
  });

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final sortText = ref.watch(sortByArticleTextProvider);
    return PopupMenuButton(
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.only(left: 15, right: 15),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(25)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.sort_down,
              color: Colors.grey[800],
            ),
            Visibility(
              visible: Responsive.isMobile(context) ? false : true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    'Sort By - $sortText',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  const Icon(Icons.keyboard_arrow_down)
                ],
              ),
            )
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        return sortByArticle.entries.map((e) {
          return PopupMenuItem(
            value: e.key,
            child: Text(e.value),
          );
        }).toList();
      },
      onSelected: (dynamic value) {
        ref.read(sortByArticleTextProvider.notifier).update((state) => sortByArticle[value].toString());

        if (value == 'all') {
          final newQuery = colRef.orderBy('created_at', descending: true);
          ref.read(articleQueryprovider.notifier).update((state) => newQuery);
        }
        if (articleStatus.containsKey(value)) {
          final newQuery = colRef.where('status', isEqualTo: value);
          ref.read(articleQueryprovider.notifier).update((state) => newQuery);
        }
        if (value == 'featured') {
          final newQuery = colRef.where('featured', isEqualTo: true);
          ref.read(articleQueryprovider.notifier).update((state) => newQuery);
        }
        if (value == 'new') {
          final newQuery = colRef.orderBy('created_at', descending: true);
          ref.read(articleQueryprovider.notifier).update((state) => newQuery);
        }
        if (value == 'old') {
          final newQuery = colRef.orderBy('created_at', descending: false);
          ref.read(articleQueryprovider.notifier).update((state) => newQuery);
        }
        if (value == 'free' || value == 'premium') {
          final newQuery = colRef.where('price_status', isEqualTo: value);
          ref.read(articleQueryprovider.notifier).update((state) => newQuery);
        }
        if (value == 'popular') {
          final newQuery = colRef.orderBy('views', descending: true);
          ref.read(articleQueryprovider.notifier).update((state) => newQuery);
        }
        if (value == 'liked') {
          final newQuery = colRef.orderBy('likes', descending: true);
          ref.read(articleQueryprovider.notifier).update((state) => newQuery);
        }
        if (value == 'category') {
          _openCategoryDialog(context, ref);
        }
        if (value == 'author') {
          _openAuthorDialog(context, ref);
        }
      },
    );
  }

  _openAuthorDialog(BuildContext context, WidgetRef ref) async {
    await FirebaseService().getAuthors().then((List<UserModel> authors) {
      if (!context.mounted) return;
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Select Author'),
              content: SizedBox(
                height: 300,
                width: 300,
                child: ListView.separated(
                  itemCount: authors.length,
                  shrinkWrap: true,
                  separatorBuilder: (BuildContext context, int index) => const Divider(),
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      contentPadding: const EdgeInsets.all(0),
                      title: Text('${index + 1}. ${authors[index].name}'),
                      subtitle: Text(authors[index].email),
                      onTap: () {
                        ref.read(sortByArticleTextProvider.notifier).update((state) => authors[index].name);
                        final newQuery = colRef.where('author.id', isEqualTo: authors[index].id);
                        ref.read(articleQueryprovider.notifier).update((state) => newQuery);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            );
          });
    });
  }

  _openCategoryDialog(BuildContext context, WidgetRef ref) async {
    await FirebaseService().getCategories().then((List<Category> cList) {
      if (!context.mounted) return;
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Select Category'),
              content: SizedBox(
                height: 300,
                width: 300,
                child: ListView.separated(
                  itemCount: cList.length,
                  shrinkWrap: true,
                  separatorBuilder: (BuildContext context, int index) => const Divider(),
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      contentPadding: const EdgeInsets.all(0),
                      title: Text('${index + 1}. ${cList[index].name}'),
                      onTap: () {
                        ref.read(sortByArticleTextProvider.notifier).update((state) => cList[index].name);
                        final newQuery = colRef.where('category.id', isEqualTo: cList[index].id);
                        ref.read(articleQueryprovider.notifier).update((state) => newQuery);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            );
          });
    });
  }
}
