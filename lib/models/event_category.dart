import 'package:news_admin/models/event.dart';

///
/// Created by Varnica Gupta on 12/03/25
///

/// Submodel of [Event]

class EventCategory {
  final String id, name;

  EventCategory({required this.id, required this.name});

  factory EventCategory.fromMap(Map<String, dynamic> map) {
    return EventCategory(
      id: map['id'],
      name: map['name'],
    );
  }

  static Map<String, dynamic> getMap(EventCategory d) {
    return {
      'id': d.id,
      'name': d.name,
    };
  }
}
