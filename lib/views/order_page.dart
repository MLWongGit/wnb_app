import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'ordering_status_page.dart'; // Import the OrderingStatusPage

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  // Total amount
  int totalAmount = 0;

  // Example data for drinks with prices
  final drinks = [
    {'name': 'Black', 'hotPrice': 8, 'coldPrice': 9},
    {'name': 'White', 'hotPrice': 10, 'coldPrice': 11},
    {'name': 'Mocha', 'hotPrice': 13, 'coldPrice': 14},
    {'name': 'Dirty Matcha', 'hotPrice': 14, 'coldPrice': 15},
    {'name': 'Chocolate', 'hotPrice': 12, 'coldPrice': 13},
    {'name': 'Matcha Latte', 'hotPrice': 13, 'coldPrice': 14},
    {'name': 'Yuzu', 'hotPrice': 0, 'coldPrice': 14},
    {'name': 'Passion Fruit', 'hotPrice': 0, 'coldPrice': 14},
    {'name': 'Watermelon', 'hotPrice': 0, 'coldPrice': 14},
    {'name': 'Earl Grey', 'hotPrice': 6, 'coldPrice': 7},
    {'name': 'Lime & Ginger', 'hotPrice': 6, 'coldPrice': 7},
    {'name': 'Earl Grey & Tangerine', 'hotPrice': 6, 'coldPrice': 7},
    {'name': 'Lemon & Mandarin', 'hotPrice': 6, 'coldPrice': 7},
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No items in the order!')),
    );
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
    await FirebaseFirestore.instance.collection('orders').doc(orderId).set(orderData);

    // Navigate to the OrderingStatusPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderingStatusPage(),
      ),
    ).then((_) {
      // Clear the orders list and reset the total amount when returning
      setState(() {
        orders.clear();
        totalAmount = 0;
      });
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to place order: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Drinks'),
      ),
      body: Column(
        children: [
          // Drinks List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: drinks.length,
                itemBuilder: (context, index) {
                  final drink = drinks[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Drink Name
                        Text(
                          drink['name'] as String,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        // Buttons for Hot and Cold
                        Row(
                          children: [
                            if ((drink['hotPrice'] as int) > 0)
                              ElevatedButton(
                                onPressed: () {
                                  addToTotal(
                                    drink['name'] as String,
                                    'Hot',
                                    drink['hotPrice'] as int,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Hot'),
                              ),
                            if ((drink['hotPrice'] as int) > 0)
                              const SizedBox(width: 8),
                            if ((drink['coldPrice'] as int) > 0)
                              ElevatedButton(
                                onPressed: () {
                                  addToTotal(
                                    drink['name'] as String,
                                    'Cold',
                                    drink['coldPrice'] as int,
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
                  );
                },
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
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