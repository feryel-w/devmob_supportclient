import 'package:flutter/material.dart';
import '../models/ticket.dart';

class TicketDetailScreen extends StatelessWidget {
  final Ticket ticket;
  const TicketDetailScreen({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(ticket.title)),
      body: const Center(child: Text('Ticket detail — bientôt !')),
    );
  }
}