import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../mixins/article_mixin.dart';
import '../../../components/side_menu.dart';
import '../../../models/article.dart';
import '../../../services/firebase_service.dart';
import '../../../configs/constants.dart';
import '../../../pages/home.dart';
import '../../../utils/custom_cache_image.dart';

final dashboardTopArticlesProvider = FutureProvider<List<Article>>((ref) async {
  final List<Article> articles = await FirebaseService().getTopArticles(5);
  return articles;
});

class DashboardTopArticles extends ConsumerWidget with ArticleMixin {
  const DashboardTopArticles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(dashboardTopArticlesProvider);
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
                'Top Articles',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                  onPressed: () {
                    ref.read(menuIndexProvider.notifier).update((state) => 1);
                    ref.read(pageControllerProvider.notifier).state.jumpToPage(1);
                  },
                  child: const Text('View All'))
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 15),
            child: articles.when(
              data: (data) {
                return Column(
                  children: data.map((article) {
                    return ListTile(
                      minVerticalPadding: 20,
                      horizontalTitleGap: 20,
                      contentPadding: const EdgeInsets.all(0),
                      leading: SizedBox(
                        height: 60,
                        width: 60,
                        child: CustomCacheImage(
                          imageUrl: article.thumbnailUrl.toString(),
                          radius: 3,
                        ),
                      ),
                      title: Text(article.title),
                      subtitle: Text('${article.author?.name ?? ''} - ${priceStatus[article.priceStatus]}')
                    );
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
