import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_admin/models/comment.dart';
import '../components/custom_buttons.dart';
import '../mixins/user_mixin.dart';
import '../utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../providers/user_data_provider.dart';
import '../services/app_service.dart';
import '../services/firebase_service.dart';
import '../tabs/admin_tabs/dashboard/dashboard_providers.dart';
import '../utils/empty_with_image.dart';
import '../components/dialogs.dart';

mixin CommentMixin {
  Widget buildComments(
    BuildContext context, {
    required bool isAuthorArticles,
    required queryProvider,
    required WidgetRef ref,
    bool isSingleArticle = false,
  }) {
    return FirestoreQueryBuilder(
      query: ref.watch(queryProvider),
      pageSize: 10,
      builder: (context, snapshot, _) {
        if (snapshot.isFetching) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint(snapshot.error.toString());
          return Center(child: Text('Something went wrong! ${snapshot.error}'));
        }

        if (snapshot.docs.isEmpty) {
          return const EmptyPageWithImage(title: 'No comments found');
        }
        return _commentList(context, snapshot: snapshot, ref: ref, isAuthorArticles: isAuthorArticles, isSingleArticle: isSingleArticle);
      },
    );
  }

  Widget _commentList(
    BuildContext context, {
    required FirestoreQueryBuilderSnapshot snapshot,
    required bool isAuthorArticles,
    required WidgetRef ref,
    required bool isSingleArticle,
  }) {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
        itemCount: snapshot.docs.length,
        shrinkWrap: true,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (BuildContext context, int index) {
          if (snapshot.hasMore && index + 1 == snapshot.docs.length) {
            snapshot.fetchMore();
          }
          final List<Comment> comments = snapshot.docs.map((e) => Comment.fromFirebase(e)).toList();
          final Comment comment = comments[index];
          return _buildListItem(context, comment, ref, isAuthorArticles, isSingleArticle);
        },
      ),
    );
  }

  ListTile _buildListItem(BuildContext context, Comment comment, WidgetRef ref, bool isAuthorArticles, bool isSingleArticle) {
    return ListTile(
      minVerticalPadding: 10,
      horizontalTitleGap: 30,
      title: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: Theme.of(context).textTheme.titleSmall,
          text: comment.commentUser.name,
          children: isSingleArticle
              ? null
              : [
                  const TextSpan(text: '  '),
                  TextSpan(
                    text: comment.articleTitle,
                    style: const TextStyle(color: Colors.blueAccent),
                  ),
                ],
        ),
      ),
      leading: UserMixin.getUserImageByUrl(imageUrl: comment.commentUser.imageUrl, radius: 40, iconSize: 20),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment.comment,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey.shade900),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.time,
                size: 18,
              ),
              const SizedBox(
                width: 5,
              ),
              Text(AppService.getDateTime(comment.createdAt)),
            ],
          ),
        ],
      ),
      trailing: Visibility(
          visible: !isAuthorArticles,
          child: CustomButtons.circleButton(context, icon: Icons.delete, onPressed: () => _onDelete(context, comment, ref))),
    );
  }

  void _onDelete(context, Comment comment, WidgetRef ref) async {
    final deleteBtnController = RoundedLoadingButtonController();
    CustomDialogs.openActionDialog(
      context,
      actionBtnController: deleteBtnController,
      title: 'Delete this comment?',
      message: 'Do you want to delete this user comment?\nWarning: This can not be undone.',
      onAction: () async {
        if (UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
          deleteBtnController.start();
          await FirebaseService().deleteContent('comments', comment.id);
          ref.invalidate(commnetsCountProvider);
          deleteBtnController.success();
          Navigator.pop(context);
          openSuccessToast(context, 'Deleted successfully!');
        } else {
          openTestingToast(context);
        }
      },
    );
  }
}
