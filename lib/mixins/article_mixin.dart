import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:news_admin/tabs/admin_tabs/articles/article_preview/article_preview.dart';
import 'package:news_admin/tabs/admin_tabs/comments/article_comments_reply.dart';
import 'package:news_admin/utils/reponsive.dart';
import '../configs/constants.dart';
import '../forms/article_form.dart';
import '../mixins/user_mixin.dart';
import '../models/article.dart';
import '../utils/custom_cache_image.dart';
import '../utils/empty_with_image.dart';
import '../utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../providers/user_data_provider.dart';
import '../services/firebase_service.dart';
import '../tabs/admin_tabs/dashboard/dashboard_providers.dart';
import '../components/custom_buttons.dart';
import '../components/dialogs.dart';

mixin ArticleMixin {
  Widget buildArticles(
    BuildContext context, {
    required WidgetRef ref,
    required queryProvider,
    bool isFeaturedPosts = false,
    bool isAuthorTab = false,
  }) {
    return FirestoreQueryBuilder(
      query: ref.watch(queryProvider),
      pageSize: 10,
      builder: (context, snapshot, _) {
        if (snapshot.isFetching) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong! ${snapshot.error}'));
        }

        if (snapshot.docs.isEmpty) {
          return const EmptyPageWithImage(title: 'No articles found');
        }
        return _articleList(context, snapshot: snapshot, isFeaturedPosts: isFeaturedPosts, isAuthorTab: isAuthorTab, ref: ref);
      },
    );
  }

  Widget _articleList(
    BuildContext context, {
    required FirestoreQueryBuilderSnapshot snapshot,
    required bool isFeaturedPosts,
    required bool isAuthorTab,
    required WidgetRef ref,
  }) {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.all(30),
        itemCount: snapshot.docs.length,
        shrinkWrap: true,
        separatorBuilder: (context, index) => const Divider(height: 50),
        itemBuilder: (BuildContext listContext, int index) {
          if (snapshot.hasMore && index + 1 == snapshot.docs.length) {
            snapshot.fetchMore();
          }
          final List<Article> articles = snapshot.docs.map((e) => Article.fromFirestore(e)).toList();
          final Article article = articles[index];
          return _buildListItem(context, article, isFeaturedPosts, isAuthorTab, ref);
        },
      ),
    );
  }

  Row _buildListItem(BuildContext context, Article article, bool isFeaturedPosts, bool isAuthorTab, WidgetRef ref) {
    final double leadingImageSize = !Responsive.isMobile(context) ? 100 : 50;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          height: leadingImageSize,
          width: leadingImageSize,
          child: Stack(
            children: [
              CustomCacheImage(
                imageUrl: article.thumbnailUrl.toString(),
                radius: 3,
              ),
              _mediaIcon(article),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  _buildStatus(context, article),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Text(
                      '${priceStatus[article.priceStatus]}',
                      style: const TextStyle(color: Colors.blueAccent),
                    ),
                    const SizedBox(width: 10),
                    Text('By ${article.author!.name}'),
                  ],
                ),
              ),
              Wrap(
                runSpacing: 10,
                children: [
                  Chip(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                    backgroundColor: Theme.of(context).primaryColor,
                    label: Text(
                      article.category?.name ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Chip(
                    label: Text(article.views.toString()),
                    avatar: const Icon(Icons.remove_red_eye, size: 18, color: Colors.grey),
                    labelPadding: const EdgeInsets.only(right: 6),
                  ),
                  const SizedBox(width: 10),
                  Chip(
                    label: Text(article.likes.toString()),
                    avatar: const Icon(Icons.thumb_up, size: 18, color: Colors.grey),
                    labelPadding: const EdgeInsets.only(right: 6),
                  ),
                  const SizedBox(width: 10),
                  ActionChip(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    label: const Text(
                      'Comments',
                      style: TextStyle(color: Colors.blue),
                    ),
                    avatar: const Icon(LineIcons.comment, size: 18, color: Colors.blue),
                    labelPadding: const EdgeInsets.only(left: 0, right: 5),
                    onPressed: () => CustomDialogs.openResponsiveDialog(
                      context,
                      widget: ArticleCommentsAndReply(article: article),
                      horizontalPaddingPercentage: 0.10,
                      verticalPaddingPercentage: 0.03,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _articleMenuButtons(article, isFeaturedPosts, isAuthorTab, context, ref),
      ],
    );
  }

  Widget _mediaIcon(Article article) {
    if (article.contentType == contentTypes.keys.elementAt(1)) {
      // Video
      return const Align(
        alignment: Alignment.center,
        child: Icon(LineIcons.play, color: Colors.white),
      );
    } else if (article.contentType == contentTypes.keys.elementAt(2)) {
      // Audio
      return const Align(
        alignment: Alignment.center,
        child: Icon(LineIcons.audioFile, color: Colors.white),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Container _buildStatus(BuildContext context, Article article) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: _getStatusColor(article.status)),
      child: Text(
        '${articleStatus[article.status]}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 12),
      ),
    );
  }

  static Color _getStatusColor(String status) {
    //draft
    if (status == articleStatus.keys.elementAt(0)) {
      return Colors.grey.shade500;

      //pending
    } else if (status == articleStatus.keys.elementAt(1)) {
      return Colors.blueAccent;

      //live
    } else if (status == articleStatus.keys.elementAt(2)) {
      return Colors.orangeAccent;

      //archived
    } else {
      return Colors.redAccent;
    }
  }

  String setArticleStatus({
    required Article? article,
    required bool? isAuthorTab,
    required bool isDraft,
  }) {
    if (isDraft) {
      //draft
      return articleStatus.keys.elementAt(0);
    } else {
      if (article != null && article.status == articleStatus.keys.elementAt(2)) {
        //if the article is already live then it stays live
        return articleStatus.keys.elementAt(2);
      } else {
        if (isAuthorTab != null && isAuthorTab == true) {
          //pending
          return articleStatus.keys.elementAt(1);
        } else {
          //live
          return articleStatus.keys.elementAt(2);
        }
      }
    }
  }

  Wrap _articleMenuButtons(Article article, bool isFeaturedPosts, bool isAuthorTab, BuildContext context, WidgetRef ref) {
    return Wrap(
      children: [
        Visibility(
          //only for live articles and not featured tabs and author articles
          visible: article.status == articleStatus.keys.elementAt(2) && !isFeaturedPosts && !isAuthorTab,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CustomButtons.circleButton(
              context,
              icon: Icons.add,
              tooltip: 'Add to featured',
              onPressed: () => _onAddToFeatured(context, article, ref),
            ),
          ),
        ),
        CustomButtons.circleButton(
          context,
          icon: Icons.remove_red_eye,
          tooltip: 'Preview',
          onPressed: () => _onPreview(context, article),
        ),
        const SizedBox(width: 8),
        Visibility(
          //not for featured posts and can edit only the author of that article
          visible: !isFeaturedPosts,
          child: CustomButtons.circleButton(
            context,
            icon: Icons.edit,
            tooltip: 'Edit',
            onPressed: () => _onEdit(context, article, isAuthorTab, ref),
          ),
        ),
        const SizedBox(width: 8),
        Visibility(visible: !isFeaturedPosts, child: _menuButton(context, article, ref)),
        Visibility(
          //only for featured posts
          visible: isFeaturedPosts,
          child: CustomButtons.circleButton(
            context,
            icon: Icons.close,
            tooltip: 'Remove',
            onPressed: () => _onRemoveFeaturedPost(context, article, ref),
          ),
        ),
      ],
    );
  }

  PopupMenuButton _menuButton(BuildContext context, Article article, WidgetRef ref) {
    return PopupMenuButton(
      child: const CircleAvatar(
        radius: 16,
        child: Icon(
          Icons.menu,
          size: 16,
        ),
      ),
      itemBuilder: (popupContext) {
        return [
          PopupMenuItem(
            enabled: (article.status == articleStatus.keys.elementAt(2) || article.status == articleStatus.keys.elementAt(3)) &&
                UserMixin.hasAdminAccess(ref.watch(userDataProvider)),
            child: Text(article.status == articleStatus.keys.elementAt(3) ? 'Publish Article' : 'Archive Article'),
            onTap: () => _handleArchiveArticle(article),
          ),
          PopupMenuItem(
            enabled: article.status == articleStatus.keys.elementAt(1) && UserMixin.hasAdminAccess(ref.watch(userDataProvider)),
            child: const Text('Approve Article'),
            onTap: () => _handleArticleApproval(article),
          ),
          PopupMenuItem(
              enabled: UserMixin.isAuthor(ref.watch(userDataProvider), article),
              child: const Text('Delete Article'),
              onTap: () => _onDelete(context, article, ref)),
        ];
      },
    );
  }

  void _handleArchiveArticle(Article article) async {
    if (article.status == articleStatus.keys.elementAt(3)) {
      article.status = articleStatus.keys.elementAt(2);
    } else {
      article.status = articleStatus.keys.elementAt(3);
    }
    await FirebaseService().saveArticle(article);
  }

  void _handleArticleApproval(Article article) async {
    article.status = articleStatus.keys.elementAt(2);
    await FirebaseService().saveArticle(article);
  }

  void _onRemoveFeaturedPost(context, Article article, WidgetRef ref) async {
    final btnController = RoundedLoadingButtonController();
    CustomDialogs.openActionDialog(
      context,
      title: 'Remove From Feature Post?',
      message: 'Do you want to remove this article from the featured list?',
      actionButtonText: 'Yes, Remove',
      onAction: () async {
        if (UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
          btnController.start();
          await FirebaseService().updateFeaturedArticle(article, false);
          btnController.success();

          if (!context.mounted) return;
          Navigator.pop(context);
          openSuccessToast(context, 'Removed Successfully!');
        } else {
          openTestingToast(context);
        }
      },
      actionBtnController: btnController,
    );
  }

  void _onAddToFeatured(context, Article article, WidgetRef ref) async {
    final addBtnController = RoundedLoadingButtonController();
    CustomDialogs.openActionDialog(
      context,
      title: 'Assign As A Feature Post?',
      message: 'Do you want to assign this as a featured post?',
      actionButtonText: 'Add',
      onAction: () async {
        if (UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
          if (article.isFeatured == false) {
            addBtnController.start();
            await FirebaseService().updateFeaturedArticle(article, true);
            addBtnController.success();

            if (!context.mounted) return;
            Navigator.pop(context);
            openSuccessToast(context, 'Added Successfully!');
          } else {
            openToast(context, 'Already added!');
          }
        } else {
          openTestingToast(context);
        }
      },
      actionBtnController: addBtnController,
    );
  }

  void _onDelete(context, Article article, WidgetRef ref) async {
    final deleteBtnController = RoundedLoadingButtonController();
    CustomDialogs.openActionDialog(
      context,
      actionBtnController: deleteBtnController,
      title: 'Delete this this?',
      message: 'Warning: All of the data releated to this article will be deleted and this can not be undone!',
      onAction: () async {
        final user = ref.read(userDataProvider);
        if (UserMixin.isAuthor(user, article) || UserMixin.hasAdminAccess(user)) {
          deleteBtnController.start();
          await FirebaseService().deleteContent('articles', article.id);
          ref.invalidate(articlesCountProvider);
          deleteBtnController.success();

          if (!context.mounted) return;
          Navigator.pop(context);
          CustomDialogs.openInfoDialog(context, 'Deleted Successfully!', '');
        } else {
          openTestingToast(context);
        }
      },
    );
  }

  void _onEdit(BuildContext context, Article article, bool isAuthorTab, WidgetRef ref) {
    if (UserMixin.hasAccess(ref.read(userDataProvider))) {
      CustomDialogs.openFullScreenDialog(context, widget: ArticleForm(article: article, isAuthorTab: isAuthorTab));
    } else {
      openFailureToast(context, 'Only Admin and Author can edit their own article');
    }
  }

  void _onPreview(BuildContext context, Article article) {
    CustomDialogs.openResponsiveDialog(context, widget: ArticlePreview(article: article), verticalPaddingPercentage: 0.02);
  }
}
