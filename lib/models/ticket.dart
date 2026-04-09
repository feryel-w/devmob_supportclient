class Ticket {
  final String id;
  final String title;
  final String description;
  final String category;
  final String priority;   // 'low', 'medium', 'high'
  final String status;     // 'new', 'in_progress', 'resolved', 'closed'
  final String authorId;
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
    this.assignedTo,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      priority: json['priority'],
      status: json['status'],
      authorId: json['author_id'],
      assignedTo: json['assigned_to'],
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'priority': priority,
    'status': status,
    'author_id': authorId,
    'assigned_to': assignedTo,
    'attachments': attachments,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}