import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/switch_option.dart';
import 'app_setting_providers.dart';
import 'post_details_layout_dropdown.dart';

class PostDetailsSettings extends StatelessWidget {
  const PostDetailsSettings({
    super.key,
    required this.isTagsEnabled,
    required this.isViewsEnabled,
    required this.isLikesEnabled,
    required this.isCommentsEnabled,
    required this.isAuthorInfoEnabled,
    required this.isReadingTimeEnabled,
    required this.ref,
  });

  final bool isTagsEnabled;
  final bool isViewsEnabled;
  final bool isLikesEnabled;
  final bool isCommentsEnabled;
  final bool isAuthorInfoEnabled;
  final bool isReadingTimeEnabled;
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
            const PostDetailsLayoutDropdown(),
            const SizedBox(height: 15),
            SwitchOption(
              deafultValue: isTagsEnabled,
              title: 'Show Tags',
              onChanged: (value) {
                ref.read(isTagsEnabledProvider.notifier).update((state) => value);
              },
            ),
            SwitchOption(
              deafultValue: isViewsEnabled,
              title: 'Post Views',
              onChanged: (value) {
                ref.read(isViewsEnabledProvider.notifier).update((state) => value);
              },
            ),
            SwitchOption(
              deafultValue: isLikesEnabled,
              title: 'Post Likes',
              onChanged: (value) {
                ref.read(isLikesEnabledProvider.notifier).update((state) => value);
              },
            ),
            SwitchOption(
              deafultValue: isCommentsEnabled,
              title: 'Post Comments',
              onChanged: (value) {
                ref.read(isCommentsEnabledProvider.notifier).update((state) => value);
              },
            ),
            SwitchOption(
              deafultValue: isAuthorInfoEnabled,
              title: 'Author Info',
              onChanged: (value) {
                ref.read(isAuthorInfoEnabledProvider.notifier).update((state) => value);
              },
            ),
            SwitchOption(
              deafultValue: isReadingTimeEnabled,
              title: 'Reading Time',
              onChanged: (value) {
                ref.read(isReadingTimeEnabledProvider.notifier).update((state) => value);
              },
            ),
          ],
        ),
      ),
    );
  }
}