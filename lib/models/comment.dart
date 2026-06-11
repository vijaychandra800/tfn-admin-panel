import 'package:cloud_firestore/cloud_firestore.dart';
import 'comment_user.dart';

class Comment {
  static const String typeArticle = 'article';
  static const String typeEvent = 'event';

  final String id;

  /// 'article' or 'event'.
  final String targetType;
  final String targetId;
  final String targetTitle;
  final String? articleAuthorId;
  final String comment;
  final CommentUser commentUser;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.targetTitle,
    this.articleAuthorId,
    required this.commentUser,
    required this.createdAt,
    required this.comment,
  });

  // Back-compat aliases.
  String get articleId => targetId;
  String get articleTitle => targetTitle;

  factory Comment.fromFirebase(DocumentSnapshot snap) {
    Map d = snap.data() as Map<String, dynamic>;
    final String type = (d['target_type'] as String?) ?? typeArticle;
    final String tId =
        (d['target_id'] as String?) ?? (d['article_id'] as String? ?? '');
    final String tTitle =
        (d['target_title'] as String?) ?? (d['article_title'] as String? ?? '');
    return Comment(
      id: snap.id,
      targetType: type,
      targetId: tId,
      targetTitle: tTitle,
      articleAuthorId: d['article_author_id'] as String?,
      comment: d['comment'],
      createdAt: (d['created_at'] as Timestamp).toDate(),
      commentUser: CommentUser.fromFirebase(d['user']),
    );
  }

  static Map<String, dynamic> getMap(Comment d) {
    final isArticle = d.targetType == typeArticle;
    return {
      'target_type': d.targetType,
      'target_id': d.targetId,
      'target_title': d.targetTitle,
      if (isArticle) 'article_id': d.targetId,
      if (isArticle) 'article_title': d.targetTitle,
      if (isArticle && d.articleAuthorId != null)
        'article_author_id': d.articleAuthorId,
      'comment': d.comment,
      'created_at': d.createdAt,
      'user': CommentUser.getMap(d.commentUser),
    };
  }
}
