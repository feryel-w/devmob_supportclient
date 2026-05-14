import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';
import '../models/ticket.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';
import 'ticket_detail_screen.dart';
import 'statistics_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _authService = AuthService();
  final _searchController = TextEditingController();

  int _currentIndex = 0;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  String _selectedUser = 'all';
  DateTime? _dateFrom;
  DateTime? _dateTo;
  List<String> _userNames = [];

  final List<Map<String, String>> _filters = [
    {'value': 'all',         'label': 'All'},
    {'value': 'new',         'label': 'New'},
    {'value': 'in_progress', 'label': 'In progress'},
    {'value': 'high',        'label': 'High priority'},
    {'value': 'technical',   'label': 'Technical'},
  ];

  Stream<QuerySnapshot> get _ticketsStream => _firestore
      .collection('tickets')
      .orderBy('createdAt', descending: true)
      .snapshots();

  void _loadUserNames(List<Ticket> tickets) {
    final names = tickets.map((t) => t.authorName).toSet().toList();
    if (!listEquals(_userNames, names)) {
      setState(() => _userNames = names);
    }
  }

  List<Ticket> _applyFilters(List<Ticket> tickets) {
    return tickets.where((t) {
      final matchesFilter = _selectedFilter == 'all' ||
          (_selectedFilter == 'high' && t.priority == 'high') ||
          (_selectedFilter == 'technical' && t.category == 'technical') ||
          t.status == _selectedFilter;

      final matchesSearch = _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.authorName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesUser =
          _selectedUser == 'all' || t.authorName == _selectedUser;

      final matchesDate =
          (_dateFrom == null || t.createdAt.isAfter(_dateFrom!)) &&
              (_dateTo == null ||
                  t.createdAt
                      .isBefore(_dateTo!.add(const Duration(days: 1))));

      return matchesFilter && matchesSearch && matchesUser && matchesDate;
    }).toList();
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  Color _getPriorityBarColor(String priority) {
    switch (priority) {
      case 'high':   return AppTheme.priorityHigh;
      case 'medium': return AppTheme.priorityMedium;
      case 'low':    return AppTheme.priorityLow;
      default:       return AppTheme.statusNew;
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              surface: AppTheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateFrom = picked.start;
        _dateTo = picked.end;
      });
    }
  }

  Future<void> _assignTicket(Ticket ticket) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('tickets').doc(ticket.id).update({
      'assignedTo': user.displayName ?? 'Support',
      'status':     'in_progress',
      'updatedAt':  FieldValue.serverTimestamp(),
    });

    await NotificationService().showTicketAssignedNotification(
      ticketTitle: ticket.title,
      agentName: user.displayName ?? 'Support',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ticket assigned to you!'),
        backgroundColor: AppTheme.statusResolved,
      ),
    );
  }

  Future<void> _changeStatus(Ticket ticket, String newStatus) async {
    await _firestore.collection('tickets').doc(ticket.id).update({
      'status':    newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await NotificationService().showStatusChangedNotification(
      ticketTitle: ticket.title,
      newStatus: newStatus,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Status updated to ${AppTheme.getStatusLabel(newStatus)}'),
        backgroundColor: AppTheme.getStatusColor(newStatus),
      ),
    );
  }

  void _showStatusMenu(Ticket ticket) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change status',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...['new', 'in_progress', 'resolved', 'closed'].map((status) {
              final color = AppTheme.getStatusColor(status);
              final isCurrent = ticket.status == status;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  if (!isCurrent) _changeStatus(ticket, status);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? color.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          isCurrent ? color : AppTheme.surfaceBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppTheme.getStatusLabel(status),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      if (isCurrent) ...[
                        const Spacer(),
                        Icon(Icons.check, color: color, size: 16),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Se déconnecter ?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.logout();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Déconnecter',
                style: TextStyle(color: AppTheme.priorityHigh)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child:
            _currentIndex == 0 ? _buildPanel() : const StatisticsScreen(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildPanel() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Support panel',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('tickets')
                            .where('status', isEqualTo: 'new')
                            .snapshots(),
                        builder: (context, snap) {
                          final count = snap.data?.docs.length ?? 0;
                          return Text(
                            '$count open tickets',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _showLogoutDialog,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.statusResolved,
                      child: Text(
                        _auth.currentUser?.displayName
                                ?.substring(0, 2)
                                .toUpperCase() ??
                            'SM',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((f) {
                    final isActive = _selectedFilter == f['value'];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedFilter = f['value']!),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primary.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive
                                ? AppTheme.primary
                                : AppTheme.surfaceBorder,
                          ),
                        ),
                        child: Text(
                          f['label']!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? AppTheme.primaryLight
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 8),

              // User + Date filters row
              Row(
                children: [
                  // User dropdown
                  Expanded(
                    child: Container(
                      height: 38,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: AppTheme.surfaceBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedUser,
                          dropdownColor: AppTheme.surface,
                          iconEnabledColor: AppTheme.textHint,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(
                              value: 'all',
                              child: Text('All users',
                                  style: TextStyle(
                                      color: AppTheme.textHint)),
                            ),
                            ..._userNames.map((name) =>
                                DropdownMenuItem(
                                  value: name,
                                  child: Text(name),
                                )),
                          ],
                          onChanged: (val) => setState(
                              () => _selectedUser = val ?? 'all'),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Date range picker
                  GestureDetector(
                    onTap: _pickDateRange,
                    child: Container(
                      height: 38,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: _dateFrom != null
                            ? AppTheme.primary.withOpacity(0.12)
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _dateFrom != null
                              ? AppTheme.primary
                              : AppTheme.surfaceBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: _dateFrom != null
                                ? AppTheme.primaryLight
                                : AppTheme.textHint,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _dateFrom != null
                                ? '${_dateFrom!.day}/${_dateFrom!.month} - ${_dateTo!.day}/${_dateTo!.month}'
                                : 'Date range',
                            style: TextStyle(
                              fontSize: 11,
                              color: _dateFrom != null
                                  ? AppTheme.primaryLight
                                  : AppTheme.textHint,
                            ),
                          ),
                          if (_dateFrom != null) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(() {
                                _dateFrom = null;
                                _dateTo = null;
                              }),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: AppTheme.textHint,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Search bar
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'Search tickets...',
                    hintStyle: TextStyle(
                        color: AppTheme.textHint, fontSize: 12),
                    prefixIcon: Icon(Icons.search,
                        color: AppTheme.textHint, size: 18),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (val) =>
                      setState(() => _searchQuery = val),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),

        // Tickets list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _ticketsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                      ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primary),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}',
                      style: const TextStyle(
                          color: AppTheme.priorityHigh)),
                );
              }

              final allTickets = snapshot.data?.docs
                      .map((doc) => Ticket.fromJson(
                          doc.data() as Map<String, dynamic>))
                      .toList() ??
                  [];

              _loadUserNames(allTickets);

              final tickets = _applyFilters(allTickets);

              if (tickets.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.inbox_outlined,
                          size: 48, color: AppTheme.textHint),
                      SizedBox(height: 12),
                      Text('No tickets found',
                          style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 80),
                itemCount: tickets.length,
                itemBuilder: (context, index) {
                  final ticket = tickets[index];
                  final barColor =
                      _getPriorityBarColor(ticket.priority);
                  final isAssigned = ticket.assignedTo != null;

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TicketDetailScreen(ticket: ticket),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.surfaceBorder),
                      ),
                      child: Row(
                        children: [
                          // Priority bar
                          Container(
                            width: 5,
                            height: 44,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius:
                                  BorderRadius.circular(3),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${ticket.title} — ${ticket.authorName}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '#TK-${ticket.id.substring(0, 6).toUpperCase()} · ${ticket.category} · ${_timeAgo(ticket.createdAt)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Action buttons
                          Column(
                            children: [
                              GestureDetector(
                                onTap: isAssigned
                                    ? null
                                    : () => _assignTicket(ticket),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isAssigned
                                        ? AppTheme.statusResolved
                                            .withOpacity(0.12)
                                        : AppTheme.primary
                                            .withOpacity(0.12),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isAssigned
                                        ? 'Assigned'
                                        : 'Assign',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: isAssigned
                                          ? AppTheme.statusResolved
                                          : AppTheme.primaryLight,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 4),

                              GestureDetector(
                                onTap: () =>
                                    _showStatusMenu(ticket),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.getStatusColor(
                                            ticket.status)
                                        .withOpacity(0.12),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    AppTheme.getStatusLabel(
                                        ticket.status),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          AppTheme.getStatusColor(
                                              ticket.status),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Color(0xFF14161E),
        border:
            Border(top: BorderSide(color: AppTheme.surfaceBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
            isActive: _currentIndex == 0,
            onTap: () => setState(() => _currentIndex = 0),
          ),
          _NavItem(
            icon: Icons.bar_chart_outlined,
            activeIcon: Icons.bar_chart,
            label: 'Stats',
            isActive: _currentIndex == 1,
            onTap: () => setState(() => _currentIndex = 1),
          ),
          _NavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
            isActive: _currentIndex == 2,
            onTap: _showLogoutDialog,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive
                ? AppTheme.primaryLight
                : AppTheme.textHint,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: isActive
                  ? AppTheme.primaryLight
                  : AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }
}