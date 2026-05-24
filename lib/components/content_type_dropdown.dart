import 'package:flutter/material.dart';
import 'package:news_admin/configs/constants.dart';

class ContentTypeDropdown extends StatelessWidget {
  const ContentTypeDropdown({super.key, required this.contentType, required this.onChanged});

  final String contentType;
  final Function onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content Type *',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.normal),
        ),
        const SizedBox(
          height: 10,
        ),
        Container(
          padding: const EdgeInsets.only(left: 15, right: 15),
          decoration: BoxDecoration(color: Colors.grey[200], border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(0)),
          child: DropdownButtonFormField(
            decoration: const InputDecoration(border: InputBorder.none),
            validator: (value) {
              if (value == null) return 'value is required';
              return null;
            },
            onChanged: (dynamic value) => onChanged(value),
            value: contentType,
            hint: const Text('Select Content Type'),
            items: contentTypes
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
    );
  }
}
