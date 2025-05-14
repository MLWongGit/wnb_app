import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'sales_summary_page.dart';

class OrderingStatusPage extends StatelessWidget {
  const OrderingStatusPage({super.key});

  // Function to calculate and save sales summary
  Future<void> endOfSales(
    BuildContext context,
    List<QueryDocumentSnapshot> orders,
  ) async {
    try {
      // Ensure there are orders to process
      if (orders.isEmpty) {
        print('No orders to process for end of sales.');
        return;
      }

      // Get the date from the first order's timestamp
      final Timestamp firstOrderTimestamp = orders.first['timestamp'] as Timestamp;
      final DateTime firstOrderDate = firstOrderTimestamp.toDate();
      final String formattedDate = firstOrderDate.toLocal().toString().split(' ')[0];

      // Calculate metrics
      final int totalSales = orders.length;
      final int totalDrinksOrdered = orders.fold<int>(
        0,
        (sum, order) => sum + (order['items'] as List).length,
      );
      final Map<String, int> listOfDrinksOrdered = {};
      for (var order in orders) {
        for (var item in order['items'] as List) {
          final drinkName = '${item['name']} ${item['type']}';
          listOfDrinksOrdered[drinkName] =
              (listOfDrinksOrdered[drinkName] ?? 0) + 1;
        }
      }
      final double totalSalesAmount = orders.fold<double>(
        0,
        (sum, order) => sum + (order['totalAmount'] as num).toDouble(),
      );

      // Check if a record for today's date already exists
      final salesSummaryCollection = FirebaseFirestore.instance.collection(
        'salesSummary',
      );
      final existingSummaryQuery =
          await salesSummaryCollection
              .where('date', isEqualTo: formattedDate)
              .get();

      if (existingSummaryQuery.docs.isNotEmpty) {
        // Update the existing record
        final existingSummary = existingSummaryQuery.docs.first;
        final existingData = existingSummary.data() as Map<String, dynamic>;

        // Update metrics
        final updatedTotalSales =
            (existingData['totalSales'] as int) + totalSales;
        final updatedTotalDrinksOrdered =
            (existingData['totalDrinksOrdered'] as int) + totalDrinksOrdered;
        final updatedListOfDrinksOrdered = Map<String, int>.from(
          existingData['listOfDrinksOrdered'] as Map,
        )..addAll(
          listOfDrinksOrdered.map(
            (key, value) => MapEntry(
              key,
              (existingData['listOfDrinksOrdered'][key] ?? 0) + value,
            ),
          ),
        );
        final updatedTotalSalesAmount =
            (existingData['totalSalesAmount'] as double) + totalSalesAmount;

        // Update Firestore document
        await salesSummaryCollection.doc(existingSummary.id).update({
          'totalSales': updatedTotalSales,
          'totalDrinksOrdered': updatedTotalDrinksOrdered,
          'listOfDrinksOrdered': updatedListOfDrinksOrdered,
          'totalSalesAmount': updatedTotalSalesAmount,
        });
      } else {
        // Insert a new record
        final salesSummaryData = {
          'date': formattedDate,
          'totalSales': totalSales,
          'totalDrinksOrdered': totalDrinksOrdered,
          'listOfDrinksOrdered': listOfDrinksOrdered,
          'totalSalesAmount': totalSalesAmount,
        };

        await salesSummaryCollection.add(salesSummaryData);
      }

      // Delete all documents in the orders collection
      final ordersCollection = FirebaseFirestore.instance.collection('orders');
      final batch = FirebaseFirestore.instance.batch();
      for (var order in orders) {
        batch.delete(order.reference);
      }
      await batch.commit();

      // Redirect to SalesSummaryPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SalesSummaryPage()),
      );
    } catch (e) {
      print('Failed to complete end of sales: $e');
    }
  }

  // Function to fetch today's orders
  Stream<QuerySnapshot> fetchTodaysOrders() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return FirebaseFirestore.instance
        .collection('orders')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .snapshots();
  }

  // Function to update the status of an order to "Complete"
  Future<void> markAsComplete(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'status': 'Complete'},
      );
    } catch (e) {
      print('Failed to update order status: $e');
    }
  }

  // Function to update the payment status of an order to "Paid"
  Future<void> markAsPaid(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'paymentStatus': 'Paid'},
      );
    } catch (e) {
      print('Failed to update payment status: $e');
    }
  }

  Future<void> removeOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .delete();
      print('Order $orderId removed successfully.');
    } catch (e) {
      print('Failed to remove order: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Summary')),
      body: StreamBuilder<QuerySnapshot>(
        stream: fetchTodaysOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No orders found for today.'));
          }

          final orders = snapshot.data!.docs;

          // Check if there are any unpaid orders
          final hasUnpaidOrders = orders.any((order) {
            final paymentStatus = order['paymentStatus'] as String? ?? 'Unpaid';
            return paymentStatus == 'Unpaid';
          });

          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('No.')), // Column for No.
                        DataColumn(
                          label: Text('Action'),
                        ), // Column for Action Buttons
                        DataColumn(label: Text('Price')), // Column for Price
                        DataColumn(label: Text('Orders')), // Column for Orders
                        DataColumn(label: Text('Status')), // Column for Status
                        DataColumn(
                          label: Text('Payment Status'),
                        ), // Column for Payment Status
                      ],
                      rows: List<DataRow>.generate(orders.length, (index) {
                        final order = orders[index];
                        final orderId = order.id;

                        // Group and count items
                        final itemsList = order['items'] as List;
                        final Map<String, int> groupedItems = {};
                        for (var item in itemsList) {
                          final itemName = '${item['name']} ${item['type']}';
                          groupedItems[itemName] =
                              (groupedItems[itemName] ?? 0) + 1;
                        }

                        // Format items as "ItemName xCount"
                        final formattedItems = groupedItems.entries
                            .map(
                              (entry) =>
                                  entry.value > 1
                                      ? '${entry.key} x${entry.value}'
                                      : entry.key,
                            )
                            .join('; ');

                        final status = order['status'] as String;
                        final paymentStatus =
                            order['paymentStatus'] as String? ?? 'Unpaid';
                        final totalPrice =
                            order['totalAmount']
                                as num; // Assuming totalAmount is stored in the order

                        return DataRow(
                          cells: [
                            // No.
                            DataCell(Text('${index + 1}')),

                            // Action Buttons
                            DataCell(
                              Row(
                                children: [
                                  // Complete Button
                                  if (status != 'Complete')
                                    ElevatedButton(
                                      onPressed: () => markAsComplete(orderId),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                      ),
                                      child: const Text('Complete'),
                                    ),
                                  const SizedBox(width: 8),
                                  // Paid Button
                                  if (paymentStatus != 'Paid')
                                    ElevatedButton(
                                      onPressed: () => markAsPaid(orderId),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      child: const Text('Paid'),
                                    ),
                                  const SizedBox(width: 8),
                                  // Remove Button
                                  if (paymentStatus != 'Paid')
                                    ElevatedButton(
                                      onPressed: () async {
                                        await removeOrder(
                                          orderId,
                                        ); // Remove the order
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text('Remove'),
                                    ),
                                ],
                              ),
                            ),

                            // Price
                            DataCell(
                              Text('\$${totalPrice.toStringAsFixed(2)}'),
                            ),

                            // Orders
                            DataCell(Text(formattedItems)),

                            // Status
                            DataCell(
                              Text(
                                status,
                                style: TextStyle(
                                  color:
                                      status == 'Complete'
                                          ? Colors.green
                                          : Colors.orange,
                                ),
                              ),
                            ),

                            // Payment Status
                            DataCell(
                              Text(
                                paymentStatus,
                                style: TextStyle(
                                  color:
                                      paymentStatus == 'Paid'
                                          ? Colors.green
                                          : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
              // End of Sales Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed:
                      hasUnpaidOrders
                          ? null
                          : () => endOfSales(context, orders),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasUnpaidOrders ? Colors.grey : Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'End of Sales',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
