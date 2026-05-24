import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_admin/components/custom_buttons.dart';
import 'package:news_admin/components/dialogs.dart';
import 'package:news_admin/configs/constants.dart';
import 'package:news_admin/forms/event_form.dart';
import 'package:news_admin/mixins/appbar_mixin.dart';
import 'package:news_admin/mixins/event_mixin.dart';
import 'package:news_admin/tabs/admin_tabs/events/sort_events_button.dart';

///
/// Created by Varnica Gupta on 12/03/25
///

final eventQueryProvider = StateProvider<Query>((ref) {
  final query = FirebaseFirestore.instance.collection('events').orderBy('created_at', descending: true);
  return query;
});

final sortByEventTextProvider = StateProvider<String>((ref) => sortByEvent.entries.first.value);

class Events extends ConsumerWidget with EventMixin {
  const Events({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AppBarMixin.buildTitleBar(context, title: 'Events', buttons: [
            CustomButtons.customOutlineButton(
              context,
              icon: Icons.add,
              text: 'Create Event',
              bgColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              onPressed: () {
                CustomDialogs.openFullScreenDialog(context, widget: const EventForm(event: null));
              },
            ),
            const SizedBox(width: 10),
            SortEventsButton(ref: ref),
          ]),
          buildEvents(context, ref: ref, queryProvider: eventQueryProvider)
        ],
      ),
    );
  }
}
