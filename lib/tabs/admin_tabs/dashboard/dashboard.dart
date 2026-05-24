import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import '../../../tabs/admin_tabs/dashboard/purchase_bar_chart.dart';
import '../../../tabs/admin_tabs/dashboard/user_bar_chart.dart';
import '../../../mixins/article_mixin.dart';
import '../../../utils/reponsive.dart';
import 'dashboard_purchases.dart';
import 'dashboard_comments.dart';
import 'dashboard_tile.dart';
import 'dashboard_providers.dart';
import 'dashboard_top_articles.dart';
import 'dashboard_users.dart';

class Dashboard extends ConsumerWidget with ArticleMixin {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
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
              DashboardTile(
                  info: 'Total Users', count: ref.watch(usersCountProvider).value ?? 0, icon: LineIcons.userFriends, bgColor: Colors.orange),
              DashboardTile(
                  info: 'Total Subscribed', count: ref.watch(subscriberCountProvider).value ?? 0, icon: LineIcons.userClock, bgColor: Colors.purple),
              DashboardTile(
                  info: 'Total Purchases', count: ref.watch(purchasesCountProvider).value ?? 0, icon: LineIcons.receipt, bgColor: Colors.cyan),
              DashboardTile(
                  info: 'Total Authors', count: ref.watch(authorsCountProvider).value ?? 0, icon: LineIcons.userTag, bgColor: Colors.pinkAccent),
              DashboardTile(
                info: 'Total Articles',
                count: ref.watch(articlesCountProvider).value ?? 0,
                icon: LineIcons.list,
                bgColor: Colors.green,
              ),
              DashboardTile(
                info: 'Total Upcoming Events',
                count: ref.watch(eventsCountProvider).value ?? 0,
                icon: LineIcons.calendarCheck,
                bgColor: Colors.indigoAccent,
              ),
              DashboardTile(
                info: 'Pending Articles',
                count: ref.watch(pendingArticlesCountProvider).value ?? 0,
                icon: Icons.timer_sharp,
                bgColor: Colors.deepOrange,
              ),
              DashboardTile(
                info: 'Total Notifications',
                count: ref.watch(notificationsCountProvider).value ?? 0,
                icon: LineIcons.bell,
                bgColor: Colors.deepPurple,
              ),
              DashboardTile(
                info: 'Total Comments',
                count: ref.watch(commnetsCountProvider).value ?? 0,
                icon: LineIcons.comment,
                bgColor: Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildOtherTabs(context),
        ],
      ),
    );
  }

  Widget _buildOtherTabs(BuildContext context) {
    if (Responsive.isDesktopLarge(context)) {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
              flex: 1,
              child: Column(
                children: [UserBarChart(), SizedBox(height: 20), DashboardComments()],
              )),
          SizedBox(width: 20),
          Flexible(
              flex: 1,
              child: Column(
                children: [PurchaseBarChart(), SizedBox(height: 20), DashboardUsers()],
              )),
          SizedBox(width: 20),
          Flexible(
              flex: 1,
              child: Column(
                children: [DashboardPurchases(), SizedBox(height: 20), DashboardTopArticles()],
              )),
        ],
      );
    } else if (Responsive.isDesktop(context)) {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
              flex: 1,
              child: Column(
                children: [
                  UserBarChart(),
                  SizedBox(height: 20),
                  DashboardComments(),
                  SizedBox(height: 20),
                  DashboardPurchases(),
                ],
              )),
          SizedBox(width: 20),
          Flexible(
              flex: 1,
              child: Column(
                children: [
                  PurchaseBarChart(),
                  SizedBox(height: 20),
                  DashboardUsers(),
                  SizedBox(height: 20),
                  DashboardTopArticles(),
                ],
              )),
        ],
      );
    } else {
      return const Column(
        children: [
          UserBarChart(),
          SizedBox(height: 20),
          PurchaseBarChart(),
          SizedBox(height: 20),
          DashboardComments(),
          SizedBox(height: 20),
          DashboardPurchases(),
          SizedBox(height: 20),
          DashboardUsers(),
          SizedBox(height: 20),
          DashboardTopArticles(),
        ],
      );
    }
  }
}
