// Sub-model of Review

class CommentUser {
  final String id, name;
  final String? imageUrl;

  CommentUser({required this.id, required this.name, this.imageUrl});

  factory CommentUser.fromFirebase(Map<String, dynamic> d) {
    return CommentUser(
      id: d['id'],
      name: d['name'],
      imageUrl: d['image_url'],
    );
  }

  static Map<String, dynamic> getMap(CommentUser d) {
    return {'id': d.id, 'name': d.name, 'image_url': d.imageUrl};
  }
}