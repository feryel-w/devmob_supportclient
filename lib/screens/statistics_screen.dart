import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_theme.dart';
import '../models/ticket.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;

  int _totalTickets = 0;
  int _newTickets = 0;
  int _inProgressTickets = 0;
  int _resolvedTickets = 0;
  int _closedTickets = 0;
  double _resolvedPercent = 0;
  double _avgResolutionHours = 0;

  Map<String, int> _byCategory = {};
  List<int> _weeklyTrend = [0, 0, 0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    final snapshot = await _firestore.collection('tickets').get();
    final tickets = snapshot.docs
        .map((doc) => Ticket.fromJson(doc.data()))
        .toList();

    final now = DateTime.now();
    final last30 = tickets.where((t) =>
        now.difference(t.createdAt).inDays <= 30).toList();

    // Counts
    final newCount = last30.where((t) => t.status == 'new').length;
    final inProgressCount =
        last30.where((t) => t.status == 'in_progress').length;
    final resolvedCount =
        last30.where((t) => t.status == 'resolved').length;
    final closedCount = last30.where((t) => t.status == 'closed').length;
    final total = last30.length;

    // Resolved percent
    final resolvedPercent =
        total > 0 ? ((resolvedCount + closedCount) / total * 100) : 0.0;

    // Avg resolution time
    final resolvedWithTime = last30.where((t) =>
        (t.status == 'resolved' || t.status == 'closed')).toList();
    double avgHours = 0;
    if (resolvedWithTime.isNotEmpty) {
      final totalHours = resolvedWithTime.fold<double>(
        0,
        (sum, t) =>
            sum + now.difference(t.createdAt).inHours.toDouble(),
      );
      avgHours = totalHours / resolvedWithTime.length;
    }

    // By category
    final categoryMap = <String, int>{};
    for (final t in last30) {
      categoryMap[t.category] = (categoryMap[t.category] ?? 0) + 1;
    }

    // Weekly trend (last 7 days)
    final weeklyData = List<int>.filled(7, 0);
    for (final t in tickets) {
      final daysAgo = now.difference(t.createdAt).inDays;
      if (daysAgo < 7) {
        weeklyData[6 - daysAgo]++;
      }
    }

    setState(() {
      _totalTickets = total;
      _newTickets = newCount;
      _inProgressTickets = inProgressCount;
      _resolvedTickets = resolvedCount;
      _closedTickets = closedCount;
      _resolvedPercent = resolvedPercent.toDouble();
      _avgResolutionHours = avgHours;
      _byCategory = categoryMap;
      _weeklyTrend = weeklyData;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary))
            : RefreshIndicator(
                onRefresh: _loadStats,
                color: AppTheme.primary,
                backgroundColor: AppTheme.surface,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    // Header
                    const Text(
                      'Analytics',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Last 30 days',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Stat cards row
                    Row(
                      children: [
                        _StatCard(
                          value: '$_totalTickets',
                          label: 'TOTAL TICKETS',
                          color: AppTheme.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          value:
                              '${_resolvedPercent.toStringAsFixed(0)}%',
                          label: 'RESOLVED',
                          color: AppTheme.statusResolved,
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          value:
                              '${_avgResolutionHours.toStringAsFixed(1)}h',
                          label: 'AVG TIME',
                          color: AppTheme.statusInProgress,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Bar chart — tickets by status
                    _ChartCard(
                      title: 'TICKETS BY STATUS',
                      child: SizedBox(
                        height: 160,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: (_totalTickets > 0
                                    ? [
                                        _newTickets,
                                        _inProgressTickets,
                                        _resolvedTickets,
                                        _closedTickets
                                      ].reduce((a, b) => a > b ? a : b) *
                                        1.3
                                    : 10)
                                .toDouble(),
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                              topTitles: AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    const labels = [
                                      'New',
                                      'Active',
                                      'Done',
                                      'Closed'
                                    ];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          top: 6),
                                      child: Text(
                                        labels[value.toInt()],
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: AppTheme.textHint,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            gridData: FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: [
                              _barGroup(
                                  0, _newTickets, AppTheme.statusNew),
                              _barGroup(1, _inProgressTickets,
                                  AppTheme.statusInProgress),
                              _barGroup(2, _resolvedTickets,
                                  AppTheme.statusResolved),
                              _barGroup(3, _closedTickets,
                                  AppTheme.statusClosed),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // By category progress bars
                    _ChartCard(
                      title: 'BY CATEGORY',
                      child: Column(
                        children: _buildCategoryBars(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Weekly trend line chart
                    _ChartCard(
                      title: 'WEEKLY TREND',
                      child: SizedBox(
                        height: 130,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                              topTitles: AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    const days = [
                                      'Mon',
                                      'Tue',
                                      'Wed',
                                      'Thu',
                                      'Fri',
                                      'Sat',
                                      'Sun'
                                    ];
                                    if (value.toInt() >= days.length) {
                                      return const SizedBox();
                                    }
                                    return Text(
                                      days[value.toInt()],
                                      style: const TextStyle(
                                        fontSize: 8,
                                        color: AppTheme.textHint,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _weeklyTrend
                                    .asMap()
                                    .entries
                                    .map((e) => FlSpot(e.key.toDouble(),
                                        e.value.toDouble()))
                                    .toList(),
                                isCurved: true,
                                color: AppTheme.primary,
                                barWidth: 2,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, bar,
                                          index) =>
                                      FlDotCirclePainter(
                                    radius: 3,
                                    color: AppTheme.primary,
                                    strokeWidth: 0,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color:
                                      AppTheme.primary.withOpacity(0.08),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, int value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.toDouble(),
          color: color,
          width: 36,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  List<Widget> _buildCategoryBars() {
    if (_byCategory.isEmpty) {
      return [
        const Text(
          'No data yet',
          style: TextStyle(color: AppTheme.textHint, fontSize: 12),
        )
      ];
    }

    final total = _byCategory.values.fold(0, (a, b) => a + b);
    final colors = [
      AppTheme.primary,
      AppTheme.statusNew,
      AppTheme.statusResolved,
      AppTheme.statusInProgress,
      AppTheme.statusClosed,
    ];

    return _byCategory.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final cat = entry.value;
      final percent = total > 0 ? (cat.value / total) : 0.0;
      final color = colors[index % colors.length];

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                cat.key[0].toUpperCase() + cat.key.substring(1),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: percent,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 36,
              child: Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: AppTheme.textHint,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}