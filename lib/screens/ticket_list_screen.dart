import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';
import '../models/ticket.dart';
import '../widgets/ticket_card.dart';
import 'ticket_detail_screen.dart';
import 'create_ticket_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _searchController = TextEditingController();

  String _selectedFilter = 'all';
  String _searchQuery = '';

  final List<Map<String, String>> _filters = [
    {'value': 'all',        'label': 'All'},
    {'value': 'new',        'label': 'New'},
    {'value': 'in_progress','label': 'Active'},
    {'value': 'resolved',   'label': 'Resolved'},
    {'value': 'closed',     'label': 'Closed'},
  ];

  Stream<QuerySnapshot> get _ticketsStream => _firestore
      .collection('tickets')
      .where('authorId', isEqualTo: _auth.currentUser?.uid)
      .snapshots();

  List<Ticket> _applyFilters(List<Ticket> tickets) {
    return tickets.where((t) {
      final matchesFilter =
          _selectedFilter == 'all' || t.status == _selectedFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Header
                  const Text(
                    'My tickets',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 12),

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
                          color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Search tickets...',
                        hintStyle: TextStyle(
                            color: AppTheme.textHint, fontSize: 13),
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

                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((f) {
                        final isActive = _selectedFilter == f['value'];
                        return GestureDetector(
                          onTap: () => setState(
                              () => _selectedFilter = f['value']!),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
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
                                fontSize: 11,
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

                  final tickets = _applyFilters(allTickets);

                  if (tickets.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox_outlined,
                              size: 52, color: AppTheme.textHint),
                          const SizedBox(height: 14),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No results for "$_searchQuery"'
                                : 'No tickets yet',
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_searchQuery.isEmpty)
                            const Text(
                              'Tap + to create your first ticket',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textHint,
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TicketCard(
                          ticket: tickets[index],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TicketDetailScreen(
                                  ticket: tickets[index]),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}