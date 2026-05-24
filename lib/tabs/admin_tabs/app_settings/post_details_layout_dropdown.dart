import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_admin/configs/constants.dart';
import 'package:news_admin/tabs/admin_tabs/app_settings/app_setting_providers.dart';

class PostDetailsLayoutDropdown extends ConsumerWidget {
  const PostDetailsLayoutDropdown({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String selectedLayout = ref.watch(postDetailsLayoutProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Post Details Layout',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.normal),
        ),
        const SizedBox(
          height: 10
        ),
        Container(
          padding: const EdgeInsets.only(left: 15, right: 15),
          decoration: BoxDecoration(color: Colors.grey[200], border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(0)),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField(
                  decoration: const InputDecoration(border: InputBorder.none),
                  onChanged: (dynamic value) {
                    ref.read(postDetailsLayoutProvider.notifier).update((state) => value);
                  },
                  value: selectedLayout,
                  hint: const Text('Select Post Details Layout'),
                  items: postDetailsLayoutTypes
                      .map((key, value) {
                        return MapEntry(
                          value,
                          DropdownMenuItem(
                            value: key,
                            child: Text(value),
                          ),
                        );
                      })
                      .values
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
