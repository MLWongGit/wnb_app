import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SalesSummaryPage extends StatelessWidget {
  const SalesSummaryPage({super.key});

  // Function to fetch sales summary ordered by date (latest to oldest)
  Stream<QuerySnapshot> fetchSalesSummary() {
    return FirebaseFirestore.instance
        .collection('salesSummary')
        .orderBy('date', descending: true) // Order by date in descending order
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Summary'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: fetchSalesSummary(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No sales summary available.'),
            );
          }

          final summaries = snapshot.data!.docs;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Total Sales')),
                DataColumn(label: Text('Total Drinks Ordered')),
                DataColumn(label: Text('Total Sales Amount')),
              ],
              rows: summaries.map((summary) {
                final data = summary.data() as Map<String, dynamic>;
                return DataRow(
                  cells: [
                    DataCell(Text(data['date'] as String)),
                    DataCell(Text(data['totalSales'].toString())),
                    DataCell(Text(data['totalDrinksOrdered'].toString())),
                    DataCell(Text('\$${data['totalSalesAmount'].toStringAsFixed(2)}')),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}