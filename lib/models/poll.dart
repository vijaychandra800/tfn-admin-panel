import 'package:cloud_firestore/cloud_firestore.dart';

class PollOption {
  final String id;
  final String text;
  final int voteCount;

  PollOption({required this.id, required this.text, this.voteCount = 0});

  factory PollOption.fromMap(Map<String, dynamic> d) {
    return PollOption(
      id: d['id'] ?? '',
      text: d['text'] ?? '',
      voteCount: (d['vote_count'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'vote_count': voteCount,
    };
  }

  PollOption copyWith({String? text, int? voteCount}) {
    return PollOption(
      id: id,
      text: text ?? this.text,
      voteCount: voteCount ?? this.voteCount,
    );
  }
}

class Poll {
  final String id;
  final String eventId;
  final String question;
  final List<PollOption> options;
  final bool allowMultiple;
  final String status; // 'open' | 'closed'
  final DateTime createdAt;
  final DateTime? updatedAt;

  Poll({
    required this.id,
    required this.eventId,
    required this.question,
    required this.options,
    required this.allowMultiple,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Poll.fromFirestore(DocumentSnapshot snap) {
    final d = snap.data() as Map<String, dynamic>;
    final List rawOptions = d['options'] ?? [];
    return Poll(
      id: snap.id,
      eventId: d['event_id'] ?? '',
      question: d['question'] ?? '',
      options: rawOptions
          .map((e) => PollOption.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      allowMultiple: d['allow_multiple'] ?? false,
      status: d['status'] ?? 'open',
      createdAt: (d['created_at'] as Timestamp).toDate(),
      updatedAt: d['updated_at'] == null
          ? null
          : (d['updated_at'] as Timestamp).toDate(),
    );
  }

  static Map<String, dynamic> getMap(Poll p) {
    return {
      'event_id': p.eventId,
      'question': p.question,
      'options': p.options.map((e) => e.toMap()).toList(),
      'allow_multiple': p.allowMultiple,
      'status': p.status,
      'created_at': p.createdAt,
      'updated_at': p.updatedAt ?? DateTime.now().toUtc(),
    };
  }

  int get totalVotes => options.fold(0, (sum, o) => sum + o.voteCount);
}
