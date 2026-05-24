import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_admin/services/auth_service.dart';
import 'package:news_admin/tabs/admin_tabs/dashboard/dashboard_providers.dart';
import 'package:news_admin/utils/toasts.dart';
import '../components/dialogs.dart';
import '../utils/reponsive.dart';
import '../mixins/textfields.dart';
import '../mixins/user_mixin.dart';
import '../models/user_model.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../components/custom_buttons.dart';
import '../providers/user_data_provider.dart';
import '../services/firebase_service.dart';

class CreateAuthorForm extends ConsumerStatefulWidget {
  const CreateAuthorForm({super.key});

  @override
  ConsumerState<CreateAuthorForm> createState() => _CreateAuthorFormState();
}

class _CreateAuthorFormState extends ConsumerState<CreateAuthorForm> with TextFields, UserMixin {
  final formKey = GlobalKey<FormState>();
  final btnController = RoundedLoadingButtonController();
  final nameCtlr = TextEditingController();
  final emailCtlr = TextEditingController();
  final passwordCtlr = TextEditingController();

  _handleSubmit() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.validate();
      final user = ref.read(userDataProvider);
      if (UserMixin.hasAdminAccess(user)) {
        btnController.start();
        final UserCredential? userCredential = await AuthService().createAuthor(emailCtlr.text.trim(), passwordCtlr.text);
        if (userCredential != null) {
          await _updateDatabase(userCredential);
          ref.invalidate(usersCountProvider);
          btnController.reset();
          if (!mounted) return;
          Navigator.pop(context);
          CustomDialogs.openInfoDialog(context, 'Createed Successfully!', '');
        } else {
          btnController.reset();
          if (!mounted) return;
          openFailureToast(context, 'Unable to create author!');
        }
      } else {
        openTestingToast(context);
      }
    }
  }

  Future _updateDatabase(UserCredential userCredential) async {
    await FirebaseService().saveAuthor(_authorData(userCredential));
  }

  UserModel _authorData(UserCredential userCredential) {
    final UserModel user = UserModel(
      id: userCredential.user!.uid,
      email: userCredential.user?.email ?? emailCtlr.text,
      name: userCredential.user!.displayName ?? nameCtlr.text,
      role: ['author'],
      createdAt: DateTime.now(),
    );

    return user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: CustomButtons.submitButton(
          context,
          width: 300,
          buttonController: btnController,
          text: 'Create',
          onPressed: _handleSubmit,
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 30,
        title: Text(
          'Create Author',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black),
        ),
        elevation: 0.1,
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 20, top: 5),
              child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.black,
                  ))),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 20 : 50),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: buildTextField(
                  context,
                  controller: nameCtlr,
                  hint: 'Author Name',
                  title: 'Name *',
                  hasImageUpload: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: buildTextField(
                  context,
                  controller: emailCtlr,
                  hint: 'Author Email',
                  title: 'Email *',
                  hasImageUpload: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: buildTextField(
                  context,
                  controller: passwordCtlr,
                  hint: 'Author Password',
                  title: 'Password *',
                  hasImageUpload: false,
                  isPassword: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
