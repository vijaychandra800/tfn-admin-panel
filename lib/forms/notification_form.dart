import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:news_admin/components/text_editors/html_editor.dart';
import '../configs/constants.dart';
import '../models/notification_model.dart';
import '../components/custom_buttons.dart';
import '../components/dialogs.dart';
import '../utils/reponsive.dart';
import '../mixins/textfields.dart';
import '../mixins/user_mixin.dart';
import '../utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../providers/user_data_provider.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class NotificationForm extends ConsumerStatefulWidget {
  const NotificationForm({super.key});

  @override
  ConsumerState<NotificationForm> createState() => _NotificationFormState();
}

class _NotificationFormState extends ConsumerState<NotificationForm> with TextFields {
  var titleCtlr = TextEditingController();
  final HtmlEditorController controller = HtmlEditorController();
  // final QuillController controller = QuillController.basic();
  final _btnCtlr = RoundedLoadingButtonController();
  final formKey = GlobalKey<FormState>();

  _handleSendNotification() async {
    if (UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
      if (formKey.currentState!.validate()) {
        formKey.currentState!.save();
        final navigator = Navigator.of(context);
        final String description = await controller.getText();
        if (description.isNotEmpty) {
          // final String description = AppService.getHtmlfromDelta(controller.document.toDelta().toJson());
          _btnCtlr.start();
          await NotificationService().sendCustomNotificationByTopic(_notificationModel(description));
          await FirebaseService().saveNotification(_notificationModel(description));
          _clearFields();
          _btnCtlr.success();
          navigator.pop();
          if (!mounted) return;
          openSuccessToast(context, 'Notification sent successfully!');
        } else {
          if (!mounted) return;
          openFailureToast(context, "Description can't be empty");
        }
      }
    } else {
      openTestingToast(context);
    }
  }

  _clearFields() {
    titleCtlr.clear();
    controller.clear();
  }

  _openPreview() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      final String description = await controller.getText();
      if (description.isNotEmpty) {
        if (!mounted) return;
        // final String description = AppService.getHtmlfromDelta(controller.document.toDelta().toJson());
        debugPrint(description);
        CustomDialogs().openNotificationDialog(context, notification: _notificationModel(description));
      } else {
        if (!mounted) return;
        openFailureToast(context, "Description can't be empty");
      }
    }
  }

  NotificationModel _notificationModel(String description) {
    final String id = FirebaseService.getUID('notifications');
    final notification = NotificationModel(
      id: id,
      title: titleCtlr.text,
      description: description,
      sentAt: DateTime.now().toUtc(),
      topic: notificationTopicForAll,
    );
    return notification;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        toolbarHeight: 70.0,
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.close,
            color: Colors.black,
          ),
        ),
        actions: [
          CustomButtons.circleButton(context, icon: Icons.remove_red_eye, onPressed: _openPreview, radius: 20),
          const SizedBox(width: 10),
          CustomButtons.submitButton(
            context,
            buttonController: _btnCtlr,
            text: 'Send',
            onPressed: _handleSendNotification,
            borderRadius: 20,
            width: 120,
            height: 45,
          ),
          const SizedBox(
            width: 20,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 20 : 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTextField(
                    context,
                    controller: titleCtlr,
                    hint: 'Enter Notification Title',
                    title: 'Notification Title *',
                    hasImageUpload: false,
                    validationRequired: true,
                  ),
                  const SizedBox(height: 30),
                  // CustomQuillEditor(controller: controller, title: 'Description *'),
                  // CustomHtmlEditoPlus(controller: controller),
                  CustomHtmlEditor(
                    controller: controller,
                    height: 400,
                    hint: 'Enter Description',
                    title: 'Notification Description',
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
