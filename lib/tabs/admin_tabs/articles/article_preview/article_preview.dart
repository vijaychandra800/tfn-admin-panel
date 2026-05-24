import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_admin/services/app_service.dart';
import 'package:news_admin/tabs/admin_tabs/articles/article_preview/article_description.dart';
import 'package:news_admin/tabs/admin_tabs/articles/article_preview/article_media_button.dart';
import 'package:news_admin/tabs/admin_tabs/articles/article_preview/article_tags.dart';
import '../../../../models/article.dart';
import '../../../../utils/custom_cache_image.dart';
import '/../../utils/reponsive.dart';

class ArticlePreview extends ConsumerWidget {
  const ArticlePreview({super.key, required this.article});
  final Article article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: const Text('Article Preview'),
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 20 : 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: ClipRRect(
                    child: CustomCacheImage(imageUrl: article.thumbnailUrl.toString(), radius: 5),
                  ),
                ),
                ArticleMediaButton(article: article),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Chip(
                  padding: const EdgeInsets.all(10),
                  elevation: 0,
                  label: Text(
                    article.category?.name ?? '',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                
                
                Visibility(
                  visible: article.sourceUrl?.isNotEmpty ?? false,
                  child: ActionChip(
                    onPressed: () => AppService().openLink(context, article.sourceUrl.toString()),
                    padding: const EdgeInsets.all(10),
                    elevation: 0,
                    label: const Text(
                      'Source URL',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(article.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
            Visibility(
              visible: article.summary?.isNotEmpty ?? false,
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      const VerticalDivider(),
                      Expanded(
                          child: Text(
                        article.summary.toString(),
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      )),
                    ],
                  ),
                ),
              ),
            ),
            ArticleDescription(article: article),
            ArticleTags(article: article),
          ],
        ),
      ),
    );
  }
}
