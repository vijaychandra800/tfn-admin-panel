import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../mixins/appbar_mixin.dart';
import '../../../mixins/categories_mixin.dart';
import '../../../components/custom_buttons.dart';
import '../../../components/dialogs.dart';
import '../../../forms/category_form/category_form.dart';

class Categories extends ConsumerWidget with CategoriesMixin {
  const Categories({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AppBarMixin.buildTitleBar(context, title: 'Categories', buttons: [
            // CustomButtons.customOutlineButton(
            //   context,
            //   icon: LineIcons.sortAmountDown,
            //   text: 'Set Order',
            //   bgColor: Theme.of(context).primaryColor,
            //   foregroundColor: Colors.white,
            //   onPressed: () {
            //     CustomDialogs.openResponsiveDialog(context, widget: const SetCategoryOrder());
            //   },
            // ),
            // const SizedBox(width: 10),
            CustomButtons.customOutlineButton(
              context,
              icon: Icons.add,
              text: 'Add Category',
              bgColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              onPressed: () {
                CustomDialogs.openResponsiveDialog(context, widget: const CategoryForm(category: null));
              },
            ),
          ]),
          buildCategories(context, ref: ref)
        ],
      ),
    );
  }
}
