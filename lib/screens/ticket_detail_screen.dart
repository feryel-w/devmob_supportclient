import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';
import '../models/ticket.dart';
import '../models/comment.dart';

class TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;
  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isSending = false;

  Stream<QuerySnapshot> get _commentsStream => _firestore
      .collection('tickets')
      .doc(widget.ticket.id)
      .collection('comments')
      .orderBy('createdAt', descending: false)
      .snapshots();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final ref = _firestore
          .collection('tickets')
          .doc(widget.ticket.id)
          .collection('comments')
          .doc();

      await ref.set({
        'id':         ref.id,
        'ticketId':   widget.ticket.id,
        'authorId':   _auth.currentUser!.uid,
        'authorName': _auth.currentUser!.displayName ?? 'User',
        'content':    text,
        'createdAt':  FieldValue.serverTimestamp(),
      });

      // Update ticket updatedAt
      await _firestore.collection('tickets').doc(widget.ticket.id).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'),
            backgroundColor: AppTheme.priorityHigh),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final statusColor = AppTheme.getStatusColor(ticket.status);
    final priorityColor = AppTheme.getPriorityColor(ticket.priority);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          color: AppTheme.primaryLight,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Back',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.primaryLight,
          ),
        ),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          // Ticket info — scrollable top section
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [

                // ID + badges
                Row(
                  children: [
                    Text(
                      '#TK-${ticket.id.substring(0, 6).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textHint,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Spacer(),
                    _Badge(
                      label: AppTheme.getStatusLabel(ticket.status),
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    _Badge(
                      label: AppTheme.getPriorityLabel(ticket.priority),
                      color: priorityColor,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  ticket.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 12),

                // Description card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Text(
                    ticket.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Info cards row
                Row(
                  children: [
                    _InfoCard(
                      label: 'Category',
                      value: ticket.category[0].toUpperCase() +
                          ticket.category.substring(1),
                    ),
                    const SizedBox(width: 8),
                    _InfoCard(
                      label: 'Created',
                      value: _formatDate(ticket.createdAt),
                    ),
                    const SizedBox(width: 8),
                    _InfoCard(
                      label: 'Assigned',
                      value: ticket.assignedTo ?? 'Unassigned',
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Discussion label
                const Text(
                  'Discussion',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 12),

                // Comments stream
                StreamBuilder<QuerySnapshot>(
                  stream: _commentsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No messages yet.\nBe the first to comment!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textHint,
                            ),
                          ),
                        ),
                      );
                    }

                    final comments = snapshot.data!.docs.map((doc) =>
                        Comment.fromJson(
                            doc.data() as Map<String, dynamic>)).toList();

                    return Column(
                      children: comments.map((comment) {
                        final isMe = comment.authorId == _auth.currentUser?.uid;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CommentBubble(
                            comment: comment,
                            isMe: isMe,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          // Chat input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
            decoration: const BoxDecoration(
              color: AppTheme.background,
              border: Border(
                top: BorderSide(color: AppTheme.surfaceBorder),
              ),
            ),
            child: Row(
              children: [
                // Input field
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 12,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Send button
                GestureDetector(
                  onTap: _isSending ? null : _sendMessage,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  const _InfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppTheme.textHint,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final Comment comment;
  final bool isMe;
  const _CommentBubble({required this.comment, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe
              ? AppTheme.primary.withOpacity(0.12)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: isMe
              ? null
              : Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMe ? 'You' : comment.authorName,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textHint,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              comment.content,
              style: TextStyle(
                fontSize: 12,
                color: isMe ? AppTheme.primaryLight : AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}