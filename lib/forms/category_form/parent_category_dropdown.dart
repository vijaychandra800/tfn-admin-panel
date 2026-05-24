import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_admin/models/category.dart';
import '../../providers/categories_provider.dart';

class ParentCategoryDropdown extends ConsumerWidget {
  const ParentCategoryDropdown({
    super.key,
    required this.selectedParentId,
    required this.onChanged,
    required this.category,
  });

  final String? selectedParentId;
  final Function(String?)? onChanged;
  final Category? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    // Checking the selected category is not deleted. If deleted, the value should be null;
    // final String? selectedId = selectedParentId == null
    //     ? null
    //     : categories.where((element) => element.parentId == selectedParentId).isEmpty
    //         ? null
    //         : selectedParentId;

    /*
    Checking some validations
    - Categories that is connected to any subcategoy is not eligible
    - Same category can't be its own subcategory
    */

    final parentCategories = categories.where((element) => element.parentId == null).toList();

    final eligibleCategories = parentCategories.where((element) {
      return element.id != category?.id && parentCategories.any((c) => c.parentId != element.id);
    });

    final bool isMainCategory = category != null && categories.any((c) => c.parentId == category?.id) ? true : false;

    return Visibility(
      visible: !isMainCategory && categories.isNotEmpty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parent Category (For creating Sub-categories)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.normal),
          ),
          const SizedBox(
            height: 10,
          ),
          Container(
            padding: const EdgeInsets.only(left: 15, right: 15),
            decoration: BoxDecoration(color: Colors.grey[200], border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(0)),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField(
                    decoration: const InputDecoration(border: InputBorder.none),
                    onChanged: onChanged,
                    value: selectedParentId,
                    hint: const Text('Select Parent Category'),
                    items: eligibleCategories.map((f) {
                      return DropdownMenuItem(
                        value: f.id,
                        child: Text(f.name),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
