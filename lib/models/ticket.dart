import 'package:cloud_firestore/cloud_firestore.dart';

class Ticket {
  final String id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final String authorId;
  final String authorName;
  final String? assignedTo;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.authorId,
    required this.authorName,
    this.assignedTo,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.parse(val);
      return DateTime.now();
    }

    return Ticket(
      id:           json['id'] ?? '',
      title:        json['title'] ?? '',
      description:  json['description'] ?? '',
      category:     json['category'] ?? '',
      priority:     json['priority'] ?? 'medium',
      status:       json['status'] ?? 'new',
      authorId:     json['authorId'] ?? '',
      authorName:   json['authorName'] ?? '',
      assignedTo:   json['assignedTo'],
      attachments:  List<String>.from(json['attachments'] ?? []),
      createdAt:    parseDate(json['createdAt']),
      updatedAt:    parseDate(json['updatedAt']),
    );
  }
}