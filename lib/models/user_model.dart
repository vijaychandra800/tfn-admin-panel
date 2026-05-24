import 'package:cloud_firestore/cloud_firestore.dart';
import 'subscription.dart';

class UserModel {
  final String id, email, name;
  DateTime? createdAt;
  DateTime? updatedAt;
  final String? imageUrl;
  List? role;
  List? bookmarks;
  bool? isDisbaled;
  Subscription? subscription;
  String? platform;

  UserModel({
    required this.id,
    required this.email,
    this.imageUrl,
    required this.name,
    this.role,
    this.bookmarks,
    this.isDisbaled,
    this.createdAt,
    this.updatedAt,
    this.subscription,
    this.platform,
  });

  factory UserModel.fromFirebase(DocumentSnapshot snap) {
    Map d = snap.data() as Map<String, dynamic>;
    return UserModel(
      id: snap.id,
      email: d['email'],
      imageUrl: d['image_url'],
      name: d['name'],
      role: d['role'] ?? [],
      isDisbaled: d['disabled'] ?? false,
      createdAt: d['created_at'] == null ? null : (d['created_at'] as Timestamp).toDate().toLocal(),
      updatedAt: d['updated_at'] == null ? null : (d['updated_at'] as Timestamp).toDate().toLocal(),
      bookmarks: d['bookmarks'] ?? [],
      subscription: d['subscription'] == null ? null : Subscription.fromFirestore(d['subscription']),
      platform: d['platform'],
    );
  }

  static Map<String, dynamic> getMap (UserModel d){
    return {
      'name': d.name,
      'email': d.email,
      'created_at': d.createdAt,
      'role': d.role
    };
  }
}
