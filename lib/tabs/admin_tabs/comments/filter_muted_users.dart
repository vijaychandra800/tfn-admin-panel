import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/reponsive.dart';
import 'comments_selection_provider.dart';

/// Toggles the admin Comments tab between the comments list and the
/// "Muted Users" management view.
class FilterMutedUsersButton extends ConsumerWidget {
  const FilterMutedUsersButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(mutedUsersFilterProvider);
    final color =
        active ? Colors.red : (Colors.grey[800] ?? Colors.grey.shade800);
    return InkWell(
      borderRadius: BorderRadius.circular(25),
      onTap: () {
        ref.read(mutedUsersFilterProvider.notifier).state = !active;
        // Clear any lingering muted-user selection when toggling the view.
        ref.read(mutedUsersSelectedIdsProvider.notifier).state = <String>{};
      },
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: active ? Colors.red.withValues(alpha: 0.08) : null,
          border: Border.all(
            color: active ? Colors.red : Colors.grey.shade400,
            width: active ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.volume_off, size: 18, color: color),
            Visibility(
              visible: !Responsive.isMobile(context),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Text(
                    'Muted Users',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: active ? Colors.red : null,
                          fontWeight: active ? FontWeight.w600 : null,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
