class CustomAdModel {
  final String? title;
  final String? actionButtonText;
  final String target;
  final String? imageUrl;

  CustomAdModel({
    required this.target,
    this.imageUrl,
    this.title,
    this.actionButtonText,
  });

  factory CustomAdModel.fromMap(Map<String, dynamic> d) {
    return CustomAdModel(
      target: d['target'],
      imageUrl: d['image'],
      title: d['title'],
      actionButtonText: d['action_text'],
    );
  }

  static Map<String, dynamic> getMap(CustomAdModel d) {
    return {
      'target': d.target,
      'image': d.imageUrl,
      'title': d.title,
      'action_text': d.actionButtonText,
    };
  }
}
