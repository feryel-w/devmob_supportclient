import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String _priority = 'medium';
  String _category = 'technical';
  bool _isLoading = false;

  final List<Map<String, String>> _categories = [
    {'value': 'technical',      'label': 'Technical issue'},
    {'value': 'account',        'label': 'Account & access'},
    {'value': 'billing',        'label': 'Billing'},
    {'value': 'academic',       'label': 'Academic request'},
    {'value': 'infrastructure', 'label': 'Infrastructure'},
    {'value': 'other',          'label': 'Other'},
  ];

  final List<Map<String, dynamic>> _priorities = [
    {'value': 'low',    'label': 'Low',    'color': AppTheme.priorityLow},
    {'value': 'medium', 'label': 'Medium', 'color': AppTheme.priorityMedium},
    {'value': 'high',   'label': 'High',   'color': AppTheme.priorityHigh},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final docRef = _firestore.collection('tickets').doc();
      await docRef.set({
        'id':          docRef.id,
        'title':       _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category':    _category,
        'priority':    _priority,
        'status':      'new',
        'authorId':    _auth.currentUser!.uid,
        'authorName':  _auth.currentUser!.displayName ?? 'User',
        'assignedTo':  null,
        'attachments': [],
        'createdAt':   FieldValue.serverTimestamp(),
        'updatedAt':   FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket created successfully!'),
          backgroundColor: AppTheme.statusResolved,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.priorityHigh,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New ticket',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // Title
            _SectionLabel(label: 'Title'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
              ),
              decoration: const InputDecoration(
                hintText: 'Brief description of your issue',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                if (value.trim().length < 5) {
                  return 'Minimum 5 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Description
            _SectionLabel(label: 'Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
              ),
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Describe your issue in detail...',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                if (value.trim().length < 10) {
                  return 'Minimum 10 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Category
            _SectionLabel(label: 'Category'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _category,
                  dropdownColor: AppTheme.surface,
                  iconEnabledColor: AppTheme.textHint,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                  isExpanded: true,
                  items: _categories
                      .map((c) => DropdownMenuItem(
                            value: c['value'],
                            child: Text(c['label']!),
                          ))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _category = val ?? _category),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Priority
            _SectionLabel(label: 'Priority'),
            const SizedBox(height: 8),
            Row(
              children: _priorities.map((p) {
                final isSelected = _priority == p['value'];
                final color = p['color'] as Color;
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _priority = p['value'] as String),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: p['value'] != 'high' ? 8 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.15)
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? color : AppTheme.surfaceBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            color: isSelected ? color : AppTheme.textHint,
                            size: 18,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
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

            const SizedBox(height: 32),

            // Submit button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitTicket,
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text('Submit ticket'),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }
}