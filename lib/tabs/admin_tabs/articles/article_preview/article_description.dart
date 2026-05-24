import 'package:flutter/material.dart';
import '/../components/html_body.dart';

import '../../../../models/article.dart';

class ArticleDescription extends StatelessWidget {
  const ArticleDescription({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: HtmlBody(
        content: article.description,
        isVideoEnabled: true,
        isimageEnabled: true,
        isIframeVideoEnabled: true,
      ),
    );
  }
}
