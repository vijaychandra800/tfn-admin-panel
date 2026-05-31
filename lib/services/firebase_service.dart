import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:news_admin/models/comment.dart';
import 'package:news_admin/models/event.dart';
import 'package:news_admin/models/poll.dart';
import '../configs/constants.dart';
import '../models/notification_model.dart';
import '../models/app_settings_model.dart';
import '../models/category.dart';
import '../models/purchase_history.dart';
import '../models/tag.dart';
import '../models/chart_model.dart';
import '../models/article.dart';
import '../models/user_model.dart';

class FirebaseService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static String getUID(String collectionName) =>
      FirebaseFirestore.instance.collection(collectionName).doc().id;

  Future deleteContent(String collectionName, String documentName) async {
    await firestore.collection(collectionName).doc(documentName).delete();
  }

  Future updateUserAccess(
      {required String userId, required bool shouldDisable}) async {
    return await firestore
        .collection('users')
        .doc(userId)
        .update({'disabled': shouldDisable});
  }

  Future updateAuthorAccess(
      {required String userId, required bool shouldAssign}) async {
    final Map<String, dynamic> data = shouldAssign
        ? {
            'role': ['author']
          }
        : {'role': null};
    return await firestore
        .collection('users')
        .doc(userId)
        .set(data, SetOptions(merge: true));
  }

  Future updateFeaturedArticle(Article article, bool value) async {
    await firestore
        .collection('articles')
        .doc(article.id)
        .update({'featured': value});
  }

  Future<String?> uploadImageToFirebaseHosting(
      XFile image, String folderName) async {
    //return download link
    Uint8List imageData = await XFile(image.path).readAsBytes();
    String fileName = image.name.split('.').first;
    final Reference storageReference =
        FirebaseStorage.instance.ref().child('$folderName/$fileName.png');
    final SettableMetadata metadata =
        SettableMetadata(contentType: 'image/png');
    final UploadTask uploadTask = storageReference.putData(imageData, metadata);
    final TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
    String? imageUrl = await snapshot.ref.getDownloadURL();
    return imageUrl;
  }

  Future<UserModel?> getUserData() async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final DocumentSnapshot snap =
        await firestore.collection('users').doc(userId).get();
    UserModel? user = UserModel.fromFirebase(snap);
    return user;
  }

  Future saveCategory(Category category) async {
    const String collectionName = 'categories';
    Map<String, dynamic> data = Category.getMap(category);
    await firestore
        .collection(collectionName)
        .doc(category.id)
        .set(data, SetOptions(merge: true));
  }

  Future saveArticle(Article article) async {
    final Map<String, dynamic> data = Article.getMap(article);
    await firestore
        .collection('articles')
        .doc(article.id)
        .set(data, SetOptions(merge: true));
  }

  Future saveEvent(Event event) async {
    final Map<String, dynamic> data = Event.getMap(event);
    await firestore
        .collection('events')
        .doc(event.id)
        .set(data, SetOptions(merge: true));
  }

  // ---------------- Polls ----------------

  CollectionReference _pollsRef(String eventId) =>
      firestore.collection('events').doc(eventId).collection('polls');

  Future savePoll(Poll poll) async {
    final Map<String, dynamic> data = Poll.getMap(poll);
    await _pollsRef(poll.eventId)
        .doc(poll.id)
        .set(data, SetOptions(merge: true));
  }

  Future deletePoll(String eventId, String pollId) async {
    await _pollsRef(eventId).doc(pollId).delete();
  }

  Stream<List<Poll>> pollsStream(String eventId) {
    return _pollsRef(eventId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((e) => Poll.fromFirestore(e)).toList());
  }

  Future saveNotification(NotificationModel notification) async {
    final Map<String, dynamic> data = NotificationModel.getMap(notification);
    await firestore.collection('notifications').doc(notification.id).set(data);
  }

  Future<List<Category>> getCategories() async {
    List<Category> data = [];
    await firestore
        .collection('categories')
        .orderBy('created_at', descending: true)
        .get()
        .then((QuerySnapshot? snapshot) {
      data = snapshot!.docs.map((e) => Category.fromFirestore(e)).toList();
    });
    return data;
  }

  Future<List<Category>> getCategoriesByParentId(String parentId) async {
    List<Category> data = [];
    await firestore
        .collection('categories')
        .orderBy('created_at', descending: true)
        .where('parent_id', isEqualTo: parentId)
        .get()
        .then((QuerySnapshot? snapshot) {
      data = snapshot!.docs.map((e) => Category.fromFirestore(e)).toList();
    });
    return data;
  }

  Future<List<Article>> getTopArticles(int limit) async {
    List<Article> data = [];
    await firestore
        .collection('articles')
        .orderBy('views', descending: true)
        .limit(limit)
        .get()
        .then((QuerySnapshot? snapshot) {
      data = snapshot!.docs.map((e) => Article.fromFirestore(e)).toList();
    });
    return data;
  }

  Future<List<UserModel>> getLatestUsers(int limit) async {
    List<UserModel> data = [];
    await firestore
        .collection('users')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get()
        .then((QuerySnapshot? snapshot) {
      data = snapshot!.docs.map((e) => UserModel.fromFirebase(e)).toList();
    });
    return data;
  }

  Future<List<Comment>> getLatestComments(int limit) async {
    List<Comment> data = [];
    await firestore
        .collection('comments')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get()
        .then((QuerySnapshot? snapshot) {
      data = snapshot!.docs.map((e) => Comment.fromFirebase(e)).toList();
    });
    return data;
  }

  Future<List<PurchaseHistory>> getLatestPurchases(int limit) async {
    List<PurchaseHistory> data = [];
    await firestore
        .collection('purchases')
        .orderBy('purchase_at', descending: true)
        .limit(limit)
        .get()
        .then((QuerySnapshot? snapshot) {
      data =
          snapshot!.docs.map((e) => PurchaseHistory.fromFirestore(e)).toList();
    });
    return data;
  }

  Future<List<UserModel>> getAuthors() async {
    List<UserModel> data = [];
    await firestore
        .collection('users')
        .where('role', arrayContainsAny: ['author', 'admin'])
        .get()
        .then((QuerySnapshot? snapshot) {
          data = snapshot!.docs.map((e) => UserModel.fromFirebase(e)).toList();
        });
    return data;
  }

  Future<AppSettingsModel?> getAppSettings() async {
    AppSettingsModel? settings;
    try {
      final DocumentSnapshot snap =
          await firestore.collection('settings').doc('app').get();
      settings = AppSettingsModel.fromFirestore(snap);
    } catch (e) {
      debugPrint('no settings data');
    }

    return settings;
  }

  Future<List<Tag>> getTags() async {
    List<Tag> data = [];
    await firestore
        .collection('tags')
        .orderBy('created_at', descending: true)
        .get()
        .then((QuerySnapshot? snapshot) {
      data = snapshot!.docs.map((e) => Tag.fromFirestore(e)).toList();
    });
    return data;
  }

  Future saveTag(Tag tag) async {
    const String collectionName = 'tags';
    Map<String, dynamic> data = Tag.getMap(tag);
    await firestore
        .collection(collectionName)
        .doc(tag.id)
        .set(data, SetOptions(merge: true));
  }

  static Query notificationsQuery() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('sent_at', descending: true);
  }

  static Query commentsQuery() {
    return FirebaseFirestore.instance
        .collection('comments')
        .orderBy('created_at', descending: true);
  }

  static Query articleCommentsQuery(Article article) {
    return FirebaseFirestore.instance
        .collection('comments')
        .where('article_id', isEqualTo: article.id)
        .orderBy('created_at', descending: true);
  }

  static Query authorArticleCommentsQuery(String articleAuthorId) {
    return FirebaseFirestore.instance
        .collection('comments')
        .where('article_author_id', isEqualTo: articleAuthorId)
        .orderBy('created_at', descending: true);
  }

  Future updateCategoriesOrder(List<Category> categories) async {
    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < categories.length; i++) {
      final docRef = FirebaseFirestore.instance
          .collection('categories')
          .doc(categories[i].id);
      batch.update(docRef, {'index': i});
    }
    await batch.commit();
  }

  Future updateUserProfile(UserModel user, Map<String, dynamic> data) async {
    await firestore.collection('users').doc(user.id).update(data);
  }

  Future saveAuthor(UserModel user) async {
    final data = UserModel.getMap(user);
    await firestore.collection('users').doc(user.id).set(data);
  }

  Future updateAppSettings(Map<String, dynamic> data) async {
    await firestore
        .collection('settings')
        .doc('app')
        .set(data, SetOptions(merge: true));
  }

  //New way for gettings counts
  Future<int> getCount(String path) async {
    final CollectionReference collectionReference = firestore.collection(path);
    AggregateQuerySnapshot snap = await collectionReference.count().get();
    int count = snap.count ?? 0;
    return count;
  }

  Future<int> getArticlesCount() async {
    final CollectionReference collectionReference =
        firestore.collection('articles');
    AggregateQuerySnapshot snap = await collectionReference
        .where('status', isEqualTo: articleStatus.keys.elementAt(2))
        .count()
        .get();
    int count = snap.count ?? 0;
    return count;
  }

  Future<int> getPendingArticlesCount() async {
    final CollectionReference collectionReference =
        firestore.collection('articles');
    AggregateQuerySnapshot snap = await collectionReference
        .where('status', isEqualTo: articleStatus.keys.elementAt(1))
        .count()
        .get();
    int count = snap.count ?? 0;
    return count;
  }

  Future<int> getEventsCount() async {
    final CollectionReference collectionReference =
        firestore.collection('events');
    AggregateQuerySnapshot snap = await collectionReference
        .where('status', isEqualTo: eventStatus.keys.elementAt(1))
        .count()
        .get();
    int count = snap.count ?? 0;
    return count;
  }

  Future<int> getAuthorsCount() async {
    final CollectionReference collectionReference =
        firestore.collection('users');
    AggregateQuerySnapshot snap = await collectionReference
        .where('role', arrayContains: 'author')
        .count()
        .get();
    int count = snap.count ?? 0;
    return count;
  }

  Future<int> getSubscribedUsersCount() async {
    final CollectionReference collectionReference =
        firestore.collection('users');
    AggregateQuerySnapshot snap = await collectionReference
        .where('subscription', isNull: false)
        .count()
        .get();
    int count = snap.count ?? 0;
    return count;
  }

  Future<int> getTotalAuthorArticlesCount(String authorId) async {
    final CollectionReference collectionReference =
        firestore.collection('articles');
    AggregateQuerySnapshot snap = await collectionReference
        .where('author.id', isEqualTo: authorId)
        .count()
        .get();
    int count = snap.count ?? 0;
    return count;
  }

  Future<int> getPendingAuthorArticlesCount(String authorId) async {
    final CollectionReference collectionReference =
        firestore.collection('articles');
    AggregateQuerySnapshot snap = await collectionReference
        .where('status', isEqualTo: articleStatus.keys.elementAt(1))
        .where('author.id', isEqualTo: authorId)
        .count()
        .get();
    int count = snap.count ?? 0;
    return count;
  }

  Future<int> getLiveAuthorArticlesCount(String authorId) async {
    final CollectionReference collectionReference =
        firestore.collection('articles');
    AggregateQuerySnapshot snap = await collectionReference
        .where('status', isEqualTo: articleStatus.keys.elementAt(2))
        .where('author.id', isEqualTo: authorId)
        .count()
        .get();
    int count = snap.count ?? 0;
    return count;
  }

  Future<int> getAuthorCommentsCount(String authorId) async {
    final CollectionReference collectionReference =
        firestore.collection('comments');
    AggregateQuerySnapshot snap = await collectionReference
        .where('article_author_id', isEqualTo: authorId)
        .count()
        .get();
    int count = snap.count ?? 0;
    return count;
  }

  Future deleteCategoryRelatedArticles(String categoryId) async {
    WriteBatch batch = firestore.batch();
    final QuerySnapshot snapshot = await firestore
        .collection('articles')
        .where('cat_id', isEqualTo: categoryId)
        .get();
    if (snapshot.size != 0) {
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }

  Future deleteCategoryRelatedSubCategories(String categoryId) async {
    WriteBatch batch = firestore.batch();
    final QuerySnapshot snapshot = await firestore
        .collection('categories')
        .where('parent_id', isEqualTo: categoryId)
        .get();
    if (snapshot.size != 0) {
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }

  Future<List<ChartModel>> getUserStats(int days) async {
    List<ChartModel> stats = [];
    DateTime lastWeek = DateTime.now().subtract(Duration(days: days));
    final QuerySnapshot snapshot = await firestore
        .collection('user_stats')
        .where('timestamp', isGreaterThanOrEqualTo: lastWeek)
        .get();
    stats = snapshot.docs.map((e) => ChartModel.fromFirestore(e)).toList();
    return stats;
  }

  Future<List<ChartModel>> getPurchaseStats(int days) async {
    List<ChartModel> stats = [];
    DateTime lastWeek = DateTime.now().subtract(Duration(days: days));
    final QuerySnapshot snapshot = await firestore
        .collection('purchase_stats')
        .where('timestamp', isGreaterThanOrEqualTo: lastWeek)
        .get();
    stats = snapshot.docs.map((e) => ChartModel.fromFirestore(e)).toList();
    return stats;
  }

  Future saveComment(Comment comment) async {
    const String collectionName = 'comments';
    Map<String, dynamic> data = Comment.getMap(comment);
    await firestore
        .collection(collectionName)
        .doc(comment.id)
        .set(data, SetOptions(merge: true));
  }

  Future<List<Article>> getAllArticles(int limit) async {
    List<Article> data = [];
    await firestore
        .collection('articles')
        .get()
        .then((QuerySnapshot? snapshot) {
      data = snapshot!.docs.map((e) => Article.fromFirestore(e)).toList();
    });
    return data;
  }
}
