import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/event.dart';
import '../../../utils/reponsive.dart';
import 'comments.dart';

class FilterCommentsByEventButton extends ConsumerWidget {
  const FilterCommentsByEventButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(commentsEventFilterProvider);
    final label = selected == null ? 'All' : _shorten(selected.title);
    return InkWell(
      borderRadius: BorderRadius.circular(25),
      onTap: () => _openPicker(context, ref),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected == null
                ? Colors.grey.shade400
                : Theme.of(context).primaryColor,
            width: selected == null ? 1 : 1.5,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.calendar,
                size: 18,
                color: selected == null
                    ? Colors.grey[800]
                    : Theme.of(context).primaryColor),
            Visibility(
              visible: !Responsive.isMobile(context),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Text('Event - $label',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ),
            if (selected != null) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _clear(ref),
                child: const Icon(Icons.close, size: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _shorten(String s) => s.length <= 24 ? s : '${s.substring(0, 22)}...';

  void _clear(WidgetRef ref) {
    ref.read(commentsEventFilterProvider.notifier).state = null;
    rebuildCommentsQuery(ref);
  }

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final picked = await showDialog<Event?>(
      context: context,
      builder: (_) => const _EventPickerDialog(),
    );
    if (picked != null) {
      ref.read(commentsEventFilterProvider.notifier).state = picked;
      // Force target filter to 'event' so other controls stay consistent.
      ref.read(commentsTargetFilterProvider.notifier).state = 'event';
      rebuildCommentsQuery(ref);
    }
  }
}

class _EventPickerDialog extends StatefulWidget {
  const _EventPickerDialog();

  @override
  State<_EventPickerDialog> createState() => _EventPickerDialogState();
}

class _EventPickerDialogState extends State<_EventPickerDialog> {
  late Future<List<Event>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _loadEvents();
  }

  Future<List<Event>> _loadEvents() async {
    final snap = await FirebaseFirestore.instance
        .collection('events')
        .orderBy('start_date_time', descending: true)
        .limit(200)
        .get();
    return snap.docs.map((d) => Event.fromFireStore(d)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 480,
        height: 560,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.calendar),
                  const SizedBox(width: 8),
                  Text('Filter comments by event',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search event title...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) =>
                    setState(() => _query = v.toLowerCase().trim()),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<Event>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }
                    final events = (snap.data ?? [])
                        .where((e) =>
                            _query.isEmpty ||
                            e.title.toLowerCase().contains(_query))
                        .toList();
                    if (events.isEmpty) {
                      return const Center(
                          child: Text('No matching events found.'));
                    }
                    return ListView.separated(
                      itemCount: events.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final e = events[i];
                        return ListTile(
                          dense: true,
                          leading:
                              const Icon(Icons.event, color: Colors.deepPurple),
                          title: Text(e.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            _formatDate(e.startDateTime),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () => Navigator.of(context).pop(e),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
