import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import '../../mixins/article_mixin.dart';
import '../../utils/reponsive.dart';
import '../../providers/user_data_provider.dart';
import '../../services/firebase_service.dart';
import '../admin_tabs/dashboard/dashboard_tile.dart';

final authorArticlesCountProvider = FutureProvider<int>((ref) async {
  final user = ref.read(userDataProvider);
  final int count = await FirebaseService().getTotalAuthorArticlesCount(user!.id);
  return count;
});

final authorLiveArticlesCountProvider = FutureProvider<int>((ref) async {
  final user = ref.read(userDataProvider);
  final int count = await FirebaseService().getLiveAuthorArticlesCount(user!.id);
  return count;
});

final authorPendingArticlesCountProvider = FutureProvider<int>((ref) async {
  final user = ref.read(userDataProvider);
  final int count = await FirebaseService().getPendingAuthorArticlesCount(user!.id);
  return count;
});

final authorCommentsCountProvider = FutureProvider<int>((ref) async {
  final user = ref.read(userDataProvider);
  final int count = await FirebaseService().getAuthorCommentsCount(user!.id);
  return count;
});

class AuthorDashboard extends ConsumerWidget with ArticleMixin {
  const AuthorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: () async => await ref.refresh(userDataProvider),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                crossAxisCount: Responsive.getCrossAxisCount(context),
                childAspectRatio: 2.5,
              ),
              children: [
                DashboardTile(info: 'Total Articles', count: ref.watch(authorArticlesCountProvider).value ?? 0, icon: LineIcons.list),
                DashboardTile(info: 'Pending Articles', count: ref.watch(authorPendingArticlesCountProvider).value ?? 0, icon: LineIcons.list),
                DashboardTile(info: 'Live Articles', count: ref.watch(authorLiveArticlesCountProvider).value ?? 0, icon: LineIcons.list),
                DashboardTile(info: 'Total Comments', count: ref.watch(authorCommentsCountProvider).value ?? 0, icon: LineIcons.comment),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
