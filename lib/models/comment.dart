import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String ticketId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.ticketId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.parse(val);
      return DateTime.now();
    }

    return Comment(
      id:         json['id'] ?? '',
      ticketId:   json['ticketId'] ?? '',
      authorId:   json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      content:    json['content'] ?? '',
      createdAt:  parseDate(json['createdAt']),
    );
  }
}