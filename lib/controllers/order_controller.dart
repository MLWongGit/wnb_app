import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for FieldValue
import '../services/order_firebase_service.dart';

class OrderController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final Map<String, Map<String, dynamic>> _order = {};
  int _total = 0;

  Map<String, Map<String, dynamic>> get order => _order;
  int get total => _total;

  Future<void> fetchDrinks() async {
    final drinks = await _firebaseService.fetchDrinks();
    for (var drink in drinks) {
      _order[drink.typeOfDrink] = {
        'quantity': 0,
        'price': drink.price,
      };
    }
    notifyListeners();
  }

  void updateQuantity(String drink, int delta) {
    if (_order.containsKey(drink)) {
      _order[drink]!['quantity'] += delta;
      _total += (_order[drink]!['price'] as num).toInt();
      notifyListeners();
    }
  }

  Future<void> completeOrder() async {
    final orderDetails = _order.entries
        .where((entry) => entry.value['quantity'] > 0)
        .map((entry) => {
              'drink': entry.key,
              'quantity': entry.value['quantity'],
            })
        .toList();

    await _firebaseService.saveOrder({
      'order': orderDetails,
      'total': _total,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _order.updateAll((key, value) => {
          'quantity': 0,
          'price': value['price'],
        });
    _total = 0;
    notifyListeners();
  }
}