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
    return Comment(
      id: json['id'],
      ticketId: json['ticket_id'],
      authorId: json['author_id'],
      authorName: json['author_name'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ticket_id': ticketId,
    'author_id': authorId,
    'author_name': authorName,
    'content': content,
    'created_at': createdAt.toIso8601String(),
  };
}