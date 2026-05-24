import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../components/side_menu.dart';
import '../../../mixins/user_mixin.dart';
import '../../../models/comment.dart';
import '../../../services/firebase_service.dart';
import '../../../pages/home.dart';

final dashboardCommentsProvider = FutureProvider<List<Comment>>((ref) async {
  final List<Comment> comments = await FirebaseService().getLatestComments(4);
  return comments;
});

class DashboardComments extends ConsumerWidget {
  const DashboardComments({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(dashboardCommentsProvider);
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.grey.shade300,
        )
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest Comments',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                  onPressed: () {
                    ref.read(menuIndexProvider.notifier).update((state) => 5);
                    ref.read(pageControllerProvider.notifier).state.jumpToPage(5);
                  },
                  child: const Text('View All'))
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: comments.when(
              skipError: true,
              data: (data) {
                return Column(
                  children: data.map((comment) {
                    return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 3),
                        leading: UserMixin.getUserImageByUrl(imageUrl: comment.commentUser.imageUrl),
                        title: Text(
                          comment.commentUser.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.comment,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ));
                  }).toList(),
                );
              },
              error: (a, b) => Container(),
              loading: () => Container(),
            ),
          )
        ],
      ),
    );
  }
}
