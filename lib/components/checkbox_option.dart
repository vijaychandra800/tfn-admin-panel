import 'package:flutter/material.dart';

class CheckBoxOption extends StatelessWidget {
  const CheckBoxOption({super.key, required this.defaultvalue, required this.onChanged, required this.title});

  final bool defaultvalue;
  final Function onChanged;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Checkbox(
          activeColor: Theme.of(context).primaryColor,
          onChanged: (bool? value) => onChanged(value),
          value: defaultvalue,
        ),
        const SizedBox(width: 5),
        Text(title),
      ],
    );
  }
}
