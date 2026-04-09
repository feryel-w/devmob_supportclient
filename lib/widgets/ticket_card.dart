import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/ticket.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(ticket.status);
    final priorityColor = AppTheme.getPriorityColor(ticket.priority);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ID + date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#TK-${ticket.id.substring(0, 6).toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textHint,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  _timeAgo(ticket.createdAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Title
            Text(
              ticket.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),

            // Badges
            Row(
              children: [
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
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
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