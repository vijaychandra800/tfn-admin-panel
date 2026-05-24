import 'package:news_admin/models/article.dart';

/// Submodel of [Article]

class ArticleCategory {
  final String id, name;

  ArticleCategory({required this.id, required this.name});

  factory ArticleCategory.fromMap(Map<String, dynamic> map) {
    return ArticleCategory(
      id: map['id'],
      name: map['name'],
    );
  }

  static Map<String, dynamic> getMap(ArticleCategory d) {
    return {
      'id': d.id,
      'name': d.name,
    };
  }
}
