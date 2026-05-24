import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../configs/constants.dart';
import '../../../utils/reponsive.dart';
import 'comments.dart';

final CollectionReference colRef = FirebaseFirestore.instance.collection('comments');

class SortCommentsButton extends StatelessWidget {
  const SortCommentsButton({super.key, required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final String sortText = ref.watch(sortByCommentTextProvider);
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
        return sortByComments.entries.map((e) {
          return PopupMenuItem(
            value: e.key,
            child: Text(e.value),
          );
        }).toList();
      },
      onSelected: (dynamic value) {
        ref.read(sortByCommentTextProvider.notifier).update((state) => sortByComments[value].toString());
        final notifier = ref.read(commentsQueryprovider.notifier);

        if (value == 'all') {
          final newQuery = colRef.orderBy('created_at', descending: true);
          notifier.update((state) => newQuery);
        }
        if (value == 'new') {
          final newQuery = colRef.orderBy('created_at', descending: true);
          notifier.update((state) => newQuery);
        }
        if (value == 'old') {
          final newQuery = colRef.orderBy('created_at', descending: false);
          notifier.update((state) => newQuery);
        }
      },
    );
  }
}
