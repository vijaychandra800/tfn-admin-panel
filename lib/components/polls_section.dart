import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_admin/components/custom_buttons.dart';
import 'package:news_admin/components/dialogs.dart';
import 'package:news_admin/forms/poll_form.dart';
import 'package:news_admin/mixins/user_mixin.dart';
import 'package:news_admin/models/poll.dart';
import 'package:news_admin/providers/user_data_provider.dart';
import 'package:news_admin/services/firebase_service.dart';
import 'package:news_admin/utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';

class PollsSection extends ConsumerWidget {
  final String eventId;

  const PollsSection({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Polls',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            CustomButtons.customOutlineButton(
              context,
              icon: Icons.add,
              text: 'Add Poll',
              bgColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              onPressed: () => _openPollForm(context, ref, null),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Add one or more polls to this event. Users will be able to vote in the app.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.blueGrey),
        ),
        const SizedBox(height: 15),
        StreamBuilder<List<Poll>>(
          stream: FirebaseService().pollsStream(eventId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final polls = snapshot.data ?? [];
            if (polls.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(5),
                ),
                child:
                    const Text('No polls yet. Click "Add Poll" to create one.'),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: polls.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _pollTile(context, ref, polls[i]),
            );
          },
        ),
      ],
    );
  }

  Widget _pollTile(BuildContext context, WidgetRef ref, Poll poll) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  poll.question,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              _statusChip(poll.status),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _openPollForm(context, ref, poll),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.redAccent),
                onPressed: () => _confirmDelete(context, ref, poll),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...poll.options.map((o) {
            final total = poll.totalVotes;
            final pct = total == 0 ? 0.0 : o.voteCount / total;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(o.text)),
                      Text(
                          '${o.voteCount} (${(pct * 100).toStringAsFixed(0)}%)',
                          style: const TextStyle(color: Colors.blueGrey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            '${poll.totalVotes} total votes${poll.allowMultiple ? ' • multiple selections allowed' : ''}',
            style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final isOpen = status == 'open';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green : Colors.grey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }

  void _openPollForm(BuildContext context, WidgetRef ref, Poll? poll) {
    if (!UserMixin.hasAccess(ref.read(userDataProvider))) {
      openTestingToast(context);
      return;
    }
    CustomDialogs.openFormDialog(
      context,
      widget: PollForm(eventId: eventId, poll: poll),
      verticalPaddingPercentage: 0.05,
      horizontalPaddingPercentage: 0.20,
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Poll poll) {
    final btnCtlr = RoundedLoadingButtonController();
    CustomDialogs.openActionDialog(
      context,
      actionBtnController: btnCtlr,
      title: 'Delete this poll?',
      message: 'All votes for this poll will be lost. This cannot be undone.',
      onAction: () async {
        if (!UserMixin.hasAccess(ref.read(userDataProvider))) {
          openTestingToast(context);
          return;
        }
        btnCtlr.start();
        await FirebaseService().deletePoll(eventId, poll.id);
        btnCtlr.success();
        if (!context.mounted) return;
        Navigator.pop(context);
        openSuccessToast(context, 'Poll deleted');
      },
    );
  }
}
