import 'package:flutter/material.dart';
import 'order_page.dart';
import 'ordering_status_page.dart'; 
import 'todays_sales_page.dart'; 
import 'sales_summary_page.dart'; 

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to \nWheels and Brews \nOrdering App',
              textAlign: TextAlign.center, // Center the text
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // ORDER HERE Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrderPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 148, 250, 153), // Green background
                padding: const EdgeInsets.symmetric(
                  horizontal: 55,
                  vertical: 16,
                ), // Larger padding for a bigger button
                textStyle: const TextStyle(
                  fontSize: 14, // Larger font size
                  fontWeight: FontWeight.bold, // Bold text
                ),
              ),
              child: const Text('ORDER HERE'),
            ),
            const SizedBox(height: 20), // Add spacing between buttons
            ElevatedButton(
              onPressed: () {
                // Navigate to OrderingStatusPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderingStatusPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 133, 200, 255),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ), // Smaller padding for a smaller button
                textStyle: const TextStyle(
                  fontSize: 14, // Smaller font size
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('ORDER SUMMARY'),
            ),
            // const SizedBox(height: 20), // Add spacing between buttons
            // ElevatedButton(
            //   onPressed: () {
            //     // Navigate to OrderingStatusPage
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => const TodaysSalesPage(),
            //       ),
            //     );
            //   },
            //   style: ElevatedButton.styleFrom(
            //     padding: const EdgeInsets.symmetric(
            //       horizontal: 20,
            //       vertical: 10,
            //     ), // Smaller padding for a smaller button
            //     textStyle: const TextStyle(
            //       fontSize: 12, // Smaller font size
            //     ),
            //   ),
            //   child: const Text("Today's sales summary"),
            // ),
            const SizedBox(height: 20), // Add spacing between buttons
            ElevatedButton(
              onPressed: () {
                // Navigate to OrderingStatusPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SalesSummaryPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ), // Smaller padding for a smaller button
                textStyle: const TextStyle(
                  fontSize: 12, // Smaller font size
                ),
              ),
              child: const Text("Sales Summary page"),
            ),
          ],
        ),
      ),
    );
  }
}