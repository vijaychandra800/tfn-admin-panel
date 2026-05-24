import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height, this.width, required this.imageString});

  final double? height;
  final double? width;
  final String imageString;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imageString,
      height: height ?? 60,
      width: width ?? 140,
    );
  }
}
