import 'package:flutter/material.dart';
import 'package:news_admin/components/extended_tag.dart';

class SwitchOption extends StatelessWidget {
  const SwitchOption({
    super.key,
    required this.onChanged,
    required this.title,
    required this.deafultValue,
    this.icon,
    this.showExtendedTag,
  });

  final Function onChanged;
  final String title;
  final bool deafultValue;
  final IconData? icon;
  final bool? showExtendedTag;

  @override
  Widget build(BuildContext context) {
    return ListTile(
        subtitle: Text(deafultValue ? 'Enabled' : 'Disabled'),
        contentPadding: const EdgeInsets.all(0),
        title: Wrap(
          children: [
            Text(title),
            showExtendedTag == true ? const ExtendedTag() : const SizedBox.shrink(),
          ],
        ),
        leading: icon == null
            ? null
            : CircleAvatar(
              backgroundColor: Colors.grey.shade300,
                child: Icon(icon),
              ),
        trailing: Switch(
          value: deafultValue,
          onChanged: (bool value) => onChanged(value),
        ));
  }
}
