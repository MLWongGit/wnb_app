<<<<<<< HEAD
# wnb_app
=======
# Flutter Order App

This is a Flutter application for managing drink orders. The app allows users to select drinks, view their prices retrieved from Firebase, and submit their orders. It also calculates the total cost of the selected drinks, displays an order summary, and provides additional features such as tracking payment status and generating sales summaries.

## Features

- User-friendly interface to select drinks
- Real-time price retrieval from Firebase
- Order summary with total cost calculation
- Payment status tracking (Paid/Unpaid)
- End-of-sales functionality with sales summary generation
- Firebase integration for storing orders and sales summaries
- Sales summary page displaying daily sales data


## Setup Instructions

1. Clone the repository:
2. Navigate to the project directory:
3. Install the dependencies:
4. Set up Firebase for your project:
- Create a Firebase project in the Firebase console.
- Add your Android and iOS apps to the Firebase project.
- Download the `google-services.json` and `GoogleService-Info.plist` files and place them in the respective directories.
5. Run the application:

## Usage

- **Welcome Page**: Navigate to different sections of the app.
- **Order Page**: Select drinks, view prices, and place orders.
- **Ordering Status Page**:
  - Track the status of orders (Pending/Complete).
  - Track payment status (Paid/Unpaid).
  - Mark orders as "Complete" or "Paid."
  - Use the "End of Sales" button to generate a daily sales summary and clear all orders.
- **Sales Summary Page**:
  - View daily sales summaries in a table format.
  - Data includes:
 - Date
 - Total Sales
 - Total Drinks Ordered
 - Total Sales Amount

## Features Added

- **Grouped Orders**: Orders are displayed in a grouped format (e.g., `Black Hot x2; Mocha Cold`).
- **End of Sales**:
  - Generates a sales summary for the day.
  - Updates existing sales summary records if the date already exists.
  - Deletes all orders after generating the summary.
- **Sales Summary Page**:
  - Displays sales data ordered by date (latest to oldest).

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.
