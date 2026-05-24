import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_admin/models/author.dart';
import 'package:news_admin/models/event_category.dart';

///
/// Created by Varnica Gupta on 12/03/25
///

class Event {
  final String id, title;
  final String? thumbnailUrl, location, summary, watchUrl, resultUrl;
  final DateTime startDateTime, endDateTime;
  final DateTime createdAt;
  DateTime? updatedAt;
  final Author? author;
  String status;
  final EventCategory? category;

  Event(
      {required this.id,
      required this.title,
      this.thumbnailUrl,
      required this.startDateTime,
      required this.endDateTime,
      this.location,
      this.summary,
      this.watchUrl,
      this.resultUrl,
      required this.createdAt,
      this.updatedAt,
      this.author,
      required this.status,
      this.category});

  factory Event.fromFireStore(DocumentSnapshot snap) {
    Map d = snap.data() as Map<String, dynamic>;

    return Event(
      id: snap.id,
      title: d['title'],
      thumbnailUrl: d['image_url'],
      startDateTime: (d['start_date_time'] as Timestamp).toDate(),
      endDateTime: (d['end_date_time'] as Timestamp).toDate(),
      location: d['location'],
      summary: d['summary'],
      watchUrl: d['watch_url'],
      resultUrl: d['result_url'],
      createdAt: (d['created_at'] as Timestamp).toDate(),
      updatedAt: d['updated_at'] == null ? null : (d['created_at'] as Timestamp).toDate(),
      author: d['author'] != null ? Author.fromMap(d['author']) : null,
      status: d['status'],
      category: d['category'] != null ? EventCategory.fromMap(d['category']) : null,
    );
  }

  static Map<String, dynamic> getMap(Event d) {
    return {
      'title': d.title,
      'summary': d.summary,
      'location': d.location,
      'image_url': d.thumbnailUrl,
      'start_date_time': d.startDateTime,
      'end_date_time': d.endDateTime,
      'created_at': d.createdAt,
      'updated_at': d.updatedAt,
      'watch_url': d.watchUrl,
      'result_url': d.resultUrl,
      'status': d.status,
      'author': d.author != null ? Author.getMap(d.author!) : null,
      'category': d.category != null ? EventCategory.getMap(d.category!) : null,
    };
  }
}
