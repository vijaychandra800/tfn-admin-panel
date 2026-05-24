import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_admin/models/app_settings_model.dart';
import 'package:news_admin/tabs/admin_tabs/app_settings/app_setting_providers.dart';
import 'package:news_admin/utils/toasts.dart';
import '../../../providers/categories_provider.dart';

class HomeCategorySelectionDropdown extends ConsumerWidget {
  const HomeCategorySelectionDropdown({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final selectedCategories = ref.watch(homeCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Home Categories',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.normal),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: Colors.grey[200], border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(0)),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField(
                  decoration: const InputDecoration(border: InputBorder.none),
                  onChanged: (dynamic value) {
                    final newData = HomeCategory(id: value.id, name: value.name);
                    final bool isAlreadyAvaibale = selectedCategories.where((element) => element.id == newData.id).toList().isNotEmpty;
                    // Maximum limit is 10
                    if (!isAlreadyAvaibale && selectedCategories.length < 10) {
                      final List newList = selectedCategories;
                      newList.add(newData);
                      ref.read(homeCategoriesProvider.notifier).update((state) => [...newList]);
                    } else {
                      openFailureToast(context, 'Duplicate selection or maximum limit is 10!');
                    }
                  },
                  hint: const Text('Select Category'),
                  items: categories.map((f) {
                    return DropdownMenuItem(
                      value: f,
                      child: Text(f.name),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        //selected categories
        ListView.separated(
          itemCount: selectedCategories.length,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shrinkWrap: true,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final hc = selectedCategories[index];
            return ListTile(
              leading: CircleAvatar(radius: 16, backgroundColor: Colors.grey.shade400, child: Text('${index + 1}')),
              title: Text(hc.name),
              trailing: IconButton(
                onPressed: () {
                  final List data = selectedCategories;
                  data.removeAt(index);
                  ref.read(homeCategoriesProvider.notifier).update((state) => [...data]);
                },
                icon: const Icon(Icons.clear),
              ),
            );
          },
        )
      ],
    );
  }
}
