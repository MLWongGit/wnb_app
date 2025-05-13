import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TodaysSalesPage extends StatelessWidget {
  const TodaysSalesPage({super.key});

  // Function to fetch today's orders
  Stream<QuerySnapshot> fetchTodaysOrders() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return FirebaseFirestore.instance
        .collection('orders')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Sales"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: fetchTodaysOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No sales data available for today.'),
            );
          }

          final orders = snapshot.data!.docs;

          // Calculate metrics
          final int numberOfSales = orders.length;
          final int numberOfDrinks = orders.fold<int>(
            0,
            (sum, order) => sum + (order['items'] as List).length,
          );
          final double totalSalesAmount = orders.fold<double>(
            0,
            (sum, order) => sum + (order['totalAmount'] as num).toDouble(),
          );

          // Format today's date
          final String todayDate = DateTime.now().toLocal().toString().split(' ')[0];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('No of Sales')),
                  DataColumn(label: Text('No of Drinks')),
                  DataColumn(label: Text('Total Sales Amount')),
                ],
                rows: [
                  DataRow(
                    cells: [
                      DataCell(Text(todayDate)),
                      DataCell(Text(numberOfSales.toString())),
                      DataCell(Text(numberOfDrinks.toString())),
                      DataCell(Text('\$${totalSalesAmount.toStringAsFixed(2)}')),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}