import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/order_controller.dart';

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<OrderController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Drinks'),
      ),
      body: controller.order.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: controller.order.keys.length,
              itemBuilder: (context, index) {
                final drink = controller.order.keys.elementAt(index);
                return ListTile(
                  title: Text(drink),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () => controller.updateQuantity(drink, -1),
                      ),
                      Text('${controller.order[drink]!['quantity']}'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => controller.updateQuantity(drink, 1),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: controller.completeOrder,
          child: Text('Complete Order (\$${controller.total})'),
        ),
      ),
    );
  }
}