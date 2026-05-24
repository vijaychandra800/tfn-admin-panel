import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_icons/line_icons.dart';
import 'package:news_admin/components/checkbox_option.dart';
import 'package:news_admin/components/text_editors/html_editor.dart';
import 'package:news_admin/models/article_category.dart';
import 'package:news_admin/models/notification_model.dart';
import 'package:news_admin/providers/categories_provider.dart';
import 'package:news_admin/services/notification_service.dart';
import 'package:news_admin/tabs/admin_tabs/articles/article_preview/article_preview.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../components/content_type_dropdown.dart';
import '../components/dialogs.dart';
import '../configs/constants.dart';
import '../components/category_dropdown.dart';
import '../mixins/article_mixin.dart';
import '../components/custom_buttons.dart';
import '../components/radio_options.dart';
import '../models/app_settings_model.dart';
import '../tabs/admin_tabs/app_settings/app_setting_providers.dart';
import '../utils/reponsive.dart';
import '../components/tags_dropdown.dart';
import '../mixins/textfields.dart';
import '../mixins/user_mixin.dart';
import '../models/author.dart';
import '../models/article.dart';
import '../models/tag.dart';
import '../utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../providers/user_data_provider.dart';
import '../services/app_service.dart';
import '../services/firebase_service.dart';
import '../tabs/admin_tabs/dashboard/dashboard_providers.dart';

final tagsProvider = FutureProvider<List<Tag>>((ref) async {
  List<Tag> tags = await FirebaseService().getTags();
  return tags;
});

class ArticleForm extends ConsumerStatefulWidget {
  const ArticleForm({super.key, required this.article, this.isAuthorTab});

  final Article? article;
  final bool? isAuthorTab;

  @override
  ConsumerState<ArticleForm> createState() => _ArticleFormState();
}

class _ArticleFormState extends ConsumerState<ArticleForm> with TextFields, ArticleMixin {
  final titleCtlr = TextEditingController();
  final thumbnailUrlCtlr = TextEditingController();
  final summaryCtlr = TextEditingController();
  final videoUrlCtlr = TextEditingController();
  final audioUrlCtlr = TextEditingController();
  final sourceCtlr = TextEditingController();

  // final HtmlEditorController descriptionCtlr = HtmlEditorController();
  // final QuillController descriptionCtlr = QuillController.basic();
  final HtmlEditorController descriptionCtlr = HtmlEditorController();

  String _pricingStatus = priceStatus.entries.first.key;

  bool _commentEnabled = true;
  String _contentType = contentTypes.keys.elementAt(0);
  bool _notifyUsers = false;

  final _publishBtnCtlr = RoundedLoadingButtonController();
  final _draftBtnCtlr = RoundedLoadingButtonController();

  var formKey = GlobalKey<FormState>();
  XFile? _selectedImage;

  String? _selectedCategoryId;
  List _selectedTagIDs = [];

  late Article? _article;
  bool _featured = false;

  void _onPickImage() async {
    XFile? image = await AppService.pickImage();
    if (image != null) {
      _selectedImage = image;
      thumbnailUrlCtlr.text = image.name;
    }
  }

  Future<String?> _getImageUrl() async {
    if (_selectedImage != null) {
      final String? imageUrl = await FirebaseService().uploadImageToFirebaseHosting(_selectedImage!, 'article_thumbnails');
      return imageUrl;
    } else {
      return thumbnailUrlCtlr.text;
    }
  }

  void _handleSubmit() async {
    if (UserMixin.hasAccess(ref.read(userDataProvider))) {
      if (formKey.currentState!.validate()) {
        formKey.currentState!.save();
        final String description = await descriptionCtlr.getText();
        if (description.isNotEmpty) {
          _publishBtnCtlr.start();
          final String? imageUrl = await _getImageUrl();
          if (imageUrl != null) {
            thumbnailUrlCtlr.text = imageUrl;
            final String status = setArticleStatus(article: _article, isAuthorTab: widget.isAuthorTab, isDraft: false);
            // final String description = AppService.getHtmlfromDelta(descriptionCtlr.document.toDelta().toJson());
            final Article article = _articleData(status, description);

            await _handleUpload(article);
            await _handleNotification(article);

            ref.invalidate(articlesCountProvider);
            _publishBtnCtlr.reset();
            if (!mounted) return;
            openSuccessToast(context, 'Saved successfully!');
          } else {
            _selectedImage = null;
            thumbnailUrlCtlr.clear();
            setState(() {});
            _publishBtnCtlr.reset();
          }
        } else {
          if (!mounted) return;
          openFailureToast(context, "Description can't be empty");
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
      final String status = setArticleStatus(article: _article, isAuthorTab: widget.isAuthorTab, isDraft: true);
      // final String description = AppService.getHtmlfromDelta(descriptionCtlr.document.toDelta().toJson());
      final String description = await descriptionCtlr.getText();

      final Article article = _articleData(status, description);

      //draft
      await _handleUpload(article);

      _draftBtnCtlr.reset();
      if (!mounted) return;
      openSuccessToast(context, 'Drafts saved!');
    } else {
      openTestingToast(context);
    }
  }

  Future _handleUpload(Article article) async {
    await FirebaseService().saveArticle(article);
    setState(() {
      _article = article;
    });
  }

  Article _articleData(String articleStatus, String description) {
    final String id = _article?.id ?? FirebaseService.getUID('articles');
    final createdAt = _article?.createdAt ?? DateTime.now().toUtc();
    final updatedAt = _article == null ? null : DateTime.now().toUtc();
    final String title = titleCtlr.text.isEmpty ? 'Untitled' : titleCtlr.text;
    final String thumbnail = thumbnailUrlCtlr.text.isEmpty ? '' : thumbnailUrlCtlr.text;
    final String? video = videoUrlCtlr.text.isEmpty ? null : videoUrlCtlr.text;
    final String? audio = audioUrlCtlr.text.isEmpty ? null : audioUrlCtlr.text;
    final String priceStatus = _pricingStatus;
    final String? summary = summaryCtlr.text.isEmpty ? null : summaryCtlr.text;
    final String? source = sourceCtlr.text.isEmpty ? null : sourceCtlr.text;

    //Author Data
    final Author? author = _authorData();
    final ArticleCategory? category = _getCategory();

    final Article article = Article(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      title: title,
      category: category,
      thumbnailUrl: thumbnail,
      tagIDs: _selectedTagIDs,
      videoUrl: video,
      status: articleStatus,
      author: author,
      priceStatus: priceStatus,
      description: description,
      audioUrl: audio,
      isCommentsEnabled: _commentEnabled,
      contentType: _contentType,
      summary: summary,
      sourceUrl: source,
      isFeatured: _featured,
    );

    return article;
  }

  Author? _authorData() {
    Author? author;
    final user = ref.read(userDataProvider);
    if (user != null) {
      if (_article?.author == null) {
        author = Author(id: user.id, name: user.name, imageUrl: user.imageUrl);
      } else {
        author = Author(id: _article!.author!.id, name: _article!.author!.name, imageUrl: _article!.author!.imageUrl);
      }
    }
    return author;
  }

  ArticleCategory? _getCategory() {
    ArticleCategory? category;
    if (_selectedCategoryId != null) {
      final categories = ref.read(categoriesProvider);
      final String categoryName = categories.where((element) => element.id == _selectedCategoryId).first.name;
      category = ArticleCategory(id: _selectedCategoryId!, name: categoryName);
    }

    return category;
  }

  _handleNotification(Article article) async {
    if (_notifyUsers) {
      final String id = FirebaseService.getUID('notifications');
      final notification = NotificationModel(
        id: id,
        title: article.title,
        description: article.description,
        sentAt: DateTime.now().toUtc(),
        topic: notificationTopicForAll,
      );
      await FirebaseService().saveNotification(notification);
      await NotificationService().sendPostNotificationToAll(article);
    }
  }

  @override
  void initState() {
    if (widget.article != null) {
      _article = widget.article;
      titleCtlr.text = _article?.title ?? '';
      thumbnailUrlCtlr.text = _article?.thumbnailUrl ?? '';
      videoUrlCtlr.text = _article?.videoUrl ?? '';
      _selectedCategoryId = _article?.category?.id;
      _selectedTagIDs = _article?.tagIDs ?? [];
      _pricingStatus = _article?.priceStatus ?? priceStatus.entries.first.key;
      summaryCtlr.text = _article?.summary ?? '';
      audioUrlCtlr.text = _article?.audioUrl ?? '';
      _commentEnabled = _article?.isCommentsEnabled ?? true;
      _contentType = _article?.contentType ?? contentTypes.keys.elementAt(0);
      sourceCtlr.text = _article?.sourceUrl ?? '';
      _featured = _article?.isFeatured ?? false;
    } else {
      _article = null;
    }
    super.initState();
  }

  void _handlePreview() async {
    // final String description = AppService.getHtmlfromDelta(descriptionCtlr.document.toDelta().toJson());
    final String description = await descriptionCtlr.getText();
    final article = _articleData('', description);
    if (!mounted) return;
    CustomDialogs.openFormDialog(
      context,
      widget: PointerInterceptor(child: ArticlePreview(article: article)),
      verticalPaddingPercentage: 0.02,
      horizontalPaddingPercentage: 0.15,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagsProvider);

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
            )),
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
                  visible: _article == null || _article?.status == articleStatus.keys.elementAt(0),
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
                  text: widget.isAuthorTab != null && widget.isAuthorTab == true ? 'Submit' : 'Publish',
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
              Row(
                children: [
                  Expanded(
                    child: CategoryDropdown(
                      selectedCategoryId: _selectedCategoryId,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ContentTypeDropdown(
                      contentType: _contentType,
                      onChanged: (value) {
                        setState(() => _contentType = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              buildTextField(context, controller: titleCtlr, hint: 'Enter Title', title: 'Title *', hasImageUpload: false),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: buildTextField(
                      context,
                      controller: thumbnailUrlCtlr,
                      hint: 'Enter image URL or select image',
                      title: 'Thumbnail Image',
                      hasImageUpload: true,
                      onPickImage: _onPickImage,
                      validationRequired: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: buildTextField(
                      context,
                      controller: sourceCtlr,
                      hint: 'Enter source URL',
                      title: 'Source (Optional)',
                      validationRequired: false,
                      urlValidationRequired: false,
                    ),
                  ),
                ],
              ),
              Visibility(
                visible: _contentType == contentTypes.keys.elementAt(1),
                child: Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: buildTextField(
                    context,
                    controller: videoUrlCtlr,
                    hint: 'Enter video url',
                    title: 'Video URL *',
                    hasImageUpload: false,
                    validationRequired: true,
                    urlValidationRequired: true,
                  ),
                ),
              ),
              Visibility(
                visible: _contentType == contentTypes.keys.elementAt(2),
                child: Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: buildTextField(
                    context,
                    controller: audioUrlCtlr,
                    hint: 'Enter Embed SoundCloud Audio URL',
                    title: 'Audio URL *',
                    hasImageUpload: false,
                    validationRequired: true,
                    urlValidationRequired: true,
                  ),
                ),
              ),

              const SizedBox(height: 30),
              tags.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, x) => Container(),
                data: (data) => TagsDropdown(
                  selectedTagIDs: _selectedTagIDs,
                  tags: data,
                  onAdd: (value) => setState(() => _selectedTagIDs.add(value)),
                  onRemove: (value) => setState(() => _selectedTagIDs.remove(value)),
                ),
              ),
              const SizedBox(height: 30),
              Consumer(
                builder: (context, ref, child) {
                  final settings = ref.watch(appSettingsProvider);
                  final LicenseType license = settings.value?.license ?? LicenseType.none;
                  final bool isExtendedLicense = license == LicenseType.extended;

                  return RadioOptions(
                    contentType: _pricingStatus,
                    onChanged: (value) {
                      if (isExtendedLicense) {
                        setState(() => _pricingStatus = value);
                      } else {
                        openFailureToast(context, 'Extended license is required');
                      }
                    },
                    options: priceStatus,
                    title: 'Pricing Status',
                    icon: LineIcons.dollarSign,
                  );
                },
              ),
              Wrap(
                children: [
                  CheckBoxOption(
                    defaultvalue: _commentEnabled,
                    title: 'Comments Enabled',
                    onChanged: (value) => setState(() => _commentEnabled = value),
                  ),
                  const SizedBox(width: 50),

                  // Disable Notify Users for published contents && author submisson
                  Visibility(
                    visible: _article?.status != articleStatus.keys.elementAt(2) && !UserMixin.hasAuthorAccess(ref.read(userDataProvider)),
                    child: CheckBoxOption(
                      defaultvalue: _notifyUsers,
                      title: 'Notify Users',
                      onChanged: (value) => setState(() => _notifyUsers = value),
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
              const SizedBox(height: 30),
              // CustomQuillEditor(
              //   controller: descriptionCtlr,
              //   title: 'Description',
              //   height: 600,
              //   initialText: widget.article?.description,
              // ),
              // CustomHtmlEditoPlus(controller: descriptionCtlr, initialText: widget.article?.description),
              CustomHtmlEditor(
                controller: descriptionCtlr,
                height: 500,
                hint: 'Enter Description',
                title: 'Article Description',
                initialText: widget.article?.description,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
