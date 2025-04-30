import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/drink_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Drink>> fetchDrinks() async {
    final drinksSnapshot = await _firestore.collection('drinks').get();
    return drinksSnapshot.docs
        .map((doc) => Drink.fromFirestore(doc.data()))
        .toList();
  }

  Future<void> saveOrder(Map<String, dynamic> orderData) async {
    await _firestore.collection('orders').add(orderData);
  }
}