import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<TransactionModel> _transactions = [];
  Map<String, double> _categoryData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final transactions = await DatabaseHelper.instance.getAllTransactions();
    
    Map<String, double> categoryMap = {};
    for (var transaction in transactions) {
      categoryMap[transaction.category] = 
          (categoryMap[transaction.category] ?? 0) + transaction.amount;
    }

    setState(() {
      _transactions = transactions;
      _categoryData = categoryMap;
      _isLoading = false;
    });
  }

  List<TransactionModel> _getTransactionsForDay(DateTime day) {
    return _transactions.where((transaction) {
      return isSameDay(transaction.date, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calendar View',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCalendar(),
                  const SizedBox(height: 24),
                  if (_selectedDay != null) _buildDayTransactions(),
                  const SizedBox(height: 24),
                  Text(
                    'Category Breakdown',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryChart(),
                  const SizedBox(height: 24),
                  _buildMonthlyTrend(),
                ],
              ),
            ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        calendarStyle: CalendarStyle(
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF6C63FF),
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: Color(0xFF4CAF50),
            shape: BoxShape.circle,
          ),
          selectedTextStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
          todayTextStyle: GoogleFonts.inter(color: const Color(0xFF6C63FF), fontWeight: FontWeight.bold),
          defaultTextStyle: GoogleFonts.inter(),
          weekendTextStyle: GoogleFonts.inter(),
          outsideTextStyle: GoogleFonts.inter(color: Colors.grey[400]),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3142),
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: Color(0xFF6C63FF)),
          rightChevronIcon: const Icon(Icons.chevron_right, color: Color(0xFF6C63FF)),
        ),
        eventLoader: (day) => _getTransactionsForDay(day),
      ),
    );
  }

  Widget _buildDayTransactions() {
    final dayTransactions = _getTransactionsForDay(_selectedDay!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transactions on ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 12),
        dayTransactions.isEmpty
            ? Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'No transactions on this day',
                    style: GoogleFonts.inter(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dayTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = dayTransactions[index];
                  final isLent = transaction.type == 'lent';
                  final color = isLent ? const Color(0xFF4CAF50) : const Color(0xFFFF5252);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isLent ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.personName,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                transaction.category,
                                style: GoogleFonts.inter(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${isLent ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildCategoryChart() {
    if (_categoryData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No category data available',
            style: GoogleFonts.inter(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFF4CAF50),
      const Color(0xFFFF5252),
      const Color(0xFFFF9800),
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: _categoryData.entries.map((entry) {
                  final index = _categoryData.keys.toList().indexOf(entry.key);
                  final color = colors[index % colors.length];
                  final total = _categoryData.values.reduce((a, b) => a + b);
                  final percentage = (entry.value / total * 100).toStringAsFixed(1);

                  return PieChartSectionData(
                    value: entry.value,
                    title: '$percentage%',
                    color: color,
                    radius: 80,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 0,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: _categoryData.entries.map((entry) {
              final index = _categoryData.keys.toList().indexOf(entry.key);
              final color = colors[index % colors.length];

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.key}: \$${entry.value.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrend() {
    Map<int, double> monthlyLent = {};
    Map<int, double> monthlyBorrowed = {};

    for (var transaction in _transactions) {
      final month = transaction.date.month;
      if (transaction.type == 'lent') {
        monthlyLent[month] = (monthlyLent[month] ?? 0) + transaction.amount;
      } else {
        monthlyBorrowed[month] = (monthlyBorrowed[month] ?? 0) + transaction.amount;
      }
    }

    final spots1 = List.generate(12, (index) {
      return FlSpot(index.toDouble(), monthlyLent[index + 1] ?? 0);
    });

    final spots2 = List.generate(12, (index) {
      return FlSpot(index.toDouble(), monthlyBorrowed[index + 1] ?? 0);
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Trend',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 100,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toInt()}',
                          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600]),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                        if (value.toInt() >= 0 && value.toInt() < 12) {
                          return Text(
                            months[value.toInt()],
                            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600]),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots1,
                    isCurved: true,
                    color: const Color(0xFF4CAF50),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: spots2,
                    isCurved: true,
                    color: const Color(0xFFFF5252),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFFF5252).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Lent', const Color(0xFF4CAF50)),
              const SizedBox(width: 24),
              _buildLegendItem('Borrowed', const Color(0xFFFF5252)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}