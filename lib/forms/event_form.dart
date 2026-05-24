import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:news_admin/components/category_dropdown.dart';
import 'package:news_admin/components/custom_buttons.dart';
import 'package:news_admin/components/dialogs.dart';
import 'package:news_admin/configs/constants.dart';
import 'package:news_admin/mixins/event_mixin.dart';
import 'package:news_admin/mixins/textfields.dart';
import 'package:news_admin/mixins/user_mixin.dart';
import 'package:news_admin/models/author.dart';
import 'package:news_admin/models/event.dart';
import 'package:news_admin/models/event_category.dart';
import 'package:news_admin/providers/categories_provider.dart';
import 'package:news_admin/providers/user_data_provider.dart';
import 'package:news_admin/services/app_service.dart';
import 'package:news_admin/services/firebase_service.dart';
import 'package:news_admin/tabs/admin_tabs/dashboard/dashboard_providers.dart';
import 'package:news_admin/tabs/admin_tabs/events/event_preview.dart';
import 'package:news_admin/utils/reponsive.dart';
import 'package:news_admin/utils/toasts.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';

///
/// Created by Varnica Gupta on 12/03/25
///

class EventForm extends ConsumerStatefulWidget {
  final Event? event;

  const EventForm({this.event, super.key});

  @override
  ConsumerState<EventForm> createState() => _EventFormState();
}

class _EventFormState extends ConsumerState<EventForm> with TextFields, EventMixin {
  var formKey = GlobalKey<FormState>();

  final titleCtlr = TextEditingController();
  final startDateCtlr = TextEditingController();
  final endDateCtlr = TextEditingController();
  final thumbnailUrlCtlr = TextEditingController();
  final locationCtlr = TextEditingController();
  final watchSourceCtlr = TextEditingController();
  final resultSourceCtlr = TextEditingController();
  final summaryCtlr = TextEditingController();

  final _publishBtnCtlr = RoundedLoadingButtonController();
  final _draftBtnCtlr = RoundedLoadingButtonController();

  late Event? _event;
  XFile? _selectedImage;

  String? _selectedCategoryId;

  @override
  void initState() {
    if (widget.event != null) {
      _event = widget.event;
      titleCtlr.text = _event?.title ?? '';
      startDateCtlr.text = _event != null ? DateFormat('dd-MM-yyyy hh:mm a').format(_event!.startDateTime) : '';
      endDateCtlr.text = _event != null ? DateFormat('dd-MM-yyyy hh:mm a').format(_event!.endDateTime) : '';
      thumbnailUrlCtlr.text = _event?.thumbnailUrl ?? '';
      locationCtlr.text = _event?.location ?? '';
      watchSourceCtlr.text = _event?.watchUrl ?? '';
      resultSourceCtlr.text = _event?.resultUrl ?? '';
      _selectedCategoryId = _event?.category?.id;
      summaryCtlr.text = _event?.summary ?? '';
    } else {
      _event = null;
    }

    super.initState();
  }

  void _handlePreview() async {
    final event = _eventData('');
    if (!mounted) return;
    CustomDialogs.openFormDialog(
      context,
      widget: PointerInterceptor(child: EventPreview(event: event)),
      verticalPaddingPercentage: 0.02,
      horizontalPaddingPercentage: 0.15,
    );
  }

  void _onPickImage() async {
    XFile? image = await AppService.pickImage();
    if (image != null) {
      _selectedImage = image;
      thumbnailUrlCtlr.text = image.name;
    }
  }

  Future<String?> _getImageUrl() async {
    if (_selectedImage != null) {
      final String? imageUrl = await FirebaseService().uploadImageToFirebaseHosting(_selectedImage!, 'event_thumbnails');
      return imageUrl;
    } else {
      return thumbnailUrlCtlr.text;
    }
  }

  void _handleSubmit() async {
    if (UserMixin.hasAccess(ref.read(userDataProvider))) {
      if (formKey.currentState!.validate()) {
        formKey.currentState!.save();

        _publishBtnCtlr.start();
        final String? imageUrl = await _getImageUrl();
        if (imageUrl != null) {
          thumbnailUrlCtlr.text = imageUrl;
          final String status = setEventStatus(
              event: _event,
              start: DateFormat('dd-MM-yyyy hh:mm a').parse((startDateCtlr.text).toString()),
              end: DateFormat('dd-MM-yyyy hh:mm a').parse((endDateCtlr.text).toString()),
              isDraft: false);
          final Event event = _eventData(status);

          await _handleUpload(event);
          // await _handleNotification(article);

          ref.invalidate(eventsCountProvider);
          _publishBtnCtlr.reset();
          if (!mounted) return;
          openSuccessToast(context, 'Saved successfully!');
        } else {
          _selectedImage = null;
          thumbnailUrlCtlr.clear();
          setState(() {});
          _publishBtnCtlr.reset();
        }
      }
    } else {
      if (!mounted) return;
      openTestingToast(context);
    }
  }

  void _handleDraftSubmit() async {
    if (UserMixin.hasAccess(ref.read(userDataProvider))) {
      _draftBtnCtlr.start();
      final String? imageUrl = await _getImageUrl();
      thumbnailUrlCtlr.text = imageUrl ?? '';
      final String status = setEventStatus(event: _event, isDraft: true);

      final Event event = _eventData(status);

      //draft
      await _handleUpload(event);

      _draftBtnCtlr.reset();
      if (!mounted) return;
      openSuccessToast(context, 'Drafts saved!');
    } else {
      openTestingToast(context);
    }
  }

  Future _handleUpload(Event event) async {
    await FirebaseService().saveEvent(event);
    setState(() {
      _event = event;
    });
  }

  Event _eventData(String eventStatus) {
    final String id = _event?.id ?? FirebaseService.getUID('events');
    final createdAt = _event?.createdAt ?? DateTime.now().toUtc();
    final updatedAt = _event?.updatedAt ?? DateTime.now().toUtc();
    final String title = titleCtlr.text.isEmpty ? 'Untitled' : titleCtlr.text;
    final String thumbnail = thumbnailUrlCtlr.text.isEmpty ? '' : thumbnailUrlCtlr.text;
    final eventStartDateTime = DateFormat('dd-MM-yyyy hh:mm a').parse((startDateCtlr.text).toString());
    final eventEndDateTime = DateFormat('dd-MM-yyyy hh:mm a').parse((endDateCtlr.text).toString());
    final String? location = locationCtlr.text.isEmpty ? null : locationCtlr.text;
    final String? summary = summaryCtlr.text.isEmpty ? null : summaryCtlr.text;
    final String? watchUrl = watchSourceCtlr.text.isEmpty ? null : watchSourceCtlr.text;
    final String? resultUrl = resultSourceCtlr.text.isEmpty ? null : resultSourceCtlr.text;

    //Author Data
    final Author? author = _authorData();
    final EventCategory? category = _getCategory();

    final Event event = Event(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      title: title,
      category: category,
      thumbnailUrl: thumbnail,
      status: eventStatus,
      author: author,
      location: location,
      summary: summary,
      watchUrl: watchUrl,
      resultUrl: resultUrl,
      startDateTime: eventStartDateTime,
      endDateTime: eventEndDateTime,
    );

    return event;
  }

  Author? _authorData() {
    Author? author;
    final user = ref.read(userDataProvider);
    if (user != null) {
      if (_event?.author == null) {
        author = Author(id: user.id, name: user.name, imageUrl: user.imageUrl);
      } else {
        author = Author(id: _event!.author!.id, name: _event!.author!.name, imageUrl: _event!.author!.imageUrl);
      }
    }
    return author;
  }

  EventCategory? _getCategory() {
    EventCategory? category;
    if (_selectedCategoryId != null) {
      final categories = ref.read(categoriesProvider);
      final String categoryName = categories.where((element) => element.id == _selectedCategoryId).first.name;
      category = EventCategory(id: _selectedCategoryId!, name: categoryName);
    }

    return category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        toolbarHeight: 70,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.close,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CustomButtons.customOutlineButton(context, icon: Icons.remove_red_eye, text: 'Preview', onPressed: () => _handlePreview()),
                const SizedBox(
                  width: 10,
                ),
                Visibility(
                  visible: _event == null || _event?.status == eventStatus.keys.elementAt(0),
                  child: CustomButtons.submitButton(context,
                      buttonController: _draftBtnCtlr,
                      text: 'Save Draft',
                      onPressed: _handleDraftSubmit,
                      borderRadius: 20,
                      width: 140,
                      height: 45,
                      bgColor: Colors.blueGrey.shade300),
                ),
                const SizedBox(
                  width: 10,
                ),
                CustomButtons.submitButton(
                  context,
                  buttonController: _publishBtnCtlr,
                  text: 'Publish',
                  onPressed: _handleSubmit,
                  borderRadius: 20,
                  width: 120,
                  height: 45,
                )
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: Responsive.isMobile(context) ? const EdgeInsets.all(20) : const EdgeInsets.symmetric(vertical: 50, horizontal: 100),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CategoryDropdown(
                selectedCategoryId: _selectedCategoryId,
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                isEvent: true,
              ),
              const SizedBox(height: 30),
              buildTextField(
                context,
                controller: titleCtlr,
                hint: 'Enter Title',
                title: 'Title *',
                hasImageUpload: false,
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: buildTextField(
                      context,
                      controller: startDateCtlr,
                      hint: 'Enter start date time',
                      title: 'Start Date Time *',
                      hasDatePick: true,
                      inputType: TextInputType.datetime,
                      onPickDate: () async {
                        FocusScope.of(context).requestFocus(FocusNode()); // Prevent keyboard popup
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null && context.mounted) {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );

                          if (pickedTime != null) {
                            DateTime finalDateTime = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );

                            // Format and set value
                            startDateCtlr.text = DateFormat('dd-MM-yyyy hh:mm a').format(finalDateTime);
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: buildTextField(
                      context,
                      controller: endDateCtlr,
                      hint: 'Enter end date time',
                      title: 'End Date Time *',
                      inputType: TextInputType.datetime,
                      hasDatePick: true,
                      onPickDate: () async {
                        FocusScope.of(context).requestFocus(FocusNode()); // Prevent keyboard popup
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null && context.mounted) {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );

                          if (pickedTime != null) {
                            DateTime finalDateTime = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );

                            // Format and set value
                            endDateCtlr.text = DateFormat('dd-MM-yyyy hh:mm a').format(finalDateTime);
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              buildTextField(
                context,
                controller: thumbnailUrlCtlr,
                hint: 'Enter image URL or select image',
                title: 'Thumbnail Image *',
                hasImageUpload: true,
                onPickImage: _onPickImage,
              ),
              const SizedBox(height: 30),
              buildTextField(
                context,
                controller: locationCtlr,
                hint: 'Enter Location',
                title: 'Location *',
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: buildTextField(
                      context,
                      controller: watchSourceCtlr,
                      hint: 'Enter watch source URL',
                      title: 'Watch Source URL *',
                      urlValidationRequired: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: buildTextField(
                      context,
                      controller: resultSourceCtlr,
                      hint: 'Enter result source URL',
                      title: 'Result Source URL *',
                      urlValidationRequired: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              buildTextField(
                context,
                controller: summaryCtlr,
                hint: 'Enter Summary',
                title: 'Short Summary (Optional)',
                hasImageUpload: false,
                maxLines: null,
                validationRequired: false,
                minLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
