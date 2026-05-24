import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:news_admin/models/custom_ad_model.dart';
import 'package:news_admin/tabs/admin_tabs/ads_settings.dart';
import '../../components/custom_buttons.dart';
import '../../utils/reponsive.dart';
import '../../mixins/textfields.dart';
import '../../mixins/user_mixin.dart';
import '../../utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../../providers/user_data_provider.dart';
import '../../services/app_service.dart';
import '../../services/firebase_service.dart';

class CustomAdsForm extends ConsumerStatefulWidget {
  const CustomAdsForm({super.key});

  @override
  ConsumerState<CustomAdsForm> createState() => _CustomAdsFormState();
}

class _CustomAdsFormState extends ConsumerState<CustomAdsForm> with TextFields {
  final titleTextCtlr = TextEditingController();
  final actionButtonTextCtlr = TextEditingController();
  final targetUrlCtlr = TextEditingController();
  final imageUrlCtlr = TextEditingController();
  final btnCtlr = RoundedLoadingButtonController();
  var formKey = GlobalKey<FormState>();
  XFile? _selectedImage;

  void _onPickImage() async {
    XFile? image = await AppService.pickImage();
    if (image != null) {
      _selectedImage = image;
      imageUrlCtlr.text = image.name;
    }
  }

  Future<String?> _getImageUrl() async {
    if (_selectedImage != null) {
      final String? imageUrl = await FirebaseService().uploadImageToFirebaseHosting(_selectedImage!, 'custom_ads');
      return imageUrl;
    } else {
      return imageUrlCtlr.text;
    }
  }

  void handleSubmit() async {
    if (UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
      if (formKey.currentState!.validate()) {
        formKey.currentState!.save();
        btnCtlr.start();
        final String? imageUrl = await _getImageUrl();
        if (imageUrl != null) {
          imageUrlCtlr.text = imageUrl;
          _handleCreate(imageUrl);
          btnCtlr.reset();
        } else {
          _selectedImage = null;
          imageUrlCtlr.clear();
          setState(() {});
          btnCtlr.reset();
        }
      }
    } else {
      openTestingToast(context);
    }
  }

  _handleCreate(String imageUrl) async {
    final navigator = Navigator.of(context);
    final ads = ref.read(customAdsProvider);
    ads.add(_newAd());
    ref.read(customAdsProvider.notifier).state = [...ads];
    navigator.pop();
    if (!mounted) return;
    openSuccessToast(context, 'Created successfully!');
  }

  CustomAdModel _newAd() {
    final ad = CustomAdModel(
      target: targetUrlCtlr.text,
      imageUrl: imageUrlCtlr.text,
      actionButtonText: actionButtonTextCtlr.text,
      title: titleTextCtlr.text,
    );

    return ad;
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
          buttonController: btnCtlr,
          text: 'Create Ad',
          onPressed: handleSubmit,
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20, top: 10),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.close,
                color: Colors.black,
              ),
            ),
          ),
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
              buildTextField(
                context,
                controller: titleTextCtlr,
                hint: 'Title',
                title: 'Ad Title',
                hasImageUpload: false,
                validationRequired: false,
              ),
              const SizedBox(height: 30),
              buildTextField(
                context,
                controller: imageUrlCtlr,
                hint: 'Enter image URL or select image',
                title: 'Ad Image',
                hasImageUpload: true,
                onPickImage: _onPickImage,
                validationRequired: false,
              ),
              const SizedBox(height: 30),
              buildTextField(
                context,
                controller: targetUrlCtlr,
                hint: 'Ad destination URL',
                title: 'Ad Target URL *',
                hasImageUpload: false,
                validationRequired: true,
              ),
              const SizedBox(height: 30),
              buildTextField(
                context,
                controller: actionButtonTextCtlr,
                hint: 'Button text',
                title: 'Action Button Text',
                hasImageUpload: false,
                validationRequired: false,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
