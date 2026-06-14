import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';

import '../../../components/dialogs.dart';
import '../../../mixins/user_mixin.dart';
import '../../../models/user_model.dart';
import '../../../providers/user_data_provider.dart';
import '../../../services/app_service.dart';
import '../../../services/firebase_service.dart';
import '../../../utils/empty_with_image.dart';
import '../../../utils/toasts.dart';
import 'comments_selection_provider.dart';

/// Lists every user currently muted by an admin and offers per-user and bulk
/// "Unmute" actions, including a "select all on this page" affordance.
class MutedUsersView extends ConsumerWidget {
  const MutedUsersView({super.key});

  static final Query _mutedUsersQuery = FirebaseFirestore.instance
      .collection('users')
      .where('muted_until', isNull: false);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: FirestoreQueryBuilder(
        query: _mutedUsersQuery,
        pageSize: 20,
        builder: (context, snapshot, _) {
          if (snapshot.isFetching) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Something went wrong! ${snapshot.error}'));
          }
          if (snapshot.docs.isEmpty) {
            return const EmptyPageWithImage(title: 'No muted users found');
          }
          return _buildList(context, ref, snapshot);
        },
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    FirestoreQueryBuilderSnapshot snapshot,
  ) {
    final selected = ref.watch(mutedUsersSelectedIdsProvider);
    final loadedIds = snapshot.docs.map((d) => d.id).toSet();
    final bool allSelected =
        loadedIds.isNotEmpty && selected.containsAll(loadedIds);

    return Column(
      children: [
        _selectionToolbar(context, ref,
            snapshot: snapshot,
            selected: selected,
            loadedIds: loadedIds,
            allSelected: allSelected),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
            itemCount: snapshot.docs.length,
            shrinkWrap: true,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              if (snapshot.hasMore && index + 1 == snapshot.docs.length) {
                snapshot.fetchMore();
              }
              final user = UserModel.fromFirebase(snapshot.docs[index]);
              return _userTile(context, ref, user, selected.contains(user.id));
            },
          ),
        ),
      ],
    );
  }

  Widget _selectionToolbar(
    BuildContext context,
    WidgetRef ref, {
    required FirestoreQueryBuilderSnapshot snapshot,
    required Set<String> selected,
    required Set<String> loadedIds,
    required bool allSelected,
  }) {
    return Material(
      color: Colors.red.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Checkbox(
              value: allSelected
                  ? true
                  : (selected.isEmpty ? false : null), // tri-state
              tristate: true,
              onChanged: (_) {
                final next = Set<String>.from(selected);
                if (allSelected) {
                  next.removeAll(loadedIds);
                } else {
                  next.addAll(loadedIds);
                }
                ref.read(mutedUsersSelectedIdsProvider.notifier).state = next;
              },
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                allSelected
                    ? 'All ${loadedIds.length} on this page selected'
                    : (selected.isEmpty
                        ? 'Select all on this page (${loadedIds.length})'
                        : '${selected.length} selected'),
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (snapshot.hasMore)
              TextButton.icon(
                onPressed: snapshot.isFetchingMore ? null : snapshot.fetchMore,
                icon: const Icon(Icons.expand_more, size: 18),
                label: const Text('Load more'),
              ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    Theme.of(context).primaryColor.withValues(alpha: 0.4),
                disabledForegroundColor: Colors.white,
              ),
              onPressed: selected.isEmpty
                  ? null
                  : () => _onBulkUnmute(context, ref, selected.toList()),
              icon: const Icon(Icons.volume_up_outlined, size: 18),
              label: Text('Unmute selected (${selected.length})'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userTile(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    bool isSelected,
  ) {
    void toggleSelected() {
      final selected = ref.read(mutedUsersSelectedIdsProvider);
      final next = Set<String>.from(selected);
      if (next.contains(user.id)) {
        next.remove(user.id);
      } else {
        next.add(user.id);
      }
      ref.read(mutedUsersSelectedIdsProvider.notifier).state = next;
    }

    return ListTile(
      minVerticalPadding: 10,
      horizontalTitleGap: 16,
      tileColor: isSelected ? Colors.red.withValues(alpha: 0.06) : null,
      onTap: toggleSelected,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(value: isSelected, onChanged: (_) => toggleSelected()),
          UserMixin.getUserImageByUrl(
              imageUrl: user.imageUrl, radius: 40, iconSize: 20),
        ],
      ),
      title: Text(
        user.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(user.email, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.volume_off, size: 16, color: Colors.red),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  user.mutedUntil == null
                      ? 'Muted'
                      : 'Muted until ${AppService.getDateTime(user.mutedUntil!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: TextButton.icon(
        style: TextButton.styleFrom(foregroundColor: Theme.of(context).primaryColor),
        icon: const Icon(CupertinoIcons.volume_up, size: 18),
        label: const Text('Unmute'),
        onPressed: () => _onUnmute(context, ref, user),
      ),
    );
  }

  void _onUnmute(BuildContext context, WidgetRef ref, UserModel user) async {
    if (!UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
      openTestingToast(context);
      return;
    }
    await FirebaseService().unmuteUser(user.id);
    final next = Set<String>.from(ref.read(mutedUsersSelectedIdsProvider))
      ..remove(user.id);
    ref.read(mutedUsersSelectedIdsProvider.notifier).state = next;
    if (!context.mounted) return;
    openSuccessToast(context, 'Unmuted ${user.name}');
  }

  void _onBulkUnmute(
      BuildContext context, WidgetRef ref, List<String> ids) async {
    if (ids.isEmpty) return;
    final unmuteBtnController = RoundedLoadingButtonController();
    CustomDialogs.openActionDialog(
      context,
      actionBtnController: unmuteBtnController,
      title: 'Unmute ${ids.length} users?',
      message:
          'Do you want to unmute the ${ids.length} selected users?\nThey will be able to comment again.',
      onAction: () async {
        if (!UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
          openTestingToast(context);
          return;
        }
        unmuteBtnController.start();
        try {
          await FirebaseService().unmuteUsersBatch(ids);
        } catch (e) {
          unmuteBtnController.error();
          if (context.mounted) {
            openFailureToast(context, 'Failed to unmute: $e');
          }
          return;
        }
        ref.read(mutedUsersSelectedIdsProvider.notifier).state = <String>{};
        unmuteBtnController.success();
        if (!context.mounted) return;
        Navigator.pop(context);
        openSuccessToast(context, 'Unmuted ${ids.length} users');
      },
    );
  }
}
