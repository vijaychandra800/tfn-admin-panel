import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/comment.dart';
import '../../../utils/reponsive.dart';
import 'comments.dart';

const Map<String, String> _kCommentTargetFilters = {
  'all': 'All',
  Comment.typeArticle: 'Articles',
  Comment.typeEvent: 'Events',
};

class FilterCommentsByTargetButton extends StatelessWidget {
  const FilterCommentsByTargetButton({super.key, required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(commentsTargetFilterProvider);
    final label = _kCommentTargetFilters[current] ?? 'All';
    return PopupMenuButton<String>(
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.only(left: 15, right: 15),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(25)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.line_horizontal_3_decrease,
                color: Colors.grey[800]),
            Visibility(
              visible: !Responsive.isMobile(context),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Text('Target - $label',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (_) => _kCommentTargetFilters.entries
          .map((e) => PopupMenuItem<String>(value: e.key, child: Text(e.value)))
          .toList(),
      onSelected: (value) {
        ref.read(commentsTargetFilterProvider.notifier).state = value;
        // Changing the target filter clears any per-event filter to avoid
        // contradictory state (e.g. "Articles" + a specific event).
        if (value != Comment.typeEvent) {
          ref.read(commentsEventFilterProvider.notifier).state = null;
        }
        rebuildCommentsQuery(ref);
      },
    );
  }
}
