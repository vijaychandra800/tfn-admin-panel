import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/switch_option.dart';
import '../../../mixins/textfields.dart';
import 'app_setting_providers.dart';
import 'category_tile_layout_dropdown.dart';

class OthersSettings extends StatelessWidget with TextFields {
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
        decoration:
            BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CategoryTileLayoutDropdown(),
            const SizedBox(height: 15),
            SwitchOption(
                deafultValue: onBoardingEnabled,
                title: 'On Boarding',
                onChanged: (value) {
                  ref
                      .read(isOnboardingEnabledProvider.notifier)
                      .update((state) => value);
                }),
            SwitchOption(
                deafultValue: isSkipLoginEnabled,
                title: 'Skip Login',
                onChanged: (value) {
                  ref
                      .read(isSkipLoginEnabledProvider.notifier)
                      .update((state) => value);
                }),
            SwitchOption(
                deafultValue: isDateEnbaled,
                title: 'Date Time',
                onChanged: (value) {
                  ref
                      .read(isDateEnabledProvider.notifier)
                      .update((state) => value);
                }),
            SwitchOption(
                deafultValue: isVideoEnabled,
                title: 'Video Tab',
                onChanged: (value) {
                  ref
                      .read(isVideoTabEnabledProvider.notifier)
                      .update((state) => value);
                }),
            SwitchOption(
                deafultValue: isAudioTabEnabled,
                title: 'Audio Tab',
                onChanged: (value) {
                  ref
                      .read(isAudioTabEnabledProvider.notifier)
                      .update((state) => value);
                }),
            const SizedBox(height: 25),
            Text(
              'Fanzone Chat Lifespan',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'After an event ends, its chat stays visible but becomes read-only for the hours below, '
              'then all of its comments are deleted automatically after the number of days below.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            buildTextField(
              context,
              controller: ref.watch(chatReadOnlyHoursProvider),
              hint: 'e.g. 72',
              title: 'Read-only after event ends (hours) — recommended 48–72',
              hasImageUpload: false,
              validationRequired: false,
              inputType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            buildTextField(
              context,
              controller: ref.watch(chatPurgeDaysProvider),
              hint: 'e.g. 7',
              title: 'Delete chat after event ends (days) — recommended 5–7',
              hasImageUpload: false,
              validationRequired: false,
              inputType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
}
