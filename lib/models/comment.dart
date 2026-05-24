import 'package:cloud_firestore/cloud_firestore.dart';
import 'comment_user.dart';

class Comment {
  final String id, articleId, articleAuthorId, articleTitle, comment;
  final CommentUser commentUser;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.articleId,
    required this.articleAuthorId,
    required this.articleTitle,
    required this.commentUser,
    required this.createdAt,
    required this.comment,
  });

  factory Comment.fromFirebase(DocumentSnapshot snap) {
    Map d = snap.data() as Map<String, dynamic>;
    return Comment(
      id: snap.id,
      articleId: d['article_id'],
      articleAuthorId: d['article_author_id'],
      articleTitle: d['article_title'],
      comment: d['comment'],
      createdAt: (d['created_at'] as Timestamp).toDate(),
      commentUser: CommentUser.fromFirebase(d['user']),
    );
  }

  static Map<String, dynamic> getMap (Comment d){
    return {
      'article_id': d.articleId,
      'article_author_id': d.articleAuthorId,
      'article_title': d.articleTitle,
      'comment': d.comment,
      'created_at': d.createdAt,
      'user': CommentUser.getMap(d.commentUser),
    };
  }

  
}
