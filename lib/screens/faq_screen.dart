import 'package:flutter/material.dart';
import '../app_theme.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final _searchController = TextEditingController();
  final _aiController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';
  int? _expandedIndex;

  final List<Map<String, dynamic>> _categories = [
    {'value': 'all',       'label': 'All',       'color': AppTheme.primaryLight,   'icon': Icons.apps},
    {'value': 'account',   'label': 'Account',   'color': AppTheme.primaryLight,   'icon': Icons.person_outline},
    {'value': 'technical', 'label': 'Technical', 'color': AppTheme.statusResolved, 'icon': Icons.computer_outlined},
    {'value': 'billing',   'label': 'Billing',   'color': AppTheme.statusInProgress, 'icon': Icons.receipt_outlined},
  ];

  final List<Map<String, String>> _faqs = [
    {
      'category': 'account',
      'question': 'How do I reset my password?',
      'answer':
          'Go to the login screen and tap "Forgot password?". Enter your email address and we\'ll send you a reset link within a few minutes. Check your spam folder if you don\'t see it.',
    },
    {
      'category': 'technical',
      'question': 'How to track my ticket status?',
      'answer':
          'All your tickets are visible on the Dashboard. Each ticket shows a colored badge indicating its current status: NEW (blue), IN PROGRESS (yellow), RESOLVED (green), or CLOSED (purple).',
    },
    {
      'category': 'technical',
      'question': 'Can I upload files to a ticket?',
      'answer':
          'Yes! When creating a ticket, tap the attachment icon to upload images or documents. Supported formats include JPG, PNG, and PDF files up to 10MB each.',
    },
    {
      'category': 'account',
      'question': 'How long until I get a response?',
      'answer':
          'Our support team typically responds within 24 hours on business days. High priority tickets are addressed within 4 hours. You\'ll receive a notification when someone replies to your ticket.',
    },
    {
      'category': 'account',
      'question': 'How to contact support directly?',
      'answer':
          'You can reach our support team by creating a ticket, or by using the AI assistant below for instant answers. For urgent issues, mark your ticket as HIGH priority.',
    },
    {
      'category': 'billing',
      'question': 'How do I update my billing information?',
      'answer':
          'Go to your Profile settings and select "Billing". From there you can update your payment method, view invoices, and manage your subscription.',
    },
    {
      'category': 'billing',
      'question': 'Can I get a refund?',
      'answer':
          'Refund requests are handled case by case. Please create a ticket with the category "Billing" and our team will review your request within 48 hours.',
    },
    {
      'category': 'technical',
      'question': 'The app is not loading properly, what should I do?',
      'answer':
          'Try these steps: 1) Force close and reopen the app. 2) Check your internet connection. 3) Clear the app cache in your phone settings. 4) If the issue persists, create a technical support ticket.',
    },
  ];

  List<Map<String, String>> get _filteredFaqs {
    return _faqs.where((faq) {
      final matchesCategory =
          _selectedCategory == 'all' || faq['category'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          faq['question']!
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          faq['answer']!
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _aiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [

            // Header
            const Text(
              'Help center',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Find answers quickly',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 16),

            // Search bar
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search for help...',
                  hintStyle: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppTheme.textHint,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _expandedIndex = null;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            // Category cards
            Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['value'];
                final color = cat['color'] as Color;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedCategory = cat['value'] as String;
                      _expandedIndex = null;
                    }),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: cat['value'] != 'billing' ? 8 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.12)
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? color.withOpacity(0.4)
                              : AppTheme.surfaceBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            color: isSelected ? color : AppTheme.textHint,
                            size: 20,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat['label'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? color : AppTheme.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Section title
            const Text(
              'Popular questions',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 12),

            // FAQ items accordion
            if (_filteredFaqs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No results found for "$_searchQuery"',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textHint,
                    ),
                  ),
                ),
              )
            else
              ...List.generate(_filteredFaqs.length, (index) {
                final faq = _filteredFaqs[index];
                final isExpanded = _expandedIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _expandedIndex = isExpanded ? null : index;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isExpanded
                              ? AppTheme.primary.withOpacity(0.4)
                              : AppTheme.surfaceBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    faq['question']!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AnimatedRotation(
                                  turns: isExpanded ? 0.125 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.add,
                                    color: isExpanded
                                        ? AppTheme.primaryLight
                                        : AppTheme.textHint,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isExpanded)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                              child: Text(
                                faq['answer']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 20),

            // AI Assistant card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI assistant',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Can\'t find your answer? Chat with our AI assistant for instant help.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: TextField(
                      controller: _aiController,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Ask me anything...',
                        hintStyle: TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 11,
                        ),
                        prefixIcon: Icon(
                          Icons.chat_bubble_outline,
                          color: AppTheme.textHint,
                          size: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isEmpty) return;
                        // Suggestions automatiques basées sur le texte
                        final query = val.toLowerCase();
                        String? suggestion;
                        for (final faq in _faqs) {
                          if (faq['question']!
                              .toLowerCase()
                              .contains(query) ||
                              faq['answer']!
                                  .toLowerCase()
                                  .contains(query)) {
                            suggestion = faq['question'];
                            break;
                          }
                        }
                        _aiController.clear();
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: AppTheme.surface,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (_) => _AiResponseSheet(
                            query: val,
                            suggestion: suggestion,
                            faqs: _faqs,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiResponseSheet extends StatelessWidget {
  final String query;
  final String? suggestion;
  final List<Map<String, String>> faqs;

  const _AiResponseSheet({
    required this.query,
    required this.suggestion,
    required this.faqs,
  });

  @override
  Widget build(BuildContext context) {
    final matches = faqs.where((faq) {
      final q = query.toLowerCase();
      return faq['question']!.toLowerCase().contains(q) ||
          faq['answer']!.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: AppTheme.primaryLight, size: 18),
              const SizedBox(width: 8),
              const Text(
                'AI assistant',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryLight,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close,
                    color: AppTheme.textHint, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Results for: "$query"',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          if (matches.isEmpty)
            const Text(
              'No matching articles found. Please create a support ticket for personalized help.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            )
          else
            ...matches.take(3).map((faq) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faq['question']!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        faq['answer']!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}