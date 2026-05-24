import 'package:news_admin/models/custom_ad_model.dart';

import '../configs/ad_config.dart';

/// Sub-model of [AppSettingsModel]

class AdsModel {
  final bool? isAdsEnabled, bannerEnbaled, interstitialEnabled, nativeEnabled, customAdsEnabled;
  final int? postIntervalCountInlineAds, clickCountInterstitialAds;
  final List<CustomAdModel>? customAds;

  AdsModel({
    this.isAdsEnabled,
    this.bannerEnbaled,
    this.interstitialEnabled,
    this.nativeEnabled,
    this.postIntervalCountInlineAds,
    this.clickCountInterstitialAds,
    this.customAdsEnabled,
    this.customAds,
  });

  factory AdsModel.fromMap(Map<String, dynamic> d) {
    return AdsModel(
      isAdsEnabled: d['enabled'] ?? false,
      bannerEnbaled: d['banner'] ?? false,
      interstitialEnabled: d['interstitial'] ?? false,
      nativeEnabled: d['native_ads'] ?? false,
      postIntervalCountInlineAds: d['post_interval_count'] ?? AdConfig.postIntervaCountInlineAdsDefault,
      clickCountInterstitialAds: d['click_count'] ?? AdConfig.clickAmountCountInterstitalAdsDefault,
      customAdsEnabled: d['custom_ads_enabled'] ?? false,
      customAds: (d['custom_ads'] as List<dynamic>?)?.map((e) => CustomAdModel.fromMap(e)).toList(),

    );
  }

  static Map<String, dynamic> getMap(AdsModel d) {
    return {
      'enabled': d.isAdsEnabled,
      'banner': d.bannerEnbaled,
      'interstitial': d.interstitialEnabled,
      'native_ads': d.nativeEnabled,
      'post_interval_count': d.postIntervalCountInlineAds,
      'click_count': d.clickCountInterstitialAds,
      'custom_ads_enabled': d.customAdsEnabled,
      'custom_ads': d.customAds?.map((e) => CustomAdModel.getMap(e)).toList(),
    };
  }
}
