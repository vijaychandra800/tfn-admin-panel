import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:news_admin/models/event.dart';
import 'package:news_admin/services/app_service.dart';
import '../../../../utils/custom_cache_image.dart';
import '/../../utils/reponsive.dart';

class EventPreview extends ConsumerWidget {
  const EventPreview({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: const Text('Event Preview'),
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
                    child: CustomCacheImage(imageUrl: event.thumbnailUrl.toString(), radius: 5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Chip(
                        padding: const EdgeInsets.all(10),
                        elevation: 0,
                        label: Text(
                          event.category?.name ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      Visibility(
                        visible: event.watchUrl?.isNotEmpty ?? false,
                        child: ActionChip(
                          onPressed: () => AppService().openLink(context, event.watchUrl.toString()),
                          padding: const EdgeInsets.all(10),
                          elevation: 0,
                          label: const Text(
                            'Watch',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      ),
                      Visibility(
                        visible: event.resultUrl?.isNotEmpty ?? false,
                        child: ActionChip(
                          onPressed: () => AppService().openLink(context, event.resultUrl.toString()),
                          padding: const EdgeInsets.all(10),
                          elevation: 0,
                          label: const Text(
                            'Result',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Wrap(
                    children: [
                      Text(DateFormat('dd-MM-yyyy hh:mm a').format(event.startDateTime)),
                      const SizedBox(width: 10),
                      Text(DateFormat('dd-MM-yyyy hh:mm a').format(event.endDateTime)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            Text(event.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
            Visibility(
              visible: event.summary?.isNotEmpty ?? false,
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      const VerticalDivider(),
                      Expanded(
                          child: Text(
                        event.summary.toString(),
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
