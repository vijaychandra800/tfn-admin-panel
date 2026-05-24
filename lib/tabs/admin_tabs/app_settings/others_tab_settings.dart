import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/switch_option.dart';
import 'app_setting_providers.dart';
import 'category_tile_layout_dropdown.dart';

class OthersSettings extends StatelessWidget {
  const OthersSettings({
    super.key,
    required this.onBoardingEnabled,
    required this.isSkipLoginEnabled,
    required this.isVideoEnabled,
    required this.isAudioTabEnabled,
    required this.isDateEnbaled,
    required this.ref,
  });

  final bool onBoardingEnabled;
  final bool isSkipLoginEnabled;
  final bool isVideoEnabled;
  final bool isAudioTabEnabled;
  final bool isDateEnbaled;
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
            const CategoryTileLayoutDropdown(),
            const SizedBox(height: 15),
            SwitchOption(
                deafultValue: onBoardingEnabled,
                title: 'On Boarding',
                onChanged: (value) {
                  ref.read(isOnboardingEnabledProvider.notifier).update((state) => value);
                }),
            SwitchOption(
                deafultValue: isSkipLoginEnabled,
                title: 'Skip Login',
                onChanged: (value) {
                  ref.read(isSkipLoginEnabledProvider.notifier).update((state) => value);
                }),
            SwitchOption(
                deafultValue: isDateEnbaled,
                title: 'Date Time',
                onChanged: (value) {
                  ref.read(isDateEnabledProvider.notifier).update((state) => value);
                }),
            SwitchOption(
                deafultValue: isVideoEnabled,
                title: 'Video Tab',
                onChanged: (value) {
                  ref.read(isVideoTabEnabledProvider.notifier).update((state) => value);
                }),
            SwitchOption(
                deafultValue: isAudioTabEnabled,
                title: 'Audio Tab',
                onChanged: (value) {
                  ref.read(isAudioTabEnabledProvider.notifier).update((state) => value);
                }),
          ],
        ),
      ),
    );
  }
}