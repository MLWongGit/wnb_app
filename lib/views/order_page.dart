import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'ordering_status_page.dart'; // Import the OrderingStatusPage
import '../utils/wifi_checker.dart';
import '../utils/dialog_helper.dart';
import '../models/drinkOption_model.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  // Total amount
  int totalAmount = 0;

  // Example data for drinks with prices
  final List<Drink> drinks = [
    //CAFFINE
    Drink(name: 'Black', type: 'CAFFINE', hotPrice: 8, coldPrice: 9),
    Drink(name: 'White', type: 'CAFFINE', hotPrice: 10, coldPrice: 11),
    Drink(name: 'Mocha', type: 'CAFFINE', hotPrice: 13, coldPrice: 14),
    Drink(name: 'Dirty Matcha', type: 'CAFFINE', hotPrice: 14, coldPrice: 15),
    Drink(name: 'Orange Black', type: 'CAFFINE', hotPrice: 0, coldPrice: 11),
    Drink(name: 'Flavoured Coffee', type: 'CAFFINE', hotPrice: 0, coldPrice: 2),
    Drink(name: 'Additional Request', type: 'CAFFINE', hotPrice: 0, coldPrice: 1),
    
    //NON-CAFFINE
    Drink(name: 'Chocolate', type: 'NON-CAFFINE', hotPrice: 12, coldPrice: 13),
    Drink(name: 'Matcha Latte', type: 'NON-CAFFINE', hotPrice: 13, coldPrice: 14),
    Drink(name: 'Matcha Strawberry', type: 'NON-CAFFINE', hotPrice: 0, coldPrice: 16),

    //TEA BASED
    Drink(name: 'Yuzu', type: 'TEA BASED', hotPrice: 0, coldPrice: 14),
    Drink(name: 'Passion Fruit', type: 'TEA BASED', hotPrice: 0, coldPrice: 14),
    Drink(name: 'Watermelon', type: 'TEA BASED', hotPrice: 0, coldPrice: 14),
    Drink(name: 'Strawberry', type: 'TEA BASED', hotPrice: 0, coldPrice: 14),
    Drink(name: 'Pineapple', type: 'TEA BASED', hotPrice: 0, coldPrice: 14),

    //SPARKLING WATER
    Drink(name: 'Strawberry', type: 'SPARKLING', hotPrice: 0, coldPrice: 15),
    Drink(name: 'Pineapple', type: 'SPARKLING', hotPrice: 0, coldPrice: 15),
    Drink(name: 'Mint Sour Plum', type: 'SPARKLING', hotPrice: 0, coldPrice: 15),
    Drink(name: 'Lychee', type: 'SPARKLING', hotPrice: 0, coldPrice: 15),

    //TEA BAG
    Drink(name: 'Tea bag', type: 'TEA BAG', hotPrice: 6, coldPrice: 7)
  ];

  // List to store orders
  final List<Map<String, dynamic>> orders = [];

  // Function to add to the total amount and add an order
  void addToTotal(String name, String type, int amount) {
    setState(() {
      totalAmount += amount;
      orders.add({'name': name, 'type': type, 'price': amount});
    });
  }

  // Function to remove an order
  void removeOrder(int index) {
    setState(() {
      totalAmount -= orders[index]['price'] as int;
      orders.removeAt(index);
    });
  }

  // Function to clear the total amount and orders
  void clearTotal() {
    setState(() {
      totalAmount = 0;
      orders.clear();
    });
  }

  // Function to place the order
  Future<void> placeOrder() async {
    if (orders.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No items in the order!')));
      return;
    }

    // Check WiFi before proceeding
    if (!await WifiChecker.isNetworkConnected()) {
      DialogHelper.showWifiWarning(context);
      return;
    }

    try {
      // Generate a unique order ID
      final orderId = FirebaseFirestore.instance.collection('orders').doc().id;

      // Create the order data
      final orderData = {
        'orderId': orderId,
        'timestamp': FieldValue.serverTimestamp(),
        'totalAmount': totalAmount,
        'status': 'Pending',
        'paymentStatus': 'Unpaid',
        'items': orders,
      };

      // Save the order to Firestore
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .set(orderData);

      // Navigate to the OrderingStatusPage
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OrderingStatusPage()),
      ).then((_) {
        // Clear the orders list and reset the total amount when returning
        setState(() {
          orders.clear();
          totalAmount = 0;
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
    }
  }

  Map<String, List<Drink>> getDrinksByType() {
  final Map<String, List<Drink>> grouped = {};
  for (var drink in drinks) {
    grouped.putIfAbsent(drink.type, () => []).add(drink);
  }
  return grouped;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Drinks')),
      body: Column(
        children: [
          // Drinks List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children:
                    getDrinksByType().entries.map((entry) {
                      final type = entry.key;
                      final drinksList = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              type,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ),
                          ...drinksList.map(
                            (drink) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Drink Name
                                  Text(drink.name),
                                    // Buttons for Hot and Cold
                                    Row(
                                    children: [
                                      if ( drink.hotPrice > 0)
                                        ElevatedButton(
                                          onPressed: () {
                                            addToTotal(
                                              drink.name,
                                              'Hot',
                                              drink.hotPrice,
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('Hot'),
                                        ),
                                      if (drink.hotPrice > 0)
                                        const SizedBox(width: 8),
                                      if (drink.coldPrice > 0)
                                        ElevatedButton(
                                          onPressed: () {
                                            addToTotal(
                                              drink.name,
                                              'Cold',
                                              drink.coldPrice,
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                          ),
                                          child: const Text('Cold'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
          // Orders Table
          if (orders.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(order['name'] as String),
                          Text(order['type'] as String),
                          ElevatedButton(
                            onPressed: () => removeOrder(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                            ),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          // Total Amount, Clear Button, and Place Order Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Total Amount: \$${totalAmount.toString()}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: clearTotal,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('Clear'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Place Order'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
