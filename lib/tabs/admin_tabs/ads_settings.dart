import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_admin/components/dialogs.dart';
import 'package:news_admin/forms/custom_ads_form.dart';
import 'package:news_admin/mixins/textfields.dart';
import 'package:news_admin/models/custom_ad_model.dart';
import 'package:news_admin/services/app_service.dart';
import 'package:news_admin/utils/custom_cache_image.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../../components/switch_option.dart';
import '../../mixins/appbar_mixin.dart';
import '../../components/custom_buttons.dart';
import '../../mixins/user_mixin.dart';
import '../../models/ads_model.dart';
import '../../models/app_settings_model.dart';
import '../../providers/user_data_provider.dart';
import '../../services/firebase_service.dart';
import '../../utils/toasts.dart';
import 'app_settings/app_setting_providers.dart';

final adsEnbaledProvider = StateProvider<bool>((ref) => false);
final bannerAdProvider = StateProvider<bool>((ref) => false);
final interstitialAdProvider = StateProvider<bool>((ref) => false);
final nativeAdsProvider = StateProvider<bool>((ref) => false);
final customAdsEnabledProvider = StateProvider<bool>((ref) => false);
final postIntervalCountProvider = Provider<TextEditingController>((ref) => TextEditingController());
final clickAmountCountProvider = Provider<TextEditingController>((ref) => TextEditingController());
final customAdsProvider = StateProvider<List<CustomAdModel>>((ref) => []);

final saveAdSettingsCtlr = Provider<RoundedLoadingButtonController>((ref) => RoundedLoadingButtonController());

class AdsSettings extends ConsumerWidget with TextFields {
  const AdsSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final ads = ref.watch(adsEnbaledProvider);
    final banner = ref.watch(bannerAdProvider);
    final interstitial = ref.watch(interstitialAdProvider);
    final native = ref.watch(nativeAdsProvider);
    final customAdsEnabled = ref.watch(customAdsEnabledProvider);
    final postIntervalCountCtlr = ref.watch(postIntervalCountProvider);
    final clickAmountCountCtlr = ref.watch(clickAmountCountProvider);
    final customAds = ref.watch(customAdsProvider);

    final saveBtnCtlr = ref.watch(saveAdSettingsCtlr);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AppBarMixin.buildTitleBar(context, title: 'Ads Settings', buttons: [
            CustomButtons.submitButton(
              context,
              buttonController: saveBtnCtlr,
              text: 'Save Changes',
              width: 170,
              borderRadius: 25,
              onPressed: () async {
                final AdsModel adsModel = AdsModel(
                  isAdsEnabled: ads,
                  bannerEnbaled: banner,
                  interstitialEnabled: interstitial,
                  nativeEnabled: native,
                  customAdsEnabled: customAdsEnabled,
                  clickCountInterstitialAds: int.parse(clickAmountCountCtlr.text),
                  postIntervalCountInlineAds: int.parse(postIntervalCountCtlr.text),
                  customAds: customAds,
                );
                final appSettingsModel = AppSettingsModel(ads: adsModel);
                final data = AppSettingsModel.getMapAdsSettings(appSettingsModel);

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
          ]),
          settings.isRefreshing
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 30, right: 30, top: 30, bottom: 100),
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                      child: Column(
                        children: [
                          SwitchOption(
                            deafultValue: ads,
                            title: 'Ads Enabled',
                            onChanged: (value) {
                              ref.read(adsEnbaledProvider.notifier).state = value;
                            },
                          ),
                          Visibility(
                            visible: ads == true,
                            child: Column(
                              children: [
                                const Divider(),
                                SwitchOption(
                                  deafultValue: banner,
                                  title: 'Banner Ads',
                                  onChanged: (value) {
                                    ref.read(bannerAdProvider.notifier).state = value;
                                  },
                                ),
                              ],
                            ),
                          ),
                          Visibility(
                            visible: ads == true,
                            child: Column(
                              children: [
                                const Divider(),
                                SwitchOption(
                                  deafultValue: interstitial,
                                  title: 'Interstitial Ads',
                                  onChanged: (value) {
                                    ref.read(interstitialAdProvider.notifier).state = value;
                                  },
                                ),
                              ],
                            ),
                          ),
                          Visibility(
                            visible: ads == true && interstitial == true,
                            child: Column(
                              children: [
                                const Divider(),
                                ListTile(
                                  contentPadding: const EdgeInsets.all(0),
                                  title: const Text('Click amount to Show Interstitial ad'),
                                  subtitle: const Text('Per post click amount to show full screen ad'),
                                  trailing: numberTextfield(clickAmountCountCtlr, 2),
                                )
                              ],
                            ),
                          ),
                          Visibility(
                            visible: ads == true,
                            child: Column(
                              children: [
                                const Divider(),
                                SwitchOption(
                                  deafultValue: native,
                                  title: 'Native Ads',
                                  onChanged: (value) {
                                    ref.read(nativeAdsProvider.notifier).state = value;
                                  },
                                ),
                              ],
                            ),
                          ),
                          Visibility(
                            visible: ads == true && (native == true || customAdsEnabled == true),
                            child: Column(
                              children: [
                                const Divider(),
                                ListTile(
                                  contentPadding: const EdgeInsets.all(0),
                                  title: const Text('Post interval to Show Inline Ads'),
                                  subtitle: const Text('Post interval count to show native/custom ads'),
                                  trailing: numberTextfield(postIntervalCountCtlr, 2),
                                )
                              ],
                            ),
                          ),

                          // Custom Ads
                          Visibility(
                            visible: ads == true,
                            child: Column(
                              children: [
                                const Divider(),
                                ListTile(
                                  contentPadding: const EdgeInsets.all(0),
                                  title: const Text('Custom Ads'),
                                  subtitle: Text(customAdsEnabled ? 'Enabled' : 'Disabled'),
                                  trailing: Wrap(
                                    children: [
                                      CustomButtons.circleButton(
                                        context,
                                        icon: Icons.add,
                                        bgColor: Theme.of(context).primaryColor,
                                        iconColor: Colors.white,
                                        onPressed: () =>
                                            CustomDialogs.openFormDialog(context, widget: const CustomAdsForm(), verticalPaddingPercentage: 0.10),
                                      ),
                                      Switch(
                                        value: customAdsEnabled,
                                        onChanged: (value) {
                                          if (customAds.isEmpty && value == true) {
                                            openFailureToast(context, 'Create A custom ad first');
                                          } else {
                                            ref.read(customAdsEnabledProvider.notifier).state = value;
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: customAds.map((e) {
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                      title: e.title?.isEmpty ?? true ? null : Text(e.title.toString()),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          RichText(
                                            text: TextSpan(
                                              text: 'Target URL: ',
                                              style: DefaultTextStyle.of(context).style,
                                              children: <TextSpan>[
                                                TextSpan(
                                                    text: e.target,
                                                    style: const TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline),
                                                    recognizer: TapGestureRecognizer()
                                                      ..onTap = () {
                                                        AppService().openLink(context, e.target);
                                                      }),
                                              ],
                                            ),
                                          ),
                                          e.actionButtonText?.isEmpty ?? true
                                              ? const SizedBox.shrink()
                                              : RichText(
                                                  text: TextSpan(
                                                    text: 'Action Button Text: ',
                                                    style: DefaultTextStyle.of(context).style,
                                                    children: <TextSpan>[
                                                      TextSpan(
                                                        text: e.actionButtonText,
                                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                        ],
                                      ),
                                      leading: e.imageUrl?.isEmpty ?? true
                                          ? null
                                          : SizedBox(
                                              height: 40,
                                              width: 60,
                                              child: CustomCacheImage(imageUrl: e.imageUrl.toString(), radius: 2),
                                            ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () {
                                          final ads = ref.read(customAdsProvider);
                                          ads.remove(e);
                                          ref.read(customAdsProvider.notifier).state = [...ads];
                                        },
                                      ),
                                    );
                                  }).toList(),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
