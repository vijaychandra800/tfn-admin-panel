import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_admin/configs/constants.dart';
import 'ads_model.dart';

enum LicenseType { none, regular, extended }

class AppSettingsModel {
  final bool? featured,
      tags,
      skipLogin,
      onBoarding,
      latestArticles,
      popular,
      comments,
      author,
      views,
      likes,
      videoTab,
      audioTab,
      drawerMenu,
      logoAtCenter,
      readingTime,
      searchBox,
      featureAutoSlide,
      date;
  final String? supportEmail, website, privacyUrl, termsOfUseUrl;
  List<HomeCategory>? homeCategories;
  final AppSettingsSocialInfo? social;
  final AdsModel? ads;
  final LicenseType? license;
  final String? postDetailsLayout, categoryTileLayout;

  AppSettingsModel({
    this.featured,
    this.tags,
    this.onBoarding,
    this.supportEmail,
    this.website,
    this.privacyUrl,
    this.homeCategories,
    this.social,
    this.skipLogin,
    this.latestArticles,
    this.ads,
    this.license,
    this.popular,
    this.comments,
    this.author,
    this.views,
    this.likes,
    this.videoTab,
    this.audioTab,
    this.drawerMenu,
    this.logoAtCenter,
    this.postDetailsLayout,
    this.categoryTileLayout,
    this.readingTime,
    this.searchBox,
    this.featureAutoSlide,
    this.date,
    this.termsOfUseUrl,
  });

  factory AppSettingsModel.fromFirestore(DocumentSnapshot snap) {
    final Map d = snap.data() as Map<String, dynamic>;
    return AppSettingsModel(
      featured: d['featured'] ?? true,
      onBoarding: d['onboarding'] ?? true,
      skipLogin: d['skip_login'] ?? false,
      latestArticles: d['latest_articles'] ?? true,
      tags: d['tags'] ?? true,
      supportEmail: d['email'],
      privacyUrl: d['privacy_url'],
      website: d['website'],
      social: d['social'] != null ? AppSettingsSocialInfo.fromMap(d['social']) : null,
      ads: d['ads'] != null ? AdsModel.fromMap(d['ads']) : null,
      license: _getLicenseType(d['license']),
      popular: d['popular'] ?? true,
      comments: d['comments'] ?? true,
      likes: d['likes'] ?? true,
      views: d['views'] ?? true,
      author: d['author'] ?? true,
      videoTab: d['video_tab'] ?? true,
      audioTab: d['audio_tab'] ?? false,
      drawerMenu: d['drawer_menu'] ?? true,
      logoAtCenter: d['logo_center'] ?? false,
      postDetailsLayout: d['post_details_layout'] ?? postDetailsLayoutTypes.keys.elementAt(0),
      categoryTileLayout: d['category_tile_layout'] ?? categoryTileLayoutTypes.keys.elementAt(0),
      homeCategories: (d['home_categories'] as List<dynamic>?)?.map((e) => HomeCategory.fromMap(e)).toList(),
      readingTime: d['reading_time'] ?? true,
      searchBox: d['search_box'] ?? true,
      featureAutoSlide: d['feature_autoslide'] ?? true,
      date: d['date'] ?? true,
      termsOfUseUrl: d['terms_of_use'],
    );
  }

  static LicenseType _getLicenseType(String? value) {
    if (value == 'regular') {
      return LicenseType.regular;
    } else if (value == 'extended') {
      return LicenseType.extended;
    } else {
      return LicenseType.none;
    }
  }

  static Map<String, dynamic> getMap(AppSettingsModel d) {
    return {
      'featured': d.featured,
      'onboarding': d.onBoarding,
      'skip_login': d.skipLogin,
      'latest_articles': d.latestArticles,
      'tags': d.tags,
      'email': d.supportEmail,
      'privacy_url': d.privacyUrl,
      'website': d.website,
      'social': d.social != null ? AppSettingsSocialInfo.getMap(d.social!) : null,
      'popular': d.popular,
      'comments': d.comments,
      'likes': d.likes,
      'views': d.views,
      'author': d.author,
      'video_tab': d.videoTab,
      'audio_tab': d.audioTab,
      'drawer_menu': d.drawerMenu,
      'logo_center': d.logoAtCenter,
      'post_details_layout': d.postDetailsLayout,
      'category_tile_layout': d.categoryTileLayout,
      'home_categories': d.homeCategories?.map((e) => HomeCategory.getMap(e)).toList(),
      'reading_time': d.readingTime,
      'feature_autoslide': d.featureAutoSlide,
      'search_box': d.searchBox,
      'date': d.date,
      'terms_of_use': d.termsOfUseUrl,
    };
  }

  static Map<String, dynamic> getMapAdsSettings(AppSettingsModel d) {
    return {
      'ads': d.ads != null ? AdsModel.getMap(d.ads!) : null,
    };
  }

  static Map<String, dynamic> getMapLicense(AppSettingsModel d) {
    final String? licenseString = _getLicenseString(d);
    return {
      'license': licenseString,
    };
  }

  static String? _getLicenseString(AppSettingsModel d) {
    if (d.license == LicenseType.regular) {
      return 'regular';
    } else if (d.license == LicenseType.extended) {
      return 'extended';
    } else {
      return null;
    }
  }
}

class HomeCategory {
  final String id, name;

  HomeCategory({required this.id, required this.name});

  factory HomeCategory.fromMap(Map<String, dynamic> d) {
    return HomeCategory(
      id: d['id'],
      name: d['name'],
    );
  }

  static Map<String, dynamic> getMap(HomeCategory d) {
    return {
      'id': d.id,
      'name': d.name,
    };
  }
}

class AppSettingsSocialInfo {
  final String? fb, youtube, twitter, instagram;

  AppSettingsSocialInfo({required this.fb, required this.youtube, required this.twitter, required this.instagram});

  factory AppSettingsSocialInfo.fromMap(Map<String, dynamic> d) {
    return AppSettingsSocialInfo(
      fb: d['fb'],
      youtube: d['youtube'],
      instagram: d['instagram'],
      twitter: d['twitter'],
    );
  }

  static Map<String, dynamic> getMap(AppSettingsSocialInfo d) {
    return {
      'fb': d.fb,
      'youtube': d.youtube,
      'instagram': d.instagram,
      'twitter': d.twitter,
    };
  }
}
