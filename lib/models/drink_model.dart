class Drink {
  final String typeOfDrink;
  final int price;

  Drink({required this.typeOfDrink, required this.price});

  factory Drink.fromFirestore(Map<String, dynamic> data) {
    return Drink(
      typeOfDrink: data['TypeOfDrink'],
      price: data['Price'],
    );
  }
}