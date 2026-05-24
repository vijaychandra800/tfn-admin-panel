import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_admin/configs/app_config.dart';
import '../../../mixins/appbar_mixin.dart';
import '../../../components/custom_buttons.dart';
import '../../../mixins/textfields.dart';
import '../../../mixins/user_mixin.dart';
import '../../../utils/toasts.dart';
import '../../../models/app_settings_model.dart';
import '../../../providers/user_data_provider.dart';
import '../../../services/firebase_service.dart';
import 'app_setting_providers.dart';
import 'home_tab_settings.dart';
import 'others_tab_settings.dart';
import 'post_details_tab_settings.dart';

class AppSettings extends ConsumerWidget with TextFields {
  const AppSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    final isFeaturedEnbled = ref.watch(isFeaturedEnabledProvider);
    final isLatestPostsEnabled = ref.watch(isLatestArticlesEnabledProvider);
    final isTagsEnabled = ref.watch(isTagsEnabledProvider);
    final isSkipLoginEnabled = ref.watch(isSkipLoginEnabledProvider);
    final onBoardingEnabled = ref.watch(isOnboardingEnabledProvider);

    final isViewsEnabled = ref.watch(isViewsEnabledProvider);
    final isLikesEnabled = ref.watch(isLikesEnabledProvider);
    final isCommentsEnabled = ref.watch(isCommentsEnabledProvider);
    final isPopularPostsEnabled = ref.watch(isPopularArticlesEnabledProvider);
    final isAuthorInfoEnabled = ref.watch(isAuthorInfoEnabledProvider);
    final isVideoEnabled = ref.watch(isVideoTabEnabledProvider);
    final isAudioTabEnabled = ref.watch(isAudioTabEnabledProvider);
    final isDrawerMenuEnabled = ref.watch(isDrawermenuEnabledProvider);
    final isLogoAtCenter = ref.watch(isLogoCenterProvider);
    final postDetailsLayouts = ref.watch(postDetailsLayoutProvider);
    final homeCategories = ref.watch(homeCategoriesProvider);
    final categoryTileLayout = ref.watch(categoryTileLayoutProvider);
    final dateEnabled = ref.watch(isDateEnabledProvider);
    final featureAutoSlide = ref.watch(isFeaturedPostsAutoSlidableProvider);
    final searchBoxEnabled = ref.watch(isSearchBoxEnabledProvider);
    final readingTimeEnabled = ref.watch(isReadingTimeEnabledProvider);

    final websiteCtlr = ref.watch(websiteTextfieldProvider);
    final supportEmailCtlr = ref.watch(supportEmailTextfieldProvider);
    final privacyCtlr = ref.watch(privacyUrlTextfieldProvider);
    final termsofUseCtlr = ref.watch(termsOfUserTextfieldProvider);

    final fbCtlr = ref.watch(fbProvider);
    final youtubeCtlr = ref.watch(youtubeProvider);
    final twitterCtrl = ref.watch(twitterProvider);
    final instaCtlr = ref.watch(instaProvider);

    final saveBtnCtlr = ref.watch(saveSettingsBtnProvider);

    // ignore: no_leading_underscores_for_local_identifiers
    final List<Tab> _tabs = [
      const Tab(text: 'Home Tab'),
      const Tab(text: 'Post Details'),
      const Tab(text: 'Others'),
      const Tab(text: 'App Info'),
      const Tab(text: 'Social Info'),
    ];

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppConfig.titleBarColor,
          elevation: 0.5,
          bottom: TabBar(
            tabs: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Theme.of(context).primaryColor,
            labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade900, fontWeight: FontWeight.w500),
          ),
          title: AppBarMixin.buildTitleBar(
            context,
            title: 'App Settings',
            buttons: [
              CustomButtons.submitButton(
                context,
                buttonController: saveBtnCtlr,
                text: 'Save Changes',
                width: 170,
                borderRadius: 25,
                onPressed: () async {
                  final AppSettingsSocialInfo social = AppSettingsSocialInfo(
                    fb: fbCtlr.text,
                    youtube: youtubeCtlr.text,
                    twitter: twitterCtrl.text,
                    instagram: instaCtlr.text,
                  );

                  final AppSettingsModel appSettingsModel = AppSettingsModel(
                    featured: isFeaturedEnbled,
                    tags: isTagsEnabled,
                    onBoarding: onBoardingEnabled,
                    skipLogin: isSkipLoginEnabled,
                    privacyUrl: privacyCtlr.text,
                    supportEmail: supportEmailCtlr.text,
                    website: websiteCtlr.text,
                    social: social,
                    latestArticles: isLatestPostsEnabled,
                    views: isViewsEnabled,
                    likes: isLikesEnabled,
                    comments: isCommentsEnabled,
                    popular: isPopularPostsEnabled,
                    author: isAuthorInfoEnabled,
                    videoTab: isVideoEnabled,
                    audioTab: isAudioTabEnabled,
                    logoAtCenter: isLogoAtCenter,
                    drawerMenu: isDrawerMenuEnabled,
                    homeCategories: homeCategories,
                    postDetailsLayout: postDetailsLayouts,
                    categoryTileLayout: categoryTileLayout,
                    date: dateEnabled,
                    searchBox: searchBoxEnabled,
                    featureAutoSlide: featureAutoSlide,
                    readingTime: readingTimeEnabled,
                    termsOfUseUrl: termsofUseCtlr.text,
                  );

                  final data = AppSettingsModel.getMap(appSettingsModel);
                  if (UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
                    saveBtnCtlr.start();
                    await FirebaseService().updateAppSettings(data);
                    saveBtnCtlr.reset();
                    if (!context.mounted) return;
                    openSuccessToast(context, 'Saved successfully!');
                  } else {
                    openTestingToast(context);
                  }
                },
              ),
              const SizedBox(width: 10),
              CustomButtons.circleButton(
                context,
                icon: Icons.refresh,
                bgColor: Theme.of(context).primaryColor,
                iconColor: Colors.white,
                radius: 22,
                onPressed: () async {
                  ref.invalidate(appSettingsProvider);
                  openSuccessToast(context, 'Refreshed!');
                },
              ),
            ],
          ),
        ),
        body: settings.isRefreshing
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Home Tab Settings
                  HomeTabSettings(
                    isFeaturedEnbled: isFeaturedEnbled,
                    isPopularPostsEnabled: isPopularPostsEnabled,
                    isLatestPostsEnabled: isLatestPostsEnabled,
                    isDrawerMenuEnabled: isDrawerMenuEnabled,
                    isLogoAtCenter: isLogoAtCenter,
                    isFeatureAutoslide: featureAutoSlide,
                    isSearchBoxEnbaled: searchBoxEnabled,
                    ref: ref,
                  ),

                  // Post Details Setttings
                  PostDetailsSettings(
                    isTagsEnabled: isTagsEnabled,
                    isViewsEnabled: isViewsEnabled,
                    isLikesEnabled: isLikesEnabled,
                    isCommentsEnabled: isCommentsEnabled,
                    isAuthorInfoEnabled: isAuthorInfoEnabled,
                    isReadingTimeEnabled: readingTimeEnabled,
                    ref: ref,
                  ),

                  // Others Settings
                  OthersSettings(
                    onBoardingEnabled: onBoardingEnabled,
                    isSkipLoginEnabled: isSkipLoginEnabled,
                    isVideoEnabled: isVideoEnabled,
                    isAudioTabEnabled: isAudioTabEnabled,
                    isDateEnbaled: dateEnabled,
                    ref: ref,
                  ),

                  // App Informations
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: buildTextField(context,
                                controller: supportEmailCtlr,
                                hint: 'Email',
                                title: 'Support Email',
                                hasImageUpload: false,
                                validationRequired: false),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: buildTextField(context,
                                controller: websiteCtlr,
                                hint: 'Your website url',
                                title: 'Website URL',
                                hasImageUpload: false,
                                validationRequired: false),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: buildTextField(context,
                                controller: privacyCtlr,
                                hint: 'Privacy url',
                                title: 'Privacy Policy',
                                hasImageUpload: false,
                                validationRequired: false),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: buildTextField(context,
                                controller: termsofUseCtlr,
                                hint: 'Terms of use url',
                                title: 'Terms Of USE',
                                hasImageUpload: false,
                                validationRequired: false),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Social Info
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: buildTextField(context,
                                controller: fbCtlr, hint: 'Facebook Page', title: 'Facebook', hasImageUpload: false, validationRequired: false),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: buildTextField(context,
                                controller: youtubeCtlr,
                                hint: 'Youtube channel url',
                                title: 'Youtube',
                                hasImageUpload: false,
                                validationRequired: false),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: buildTextField(context,
                                controller: twitterCtrl,
                                hint: 'X acount url',
                                title: 'X (Formly Twitter)',
                                hasImageUpload: false,
                                validationRequired: false),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: buildTextField(context,
                                controller: instaCtlr, hint: 'Instagram url', title: 'Instagram', hasImageUpload: false, validationRequired: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}






