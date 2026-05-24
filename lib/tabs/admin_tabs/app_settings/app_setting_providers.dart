import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_admin/configs/ad_config.dart';
import 'package:news_admin/configs/constants.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';

import '../../../models/app_settings_model.dart';
import '../../../services/firebase_service.dart';
import '../ads_settings.dart';

final saveSettingsBtnProvider = Provider<RoundedLoadingButtonController>((ref) => RoundedLoadingButtonController());

final isFeaturedEnabledProvider = StateProvider<bool>((ref) => true);
final isPopularArticlesEnabledProvider = StateProvider<bool>((ref) => true);
final isLatestArticlesEnabledProvider = StateProvider((ref) => true);
final isCommentsEnabledProvider = StateProvider((ref) => true);
final isViewsEnabledProvider = StateProvider((ref) => true);
final isLikesEnabledProvider = StateProvider((ref) => true);
final isAuthorInfoEnabledProvider = StateProvider((ref) => true);
final isVideoTabEnabledProvider = StateProvider((ref) => true);
final isAudioTabEnabledProvider = StateProvider((ref) => false);
final isDrawermenuEnabledProvider = StateProvider((ref) => true);
final isLogoCenterProvider = StateProvider((ref) => true);
final isReadingTimeEnabledProvider = StateProvider((ref) => true);
final isSearchBoxEnabledProvider = StateProvider((ref) => true);
final isFeaturedPostsAutoSlidableProvider = StateProvider((ref) => true);
final isDateEnabledProvider = StateProvider<bool>((ref) => true);


final postDetailsLayoutProvider = StateProvider<String>((ref) => postDetailsLayoutTypes.keys.elementAt(0));
final homeCategoriesProvider = StateProvider<List<HomeCategory>>((ref) => []);
final isTagsEnabledProvider = StateProvider<bool>((ref) => true);
final categoryTileLayoutProvider = StateProvider((ref) => categoryTileLayoutTypes.keys.elementAt(0));

final websiteTextfieldProvider = Provider<TextEditingController>((ref) => TextEditingController());
final supportEmailTextfieldProvider = Provider<TextEditingController>((ref) => TextEditingController());
final privacyUrlTextfieldProvider = Provider<TextEditingController>((ref) => TextEditingController());
final termsOfUserTextfieldProvider = Provider<TextEditingController>((ref) => TextEditingController());

final isSkipLoginEnabledProvider = StateProvider<bool>((ref) => false);
final isOnboardingEnabledProvider = StateProvider<bool>((ref) => true);

final fbProvider = Provider<TextEditingController>((ref) => TextEditingController());
final youtubeProvider = Provider<TextEditingController>((ref) => TextEditingController());
final twitterProvider = Provider<TextEditingController>((ref) => TextEditingController());
final instaProvider = Provider<TextEditingController>((ref) => TextEditingController());


final appSettingsProvider = FutureProvider<AppSettingsModel?>((ref) async {
  final AppSettingsModel? settings = await FirebaseService().getAppSettings();

  // Update the other providers based on the ads data
  if (settings != null) {
    ref.read(isFeaturedEnabledProvider.notifier).state = settings.featured!;
    ref.read(isSkipLoginEnabledProvider.notifier).state = settings.skipLogin!;
    ref.read(isLatestArticlesEnabledProvider.notifier).state = settings.latestArticles!;
    ref.read(isTagsEnabledProvider.notifier).state = settings.tags!;
    ref.read(isSkipLoginEnabledProvider.notifier).state = settings.skipLogin!;
    ref.read(isOnboardingEnabledProvider.notifier).state = settings.onBoarding!;

    ref.read(isViewsEnabledProvider.notifier).state = settings.views!;
    ref.read(isLikesEnabledProvider.notifier).state = settings.likes!;
    ref.read(isCommentsEnabledProvider.notifier).state = settings.comments!;
    ref.read(isPopularArticlesEnabledProvider.notifier).state = settings.popular!;
    ref.read(isAuthorInfoEnabledProvider.notifier).state = settings.author!;
    ref.read(isReadingTimeEnabledProvider.notifier).state = settings.readingTime!;
    ref.read(isSearchBoxEnabledProvider.notifier).state = settings.searchBox!;
    ref.read(isFeaturedEnabledProvider.notifier).state = settings.featureAutoSlide!;
    ref.read(isDateEnabledProvider.notifier).state = settings.date!;


    ref.read(isVideoTabEnabledProvider.notifier).state = settings.videoTab!;
    ref.read(isAudioTabEnabledProvider.notifier).state = settings.audioTab!;
    ref.read(isDrawermenuEnabledProvider.notifier).state = settings.drawerMenu!;
    ref.read(isLogoCenterProvider.notifier).state = settings.logoAtCenter!;
    ref.read(postDetailsLayoutProvider.notifier).state = settings.postDetailsLayout!;
    ref.read(categoryTileLayoutProvider.notifier).state = settings.categoryTileLayout!;

    ref.read(homeCategoriesProvider.notifier).state = [...settings.homeCategories ?? []];

    ref.read(fbProvider).text = settings.social?.fb ?? '';
    ref.read(instaProvider).text = settings.social?.instagram ?? '';
    ref.read(youtubeProvider).text = settings.social?.youtube ?? '';
    ref.read(twitterProvider).text = settings.social?.twitter ?? '';
    ref.read(websiteTextfieldProvider).text = settings.website ?? '';
    ref.read(supportEmailTextfieldProvider).text = settings.supportEmail ?? '';
    ref.read(privacyUrlTextfieldProvider).text = settings.privacyUrl ?? '';
    ref.read(termsOfUserTextfieldProvider).text = settings.termsOfUseUrl ?? '';


    ref.read(adsEnbaledProvider.notifier).state = settings.ads?.isAdsEnabled ?? false;
    ref.read(bannerAdProvider.notifier).state = settings.ads?.bannerEnbaled ?? false;
    ref.read(interstitialAdProvider.notifier).state = settings.ads?.interstitialEnabled ?? false;
    ref.read(nativeAdsProvider.notifier).state = settings.ads?.nativeEnabled ?? false;
    ref.read(customAdsEnabledProvider.notifier).state = settings.ads?.customAdsEnabled ?? false;
    ref.read(clickAmountCountProvider).text = settings.ads?.clickCountInterstitialAds.toString() ?? AdConfig.clickAmountCountInterstitalAdsDefault.toString();
    ref.read(postIntervalCountProvider).text = settings.ads?.postIntervalCountInlineAds.toString() ?? AdConfig.postIntervaCountInlineAdsDefault.toString();
    ref.read(customAdsProvider.notifier).state = [...settings.ads?.customAds ?? []];

  }

  return settings;
});
