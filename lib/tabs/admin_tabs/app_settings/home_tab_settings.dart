import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/switch_option.dart';
import 'app_setting_providers.dart';
import 'home_category_dropdown.dart';

class HomeTabSettings extends StatelessWidget {
  const HomeTabSettings({super.key, 
    required this.isFeaturedEnbled,
    required this.isPopularPostsEnabled,
    required this.isLatestPostsEnabled,
    required this.isDrawerMenuEnabled,
    required this.isLogoAtCenter,
    required this.ref,
    required this.isSearchBoxEnbaled,
    required this.isFeatureAutoslide,
  });

  final bool isFeaturedEnbled;
  final bool isPopularPostsEnabled;
  final bool isLatestPostsEnabled;
  final bool isDrawerMenuEnabled;
  final bool isLogoAtCenter;
  final bool isSearchBoxEnbaled;
  final bool isFeatureAutoslide;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchOption(
              deafultValue: isFeaturedEnbled,
              title: 'Featured Section',
              onChanged: (value) {
                ref.read(isFeaturedEnabledProvider.notifier).update((state) => value);
              },
            ),
            SwitchOption(
              deafultValue: isPopularPostsEnabled,
              title: 'Popular Posts',
              onChanged: (value) {
                ref.read(isPopularArticlesEnabledProvider.notifier).update((state) => value);
              },
            ),
            SwitchOption(
              deafultValue: isLatestPostsEnabled,
              title: 'Latest Posts',
              onChanged: (value) {
                ref.read(isLatestArticlesEnabledProvider.notifier).update((state) => value);
              },
            ),
            SwitchOption(
              deafultValue: isDrawerMenuEnabled,
              title: 'Drawer Menubar',
              onChanged: (value) {
                ref.read(isDrawermenuEnabledProvider.notifier).update((state) => value);
              },
            ),
            SwitchOption(
              deafultValue: isLogoAtCenter,
              title: 'Logo Position At Center',
              onChanged: (value) {
                ref.read(isLogoCenterProvider.notifier).update((state) => value);
              },
            ),
            SwitchOption(
              deafultValue: isFeatureAutoslide,
              title: 'Feature Posts Auto Slidable',
              onChanged: (value) {
                ref.read(isFeaturedPostsAutoSlidableProvider.notifier).update((state) => value);
              },
            ),
            SwitchOption(
              deafultValue: isSearchBoxEnbaled,
              title: 'Search Box',
              onChanged: (value) {
                ref.read(isSearchBoxEnabledProvider.notifier).update((state) => value);
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: HomeCategorySelectionDropdown(),
            ),
          ],
        ),
      ),
    );
  }
}