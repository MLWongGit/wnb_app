import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'sales_summary_page.dart';
import '../utils/wifi_checker.dart';
import '../utils/dialog_helper.dart';

class OrderingStatusPage extends StatefulWidget {
  const OrderingStatusPage({super.key});

  @override
  State<OrderingStatusPage> createState() => _OrderingStatusPageState();
}

class _OrderingStatusPageState extends State<OrderingStatusPage> {
  double _addedAmount = 0.0; // accumulated amount added via the + button

  // Function to calculate and save sales summary
  Future<void> endOfSales(
    BuildContext context,
    List<QueryDocumentSnapshot> orders,
  ) async {
    try {
      if (orders.isEmpty) return;
      final salesSummaryCollection =
          FirebaseFirestore.instance.collection('salesSummary');

      DateTime earliest = orders
          .map((o) => (o['timestamp'] as Timestamp).toDate().toLocal())
          .reduce((a, b) => a.isBefore(b) ? a : b);

      final formattedDate =
          '${earliest.year.toString().padLeft(4, '0')}-${earliest.month.toString().padLeft(2, '0')}-${earliest.day.toString().padLeft(2, '0')}';

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
        final salesSummaryData = {
          'date': formattedDate,
          'totalSales': totalSales,
          'totalDrinksOrdered': totalDrinksOrdered,
          'listOfDrinksOrdered': listOfDrinksOrdered,
          'totalSalesAmount': totalSalesAmount,
        };
        await salesSummaryCollection.add(salesSummaryData);
      }

      final batch = FirebaseFirestore.instance.batch();
      for (var order in orders) {
        batch.delete(order.reference);
      }
      await batch.commit();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SalesSummaryPage()),
      );
    } catch (e) {
      print('Failed to complete end of sales: $e');
    }
  }

  // Return all remaining orders (current session). Earliest order will be the first sale.
  Stream<QuerySnapshot> fetchCurrentOrders() {
    return FirebaseFirestore.instance
        .collection('orders')
        .orderBy('timestamp', descending: false) // earliest first
        .snapshots();
  }

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
      await FirebaseFirestore.instance.collection('orders').doc(orderId).delete();
    } catch (e) {
      print('Failed to remove order: $e');
    }
  }

  // Show dialog to input an amount; add to _addedAmount
  Future<void> _addAmountDialog(BuildContext context) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add amount'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Enter amount (e.g. 5.50)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );

    if (confirmed == true) {
      final input = controller.text.trim();
      final value = double.tryParse(input.replaceAll(',', ''));
      if (value != null) {
        setState(() => _addedAmount += value);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid amount')),
        );
      }
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
                          DataColumn(label: Text('No.')),
                          DataColumn(label: Text('Action')),
                          DataColumn(label: Text('Price')),
                          DataColumn(label: Text('Orders')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Payment Status')),
                        ],
                        rows: List<DataRow>.generate(orders.length, (index) {
                          final order = orders[index];
                          final orderId = order.id;
                          final itemsList = order['items'] as List;
                          final Map<String, int> groupedItems = {};
                          for (var item in itemsList) {
                            final itemName = '${item['name']} ${item['type']}';
                            groupedItems[itemName] =
                                (groupedItems[itemName] ?? 0) + 1;
                          }
                          final formattedItems = groupedItems.entries
                              .map((entry) => entry.value > 1
                                  ? '${entry.key} x${entry.value}'
                                  : entry.key)
                              .join('; ');
                          final status = order['status'] as String;
                          final paymentStatus =
                              order['paymentStatus'] as String? ?? 'Unpaid';
                          final totalPrice = order['totalAmount'] as num;

                          return DataRow(cells: [
                            DataCell(Text('${index + 1}')),
                            DataCell(Row(
                              children: [
                                if (status != 'Complete')
                                  ElevatedButton(
                                    onPressed: () => markAsComplete(context, orderId),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                    child: const Text('Complete'),
                                  ),
                                const SizedBox(width: 8),
                                if (paymentStatus != 'Paid')
                                  ElevatedButton(
                                    onPressed: () => markAsPaid(context, orderId),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: const Text('Paid'),
                                  ),
                                const SizedBox(width: 8),
                                if (paymentStatus != 'Paid')
                                  ElevatedButton(
                                    onPressed: () async => await removeOrder(context, orderId),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: const Text('Remove'),
                                  ),
                                const SizedBox(width: 8),
                                // + button: add this order's price to _addedAmount
                                if (paymentStatus != 'Paid')
                                  IconButton(
                                    onPressed: () {
                                      final priceNum = (order['totalAmount'] as num?) ?? 0;
                                      setState(() => _addedAmount += priceNum.toDouble());
                                    },
                                    icon: const Icon(Icons.add, color: Colors.blue),
                                    tooltip: 'Add this amount',
                                  ),
                              ],
                            )),
                            DataCell(Text('\$${totalPrice.toStringAsFixed(2)}')),
                            DataCell(Text(formattedItems)),
                            DataCell(Text(
                              status,
                              style: TextStyle(color: status == 'Complete' ? Colors.green : Colors.orange),
                            )),
                            DataCell(Text(
                              paymentStatus,
                              style: TextStyle(color: paymentStatus == 'Paid' ? Colors.green : Colors.red),
                            )),
                          ]);
                        }),
                      ),
                    ),
                  ),
                ),
              ),

              // Display accumulated added amount
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    const Text('Added amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text('\$${_addedAmount.toStringAsFixed(2)}'),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() => _addedAmount = 0.0),
                      child: const Text('Clear'),
                    ),
                  ],
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
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  child: const Text('End of Sales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
