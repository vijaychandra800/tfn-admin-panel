import 'package:flutter/material.dart';

class ExtendedTag extends StatelessWidget {
  const ExtendedTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.all(Radius.circular(1)),
      ),
      child: Text(
        'Extended',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontSize: 11),
      ),
    );
  }
}