import 'package:flutter/material.dart';

class DialogHelper {
  static void showWifiWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('WiFi Not Connected'),
        content: const Text('Please connect to WiFi to use the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}