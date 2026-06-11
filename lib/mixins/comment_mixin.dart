import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_admin/models/comment.dart';
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
        return _commentList(context,
            snapshot: snapshot,
            ref: ref,
            isAuthorArticles: isAuthorArticles,
            isSingleArticle: isSingleArticle);
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
          final List<Comment> comments =
              snapshot.docs.map((e) => Comment.fromFirebase(e)).toList();
          final Comment comment = comments[index];
          return _buildListItem(
              context, comment, ref, isAuthorArticles, isSingleArticle);
        },
      ),
    );
  }

  ListTile _buildListItem(BuildContext context, Comment comment, WidgetRef ref,
      bool isAuthorArticles, bool isSingleArticle) {
    final bool showTarget = !isSingleArticle && comment.targetTitle.isNotEmpty;
    return ListTile(
      minVerticalPadding: 10,
      horizontalTitleGap: 16,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              comment.commentUser.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (showTarget) ...[
            const SizedBox(width: 8),
            _targetBadge(context, comment.targetType),
          ],
        ],
      ),
      leading: UserMixin.getUserImageByUrl(
          imageUrl: comment.commentUser.imageUrl, radius: 40, iconSize: 20),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTarget) ...[
            const SizedBox(height: 4),
            _targetTitleRow(context, comment),
          ],
          const SizedBox(height: 6),
          Text(
            comment.comment,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.blueGrey.shade900),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.time, size: 16),
              const SizedBox(width: 5),
              Text(
                AppService.getDateTime(comment.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
      trailing:
          isAuthorArticles ? null : _moderationActions(context, comment, ref),
    );
  }

  Widget _targetTitleRow(BuildContext context, Comment comment) {
    final isEvent = comment.targetType == Comment.typeEvent;
    final color = isEvent ? Colors.deepPurple : Colors.teal;
    return Row(
      children: [
        Icon(isEvent ? Icons.event : Icons.article_outlined,
            size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            comment.targetTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  Widget _targetBadge(BuildContext context, String targetType) {
    final isEvent = targetType == Comment.typeEvent;
    final color = isEvent ? Colors.deepPurple : Colors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEvent ? Icons.event : Icons.article_outlined,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isEvent ? 'Event' : 'Article',
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _moderationActions(
      BuildContext context, Comment comment, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Delete comment',
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => _onDelete(context, comment, ref),
        ),
        _muteUserButton(context, comment, ref),
      ],
    );
  }

  Widget _muteUserButton(BuildContext context, Comment comment, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'Mute / unmute user',
      position: PopupMenuPosition.under,
      icon: const Icon(Icons.volume_off_outlined, color: Colors.orange),
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Text('Mute ${comment.commentUser.name}',
              style: Theme.of(context).textTheme.bodySmall),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'mute_1d', child: Text('1 day')),
        const PopupMenuItem(value: 'mute_7d', child: Text('7 days')),
        const PopupMenuItem(value: 'mute_30d', child: Text('30 days')),
        const PopupMenuItem(value: 'mute_forever', child: Text('Forever')),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'unmute',
          child: Text('Unmute user'),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'mute_1d':
            _onMute(context, comment, ref, const Duration(days: 1));
            break;
          case 'mute_7d':
            _onMute(context, comment, ref, const Duration(days: 7));
            break;
          case 'mute_30d':
            _onMute(context, comment, ref, const Duration(days: 30));
            break;
          case 'mute_forever':
            _onMute(context, comment, ref, const Duration(days: 365 * 100));
            break;
          case 'unmute':
            _onUnmute(context, comment, ref);
            break;
        }
      },
    );
  }

  void _onMute(
      BuildContext context, Comment comment, WidgetRef ref, Duration d) async {
    if (!UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
      openTestingToast(context);
      return;
    }
    final until = DateTime.now().add(d);
    await FirebaseService().muteUser(comment.commentUser.id, until);
    if (!context.mounted) return;
    openSuccessToast(
        context, 'Muted ${comment.commentUser.name} until ${until.toLocal()}');
  }

  void _onUnmute(BuildContext context, Comment comment, WidgetRef ref) async {
    if (!UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
      openTestingToast(context);
      return;
    }
    await FirebaseService().unmuteUser(comment.commentUser.id);
    if (!context.mounted) return;
    openSuccessToast(context, 'Unmuted ${comment.commentUser.name}');
  }

  void _onDelete(context, Comment comment, WidgetRef ref) async {
    final deleteBtnController = RoundedLoadingButtonController();
    CustomDialogs.openActionDialog(
      context,
      actionBtnController: deleteBtnController,
      title: 'Delete this comment?',
      message:
          'Do you want to delete this user comment?\nWarning: This can not be undone.',
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
