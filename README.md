# Flutter Order App

This is a simple Flutter application for managing drink orders. The app allows users to select drinks, view their prices retrieved from Firebase, and submit their orders. It also calculates the total cost of the selected drinks and displays an order summary upon completion.

## Features

- User-friendly interface to select drinks
- Real-time price retrieval from Firebase
- Order summary with total cost calculation
- Firebase integration for storing orders

## Project Structure

```
flutter_order_app
├── lib
│   ├── main.dart                # Entry point of the application
│   ├── screens
│   │   ├── home_screen.dart     # Home screen with navigation options
│   │   ├── order_screen.dart    # Screen for selecting drinks and placing orders
│   │   └── summary_screen.dart   # Screen displaying order summary and total cost
│   ├── models
│   │   └── drink_model.dart      # Model representing a drink
│   ├── services
│   │   ├── firebase_service.dart  # Service for Firebase interactions
│   │   └── order_service.dart     # Service for managing order logic
│   ├── widgets
│   │   ├── drink_list.dart        # Widget displaying available drinks
│   │   └── order_form.dart        # Widget for inputting order details
├── android
├── ios
├── pubspec.yaml                  # Flutter project configuration
└── README.md                     # Project documentation
```

## Setup Instructions

1. Clone the repository:
   ```
   git clone <repository-url>
   ```

2. Navigate to the project directory:
   ```
   cd flutter_order_app
   ```

3. Install the dependencies:
   ```
   flutter pub get
   ```

4. Set up Firebase for your project:
   - Create a Firebase project in the Firebase console.
   - Add your Android and iOS apps to the Firebase project.
   - Download the `google-services.json` and `GoogleService-Info.plist` files and place them in the respective directories.

5. Run the application:
   ```
   flutter run
   ```

## Usage

- Launch the app on your device or emulator.
- Navigate to the order screen to select drinks and place your order.
- View the summary of your order and the total cost after submission.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.