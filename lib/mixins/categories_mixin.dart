import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../forms/category_form/category_form.dart';
import '../mixins/user_mixin.dart';
import '../utils/custom_cache_image.dart';
import '../utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../models/category.dart';
import '../providers/categories_provider.dart';
import '../providers/user_data_provider.dart';
import '../services/firebase_service.dart';
import '../utils/empty_with_image.dart';
import '../components/custom_buttons.dart';
import '../components/dialogs.dart';

mixin CategoriesMixin {
  Widget buildCategories(
    BuildContext context, {
    required WidgetRef ref,
  }) {
    final categories = ref.watch(categoriesProvider);
    final List<Category> mainCategories = categories.where((element) => element.parentId == null).toList();
    return categories.isEmpty
        ? const EmptyPageWithImage(title: 'No categories found')
        : Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: mainCategories.length,
              shrinkWrap: true,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (BuildContext context, int index) {
                final Category category = mainCategories[index];
                final List<Category> subCategories = categories.where((element) => element.parentId == category.id).toList();
                return ListTile(
                  title: _buildListItem(context, category, ref),
                  subtitle: Column(
                    children: subCategories
                        .map(
                          (e) => IntrinsicHeight(
                            child: Row(
                              children: [
                                const VerticalDivider(),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    child: _buildListItem(context, e, ref),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
          );
  }

  ListTile _buildListItem(BuildContext context, Category category, WidgetRef ref) {
    return ListTile(
      minVerticalPadding: 0,
      horizontalTitleGap: 30,
      leading: SizedBox(
        height: 40,
        width: 40,
        child: CustomCacheImage(
          imageUrl: category.thumbnailUrl,
          radius: 3,
        ),
      ),
      title: Text(category.name),
      // subtitle: category.parentId != null ? Text(_parentCategory(category, ref)) : null,
      trailing: Wrap(
        children: [
          CustomButtons.circleButton(context, icon: Icons.edit, tooltip: 'Edit', onPressed: () => _onEdit(context, category)),
          const SizedBox(
            width: 8,
          ),
          CustomButtons.circleButton(context, icon: Icons.delete, tooltip: 'Delete', onPressed: () => _onDelete(context, category, ref)),
        ],
      ),
    );
  }

  void _onDelete(context, Category category, WidgetRef ref) async {
    final deleteBtnController = RoundedLoadingButtonController();
    CustomDialogs.openActionDialog(
      context,
      actionBtnController: deleteBtnController,
      title: 'Delete this category?',
      message: 'Warning: All of the data releated to this categoy will be deleted and this can not be undone!',
      onAction: () async {
        if (UserMixin.hasAdminAccess(ref.read(userDataProvider))) {
          deleteBtnController.start();
          await FirebaseService().deleteContent('categories', category.id);
          await FirebaseService().deleteCategoryRelatedSubCategories(category.id);
          await FirebaseService().deleteCategoryRelatedArticles(category.id);
          await ref.read(categoriesProvider.notifier).getCategories();
          deleteBtnController.success();
          Navigator.pop(context);
          openSuccessToast(context, 'Deleted Successfully!');
        } else {
          openTestingToast(context);
        }
      },
    );
  }

  void _onEdit(BuildContext context, Category category) {
    CustomDialogs.openResponsiveDialog(context, widget: CategoryForm(category: category));
  }
}
