import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:news_admin/configs/constants.dart';
import 'package:news_admin/models/article.dart';
import 'package:news_admin/services/app_service.dart';

class ArticleMediaButton extends StatelessWidget {
  const ArticleMediaButton({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    // Video
    if (article.contentType == contentTypes.keys.elementAt(1) && article.videoUrl != null && article.videoUrl != '') {
      return Align(
        alignment: Alignment.center,
        child: IconButton(
          onPressed: () => AppService().openLink(context, article.videoUrl.toString()),
          icon: const Icon(LineIcons.play, size: 50, color: Colors.white,),
        ),
      );

      // Audio
    } else if (article.contentType == contentTypes.keys.elementAt(2) && article.audioUrl != null && article.audioUrl != '') {
      return Align(
        alignment: Alignment.center,
        child: IconButton(
          onPressed: () => AppService().openLink(context, article.audioUrl.toString()),
          icon: const Icon(LineIcons.audioFile, size: 50, color: Colors.white,),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
