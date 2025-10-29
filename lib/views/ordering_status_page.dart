import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'sales_summary_page.dart';
import '../utils/wifi_checker.dart';
import '../utils/dialog_helper.dart';

class OrderingStatusPage extends StatelessWidget {
  const OrderingStatusPage({super.key});

  // Function to calculate and save sales summary
  Future<void> endOfSales(
    BuildContext context,
    List<QueryDocumentSnapshot> orders,
  ) async {
    try {
      // // Ensure there are orders to process
      // if (orders.isEmpty) {
      //   print('No orders to process for end of sales.');
      //   return;
      // }

      // // Get the date from the first order's timestamp
      // final Timestamp firstOrderTimestamp =
      //     orders.first['timestamp'] as Timestamp;
      // final DateTime firstOrderDate = firstOrderTimestamp.toDate();
      // final String formattedDate =
      //     firstOrderDate.toLocal().toString().split(' ')[0];

      // // Calculate metrics
      // final int totalSales = orders.length;
      // final int totalDrinksOrdered = orders.fold<int>(
      //   0,
      //   (sum, order) => sum + (order['items'] as List).length,
      // );
      // final Map<String, int> listOfDrinksOrdered = {};
      // for (var order in orders) {
      //   for (var item in order['items'] as List) {
      //     final drinkName = '${item['name']} ${item['type']}';
      //     listOfDrinksOrdered[drinkName] =
      //         (listOfDrinksOrdered[drinkName] ?? 0) + 1;
      //   }
      // }
      // final double totalSalesAmount = orders.fold<double>(
      //   0,
      //   (sum, order) => sum + (order['totalAmount'] as num).toDouble(),
      // );

      // // Check if a record for today's date already exists
      // final salesSummaryCollection = FirebaseFirestore.instance.collection(
      //   'salesSummary',
      // );
      // final existingSummaryQuery =
      //     await salesSummaryCollection
      //         .where('date', isEqualTo: formattedDate)
      //         .get();

      // if (existingSummaryQuery.docs.isNotEmpty) {
      //   // Update the existing record
      //   final existingSummary = existingSummaryQuery.docs.first;
      //   final existingData = existingSummary.data() as Map<String, dynamic>;

      //   // Update metrics
      //   final updatedTotalSales =
      //       (existingData['totalSales'] as int) + totalSales;
      //   final updatedTotalDrinksOrdered =
      //       (existingData['totalDrinksOrdered'] as int) + totalDrinksOrdered;
      //   final updatedListOfDrinksOrdered = Map<String, int>.from(
      //     existingData['listOfDrinksOrdered'] as Map,
      //   )..addAll(
      //     listOfDrinksOrdered.map(
      //       (key, value) => MapEntry(
      //         key,
      //         (existingData['listOfDrinksOrdered'][key] ?? 0) + value,
      //       ),
      //     ),
      //   );
      //   final updatedTotalSalesAmount =
      //       (existingData['totalSalesAmount'] as double) + totalSalesAmount;

      //   // Update Firestore document
      //   await salesSummaryCollection.doc(existingSummary.id).update({
      //     'totalSales': updatedTotalSales,
      //     'totalDrinksOrdered': updatedTotalDrinksOrdered,
      //     'listOfDrinksOrdered': updatedListOfDrinksOrdered,
      //     'totalSalesAmount': updatedTotalSalesAmount,
      //   });
      // } else {
      //   // Insert a new record
      //   final salesSummaryData = {
      //     'date': formattedDate,
      //     'totalSales': totalSales,
      //     'totalDrinksOrdered': totalDrinksOrdered,
      //     'listOfDrinksOrdered': listOfDrinksOrdered,
      //     'totalSalesAmount': totalSalesAmount,
      //   };

      //   await salesSummaryCollection.add(salesSummaryData);
      // }

      // // Delete all documents in the orders collection
      // final ordersCollection = FirebaseFirestore.instance.collection('orders');
      // final batch = FirebaseFirestore.instance.batch();
      // for (var order in orders) {
      //   batch.delete(order.reference);
      // }
      // await batch.commit();

      // // Redirect to SalesSummaryPage
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => const SalesSummaryPage()),
      // );
      if (orders.isEmpty) return;

      final salesSummaryCollection =
          FirebaseFirestore.instance.collection('salesSummary');

      // Find the earliest order timestamp (this becomes the "sales date")
      DateTime earliest = orders
          .map((o) => (o['timestamp'] as Timestamp).toDate().toLocal())
          .reduce((a, b) => a.isBefore(b) ? a : b);

      // Normalize to midnight local date (YYYY-MM-DD)
      final formattedDate =
          '${earliest.year.toString().padLeft(4, '0')}-${earliest.month.toString().padLeft(2, '0')}-${earliest.day.toString().padLeft(2, '0')}';

      // Aggregate metrics across all provided orders
      final int totalSales = orders.length;
      final int totalDrinksOrdered = orders.fold<int>(
        0,
        (sum, o) {
          final items = o['items'] as List<dynamic>? ?? [];
          return sum + items.length;
        },
      );

      final Map<String, int> listOfDrinksOrdered = {};
      double totalSalesAmount = 0.0;
      for (var o in orders) {
        final items = (o['items'] as List<dynamic>? ?? []);
        for (var item in items) {
          final name = '${item['name']} ${item['type']}';
          listOfDrinksOrdered[name] = (listOfDrinksOrdered[name] ?? 0) + 1;
        }
        totalSalesAmount += ((o['totalAmount'] as num?)?.toDouble() ?? 0.0);
      }

      // Check existing summary for this date
      final existingQuery = await salesSummaryCollection
          .where('date', isEqualTo: formattedDate)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        final existing = existingQuery.docs.first;
        final existingData = existing.data() as Map<String, dynamic>;

        final updatedTotalSales =
            (existingData['totalSales'] as int? ?? 0) + totalSales;
        final updatedTotalDrinks =
            (existingData['totalDrinksOrdered'] as int? ?? 0) + totalDrinksOrdered;

        // Merge drink maps safely
        final Map<String, int> updatedDrinks =
            Map<String, int>.from(existingData['listOfDrinksOrdered'] as Map? ?? {});
        listOfDrinksOrdered.forEach((key, value) {
          updatedDrinks[key] = (updatedDrinks[key] ?? 0) + value;
        });

        final updatedAmount =
            (existingData['totalSalesAmount'] as num? ?? 0.0) + totalSalesAmount;

        await salesSummaryCollection.doc(existing.id).update({
          'totalSales': updatedTotalSales,
          'totalDrinksOrdered': updatedTotalDrinks,
          'listOfDrinksOrdered': updatedDrinks,
          'totalSalesAmount': updatedAmount,
        });
      } else {
        // Create new summary document for this "sales date"
        final salesSummaryData = {
          'date': formattedDate,
          'totalSales': totalSales,
          'totalDrinksOrdered': totalDrinksOrdered,
          'listOfDrinksOrdered': listOfDrinksOrdered,
          'totalSalesAmount': totalSalesAmount,
        };
        await salesSummaryCollection.add(salesSummaryData);
      }

      // Delete processed orders in a batch
      final batch = FirebaseFirestore.instance.batch();
      for (var order in orders) {
        batch.delete(order.reference);
      }
      await batch.commit();

      // Navigate to SalesSummaryPage (or refresh as needed)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SalesSummaryPage()),
      );
    } catch (e) {
      print('Failed to complete end of sales: $e');
    }
  }

  // Function to fetch today's orders
  // Stream<QuerySnapshot> fetchTodaysOrders() {
  //   final now = DateTime.now();
  //   final startOfDay = DateTime(now.year, now.month, now.day);

  //   return FirebaseFirestore.instance
  //       .collection('orders')
  //       .where('timestamp', isLessThanOrEqualTo: startOfDay)
  //       .orderBy('timestamp', descending: true)
  //       .snapshots();
  // }

  // Replace fetchTodaysOrders with fetchCurrentOrders that returns all remaining orders
  Stream<QuerySnapshot> fetchCurrentOrders() {
    // Return all orders (current session). Earliest order will be the first sale.
    return FirebaseFirestore.instance
        .collection('orders')
        .orderBy('timestamp', descending: false) // earliest first
        .snapshots();
  }

  // Function to update the status of an order to "Complete"
  Future<void> markAsComplete(BuildContext context, String orderId) async {
    if (!await WifiChecker.isNetworkConnected()) {
      DialogHelper.showWifiWarning(context);
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'status': 'Complete'},
      );
    } catch (e) {
      print('Failed to update order status: $e');
    }
  }

  // Function to update the payment status of an order to "Paid"
  Future<void> markAsPaid(BuildContext context, String orderId) async {
    if (!await WifiChecker.isNetworkConnected()) {
      DialogHelper.showWifiWarning(context);
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'paymentStatus': 'Paid'},
      );
    } catch (e) {
      print('Failed to update payment status: $e');
    }
  }

  Future<void> removeOrder(BuildContext context, String orderId) async {
    if (!await WifiChecker.isNetworkConnected()) {
      DialogHelper.showWifiWarning(context);
      return;
    }
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
        stream: fetchCurrentOrders(),
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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('No.')), // Column for No.
                          DataColumn(
                            label: Text('Action'),
                          ), // Column for Action Buttons
                          DataColumn(label: Text('Price')), // Column for Price
                          DataColumn(
                            label: Text('Orders'),
                          ), // Column for Orders
                          DataColumn(
                            label: Text('Status'),
                          ), // Column for Status
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
                                        onPressed:
                                            () => markAsComplete(
                                              context,
                                              orderId,
                                            ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                        ),
                                        child: const Text('Complete'),
                                      ),
                                    const SizedBox(width: 8),
                                    // Paid Button
                                    if (paymentStatus != 'Paid')
                                      ElevatedButton(
                                        onPressed:
                                            () => markAsPaid(context, orderId),
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
                                            context,
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
              ),
              // End of Sales Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: hasUnpaidOrders
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm end of sales'),
                              content: const Text('This will finalise current session. Continue?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                          if (!await WifiChecker.isNetworkConnected()) {
                            DialogHelper.showWifiWarning(context);
                            return;
                          }
                          await endOfSales(context, orders);
                        },
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
