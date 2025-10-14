// ...existing code...
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SalesSummaryPage extends StatefulWidget {
  const SalesSummaryPage({super.key});

  @override
  State<SalesSummaryPage> createState() => _SalesSummaryPageState();
}

class _SalesSummaryPageState extends State<SalesSummaryPage> {
  DateTime? _selectedMonthStart; // null = All
  final List<String> _monthNames = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  // Generate last 12 months (including current)
  List<DateTime> get _recentMonthStarts {
    final now = DateTime.now();
    return List.generate(12, (i) {
      final dt = DateTime(now.year, now.month - i, 1);
      return DateTime(dt.year, dt.month, 1);
    });
  }

  String _monthLabel(DateTime dt) => '${_monthNames[dt.month - 1]} ${dt.year}';

  String _formatDateYMD(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Stream<QuerySnapshot> fetchSalesSummary() {
    final collection = FirebaseFirestore.instance.collection('salesSummary');
    if (_selectedMonthStart == null) {
      return collection.orderBy('date', descending: true).snapshots();
    }

    final start = _selectedMonthStart!;
    final end = DateTime(start.year, start.month + 1, 1);
    final startStr = _formatDateYMD(start);
    final endStr = _formatDateYMD(end);

    return collection
        .where('date', isGreaterThanOrEqualTo: startStr)
        .where('date', isLessThan: endStr)
        .orderBy('date', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final months = _recentMonthStarts;
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Summary')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Text('Filter by month:'),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<DateTime?>(
                    isExpanded: true,
                    value: _selectedMonthStart,
                    items: [
                      const DropdownMenuItem<DateTime?>(
                        value: null,
                        child: Text('All months'),
                      ),
                      ...months.map((m) => DropdownMenuItem<DateTime?>(
                            value: m,
                            child: Text(_monthLabel(m)),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedMonthStart = value);
                    },
                  ),
                ),
                if (_selectedMonthStart != null) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => setState(() => _selectedMonthStart = null),
                    child: const Text('Clear'),
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: fetchSalesSummary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No sales summary available.'));
                }

                final summaries = snapshot.data!.docs;

                // compute totals for the current filter
                int totalSalesSum = 0;
                int totalDrinksOrderedSum = 0;
                double totalSalesAmountSum = 0.0;
                for (var doc in summaries) {
                  final data = doc.data() as Map<String, dynamic>;
                  totalSalesSum += (data['totalSales'] as int?) ?? 0;
                  totalDrinksOrderedSum += (data['totalDrinksOrdered'] as int?) ?? 0;
                  totalSalesAmountSum += ((data['totalSalesAmount'] as num?)?.toDouble() ?? 0.0);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      child: Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Sales', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(totalSalesSum.toString()),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Drinks', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(totalDrinksOrderedSum.toString()),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('\$${totalSalesAmountSum.toStringAsFixed(2)}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Total Sales')),
                              DataColumn(label: Text('Total Drinks Ordered')),
                              DataColumn(label: Text('Total Sales Amount')),
                            ],
                            rows: summaries.map((summary) {
                              final data = summary.data() as Map<String, dynamic>;
                              final totalSalesAmount = (data['totalSalesAmount'] as num?)?.toDouble() ?? 0.0;
                              return DataRow(
                                cells: [
                                  DataCell(Text(data['date'] as String? ?? '')),
                                  DataCell(Text((data['totalSales'] ?? 0).toString())),
                                  DataCell(Text((data['totalDrinksOrdered'] ?? 0).toString())),
                                  DataCell(Text('\$${totalSalesAmount.toStringAsFixed(2)}')),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}