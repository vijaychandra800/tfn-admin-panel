import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:line_icons/line_icons.dart';

import '../services/app_service.dart';

mixin TextFields {
  Widget buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required String title,
    bool hasImageUpload = false,
    bool hasDatePick = false,
    bool hasTimePick = false,
    VoidCallback? onPickImage,
    VoidCallback? onPickDate,
    VoidCallback? onPickTime,
    bool? isPassword,
    bool validationRequired = true,
    bool urlValidationRequired = false,
    int? minLines,
    int? maxLines = 1,
    TextInputType inputType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.normal),
        ),
        const SizedBox(
          height: 10,
        ),
        Container(
          width: double.infinity,
          color: Colors.grey.shade200,
          child: TextFormField(
            maxLines: maxLines,
            minLines: minLines,
            obscureText: isPassword ?? false,
            controller: controller,
            keyboardType: inputType,
            // inputFormatters: hasDatePick || hasTimePick ? [hasDatePick ? DateInputFormatter() : TimeInputFormatter()] : [],
            validator: (value) {
              if (validationRequired && value!.isEmpty) return 'value is empty';
              if (urlValidationRequired && !AppService.isURLValid(value!)) return 'Invalid Url';
              // if (hasTimePick) {
              //   // Regular expression for hh:mm AM/PM format
              //   final RegExp timeRegex = RegExp(r'^(0[1-9]|1[0-2]):[0-5][0-9] (AM|PM)$');
              //   if (!timeRegex.hasMatch(value!)) {
              //     return 'Enter valid time (hh:mm AM/PM)';
              //   }
              // }
              // if (hasDatePick) {
              //   // Regular expression for dd-MM-yyyy format
              //   final RegExp timeRegex = RegExp(r'^(0[1-9]|[12][0-9]|3[01])-(0[1-9]|1[0-2])-\d{4}$');
              //   if (!timeRegex.hasMatch(value!)) {
              //     return 'Enter valid date (dd-MM-yyyy)';
              //   }
              // }
              return null;
            },
            decoration: InputDecoration(
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => controller.clear(),
                    icon: const Icon(Icons.clear),
                  ),
                  Visibility(
                    visible: hasImageUpload,
                    child: IconButton(
                      tooltip: 'Select Image',
                      icon: const Icon(Icons.image_outlined),
                      onPressed: onPickImage,
                    ),
                  ),
                  Visibility(
                    visible: hasDatePick,
                    child: IconButton(
                      tooltip: 'Select Date',
                      icon: const Icon(Icons.calendar_month),
                      onPressed: onPickDate,
                    ),
                  ),
                  Visibility(
                    visible: hasTimePick,
                    child: IconButton(
                      tooltip: 'Select Time',
                      icon: const Icon(LineIcons.clock),
                      onPressed: onPickTime,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  )
                ],
              ),
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSearchTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required Function onSubmitted,
    required Function onClear,
    Color color = Colors.white,
  }) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      child: TextFormField(
        controller: controller,
        onFieldSubmitted: (value) => onSubmitted(value),
        decoration: InputDecoration(
          suffixIcon: IconButton(
            onPressed: () => onClear(),
            icon: const Icon(Icons.clear),
          ),
          hintText: hint,
          border: InputBorder.none,
          alignLabelWithHint: true,
          contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        ),
      ),
    );
  }

  Widget actionTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required String title,
    required List list,
    required Function onSubmitted,
    required Function onDelete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.normal),
        ),
        const SizedBox(
          height: 10,
        ),
        Container(
          color: Colors.grey.shade200,
          child: TextFormField(
            controller: controller,
            onFieldSubmitted: (value) => onSubmitted(value),
            decoration: InputDecoration(
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => onSubmitted(controller.text),
                    icon: const Icon(Icons.send),
                  ),
                  const SizedBox(
                    width: 10,
                  )
                ],
              ),
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
            ),
          ),
        ),
        Column(
          children: list.map((e) {
            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  leading: const Icon(Icons.done),
                  title: Text(e),
                  trailing: IconButton(
                    onPressed: () => onDelete(e),
                    icon: const Icon(Icons.clear),
                  ),
                ),
                const Divider()
              ],
            );
          }).toList(),
        )
      ],
    );
  }

  Widget commentTextField(
    BuildContext context, {
    required TextEditingController controller,
    required Function onSubmitted,
  }) {
    return Container(
      height: 60,
      color: Colors.grey.shade200,
      child: TextFormField(
        controller: controller,
        onFieldSubmitted: (value) => onSubmitted(),
        decoration: InputDecoration(
          suffixIcon: IconButton(
            onPressed: () => onSubmitted(),
            icon: const Icon(Icons.send),
          ),
          hintText: 'Write comment',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
        ),
      ),
    );
  }

  Container numberTextfield(TextEditingController controller, int length) {
    return Container(
      width: 60,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: TextFormField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(length)],
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.only(left: 5, right: 5),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
