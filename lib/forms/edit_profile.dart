import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../components/dialogs.dart';
import '../utils/reponsive.dart';
import '../mixins/textfields.dart';
import '../mixins/user_mixin.dart';
import '../models/user_model.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../components/custom_buttons.dart';
import '../providers/user_data_provider.dart';
import '../services/app_service.dart';
import '../services/firebase_service.dart';

class EditProfile extends ConsumerStatefulWidget {
  const EditProfile({super.key, required this.user});

  final UserModel user;

  @override
  ConsumerState<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<EditProfile> with TextFields, UserMixin {
  final formKey = GlobalKey<FormState>();
  final btnController = RoundedLoadingButtonController();
  final nameCtlr = TextEditingController();

  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    nameCtlr.text = widget.user.name;
  }

  _pickImage() async {
    XFile? image = await AppService.pickImage(maxHeight: 300, maxWidth: 300);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<String?> _getImageUrl() async {
    if (_selectedImage != null) {
      final String? imageUrl = await FirebaseService().uploadImageToFirebaseHosting(_selectedImage!, 'user_images');
      return imageUrl;
    } else {
      return widget.user.imageUrl;
    }
  }

  _handleSubmit() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.validate();
      btnController.start();
      final String? imageUrl = await _getImageUrl();
      await _updateDatabase(imageUrl);
      ref.invalidate(userDataProvider);

      await ref.read(userDataProvider.notifier).getData();
      btnController.reset();
      if (!mounted) return;
      CustomDialogs.openInfoDialog(context, 'Updated Successfully', '');
    }
  }

  Future _updateDatabase(String? imageUrl) async {
    await FirebaseService().updateUserProfile(widget.user, _prepareData(imageUrl));
  }

  Map<String, dynamic> _prepareData(String? imageUrl) {
    final data = {'name': nameCtlr.text, 'image_url': imageUrl};
    return data;
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
          text: 'Update',
          onPressed: _handleSubmit,
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 30,
        title: Text(
          'Edit Profile',
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
              _profileImage(),
              const SizedBox(
                height: 30,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: buildTextField(
                  context,
                  controller: nameCtlr,
                  hint: 'Enter Name',
                  title: 'Your Name *',
                  hasImageUpload: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileImage() {
    return Center(
      child: InkWell(
        onTap: () => _pickImage(),
        child: getUserImage(
          user: widget.user,
          radius: 100,
          iconSize: 30,
          imagePath: _selectedImage?.path,
        ),
      ),
    );
  }
}
