import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_admin/components/custom_buttons.dart';
import 'package:news_admin/components/dialogs.dart';
import 'package:news_admin/configs/constants.dart';
import 'package:news_admin/forms/event_form.dart';
import 'package:news_admin/mixins/user_mixin.dart';
import 'package:news_admin/models/event.dart';
import 'package:news_admin/providers/user_data_provider.dart';
import 'package:news_admin/services/firebase_service.dart';
import 'package:news_admin/tabs/admin_tabs/dashboard/dashboard_providers.dart';
import 'package:news_admin/tabs/admin_tabs/events/event_preview.dart';
import 'package:news_admin/utils/custom_cache_image.dart';
import 'package:news_admin/utils/empty_with_image.dart';
import 'package:news_admin/utils/reponsive.dart';
import 'package:news_admin/utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';

///
/// Created by Varnica Gupta on 12/03/25
///

mixin EventMixin {
  Widget buildEvents(
    BuildContext context, {
    required WidgetRef ref,
    required queryProvider,
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
          return const EmptyPageWithImage(title: 'No events found');
        }
        return _eventList(context, snapshot: snapshot, ref: ref);
      },
    );
  }

  Widget _eventList(
    BuildContext context, {
    required FirestoreQueryBuilderSnapshot snapshot,
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
          final List<Event> events = snapshot.docs.map((e) => Event.fromFireStore(e)).toList();
          final Event event = events[index];
          return _buildListItem(context, event, ref);
        },
      ),
    );
  }

  Row _buildListItem(BuildContext context, Event event, WidgetRef ref) {
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
                imageUrl: event.thumbnailUrl.toString(),
                radius: 3,
              ),
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
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  _buildStatus(context, event),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Text('By ${event.author!.name}'),
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
                      event.category?.name ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ],
          ),
        ),
        _eventsMenuButtons(event, context, ref),
      ],
    );
  }

  String setEventStatus({
    required Event? event,
    DateTime? start,
    DateTime? end,
    required bool isDraft,
  }) {
    start = start ?? DateTime.now();
    end = end ?? DateTime.now();
    if (isDraft) {
      //draft
      return eventStatus.keys.elementAt(0);
    } else {
      if (event != null) {
        if ((event.startDateTime.isBefore(DateTime.now())) && event.endDateTime.isAfter(DateTime.now())) {
          return eventStatus.keys.elementAt(3); //live
        } else if (event.startDateTime.isAfter(DateTime.now())) {
          return eventStatus.keys.elementAt(1); //upcoming
        } else if (event.endDateTime.isBefore(DateTime.now())) {
          return eventStatus.keys.elementAt(2); //covered
        } else {
          return eventStatus.keys.elementAt(1); //upcoming
        }
      } else {
        if ((start.isBefore(DateTime.now())) && end.isAfter(DateTime.now())) {
          return eventStatus.keys.elementAt(3); //live
        } else if (start.isAfter(DateTime.now())) {
          return eventStatus.keys.elementAt(1); //upcoming
        } else if (end.isBefore(DateTime.now())) {
          return eventStatus.keys.elementAt(2); //covered
        } else {
          return eventStatus.keys.elementAt(1); //upcoming
        }
      }
    }
  }

  Wrap _eventsMenuButtons(Event event, BuildContext context, WidgetRef ref) {
    return Wrap(
      children: [
        CustomButtons.circleButton(
          context,
          icon: Icons.remove_red_eye,
          tooltip: 'Preview',
          onPressed: () => _onPreview(context, event),
        ),
        const SizedBox(width: 8),
        CustomButtons.circleButton(
          context,
          icon: Icons.edit,
          tooltip: 'Edit',
          onPressed: () => _onEdit(context, event, ref),
        ),
        const SizedBox(width: 8),
        _menuButton(context, event, ref),
      ],
    );
  }

  PopupMenuButton _menuButton(BuildContext context, Event event, WidgetRef ref) {
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
            enabled: UserMixin.hasAdminAccess(ref.watch(userDataProvider)),
            child: Text(event.status == eventStatus.keys.elementAt(4) ? 'Publish Event' : 'Archive Event'),
            onTap: () => _handleArchiveEvent(context, event),
          ),
          PopupMenuItem(
              enabled: UserMixin.isAuthor(ref.watch(userDataProvider), event),
              child: const Text('Delete Event'),
              onTap: () => _onDelete(context, event, ref)),
        ];
      },
    );
  }

  void _onDelete(context, Event event, WidgetRef ref) async {
    final deleteBtnController = RoundedLoadingButtonController();
    CustomDialogs.openActionDialog(
      context,
      actionBtnController: deleteBtnController,
      title: 'Delete this this?',
      message: 'Warning: All of the data related to this event will be deleted and this can not be undone!',
      onAction: () async {
        final user = ref.read(userDataProvider);
        if (UserMixin.isAuthor(user, event) || UserMixin.hasAdminAccess(user)) {
          deleteBtnController.start();
          await FirebaseService().deleteContent('events', event.id);
          ref.invalidate(eventsCountProvider);
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

  void _handleArchiveEvent(BuildContext context, Event event) async {
    String message = '';
    if (event.status == eventStatus.keys.elementAt(4)) {
      event.status = eventStatus.keys.elementAt(1);
      message = 'Event Published Successfully';
    } else {
      event.status = eventStatus.keys.elementAt(4);
      message = 'Event Archived Successfully';
    }
    await FirebaseService().saveEvent(event);
    if (context.mounted) {
      openSuccessToast(context, message);
    }
  }

  void _onEdit(BuildContext context, Event event, WidgetRef ref) {
    if (UserMixin.hasAccess(ref.read(userDataProvider))) {
      CustomDialogs.openFullScreenDialog(context, widget: EventForm(event: event));
    } else {
      openFailureToast(context, 'Only Admin and Author can edit their own event');
    }
  }

  void _onPreview(BuildContext context, Event event) {
    CustomDialogs.openResponsiveDialog(context, widget: EventPreview(event: event), verticalPaddingPercentage: 0.02);
  }

  Container _buildStatus(BuildContext context, Event event) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: _getStatusColor(event.status)),
      child: Text(
        '${eventStatus[event.status]}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 12),
      ),
    );
  }

  static Color _getStatusColor(String status) {
//draft
    if (status == eventStatus.keys.elementAt(0)) {
      return Colors.grey.shade500;

//upcoming
    } else if (status == eventStatus.keys.elementAt(1)) {
      return Colors.green;

//covered
    } else if (status == eventStatus.keys.elementAt(2)) {
      return Colors.orangeAccent;
    }
//live
    else if (status == eventStatus.keys.elementAt(3)) {
      return Colors.redAccent;
    }
//archived
    else {
      return Colors.grey.shade500;
    }
  }
}
