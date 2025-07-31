class Drink {
  final String name;
  final String type;
  final int hotPrice;
  final int coldPrice;

  Drink({
    required this.name,
    required this.type,
    required this.hotPrice,
    required this.coldPrice,
  });

  // Optional: for converting from a Map (if needed)
  factory Drink.fromMap(Map<String, dynamic> map) {
    return Drink(
      name: map['name'] as String,
      type: map['Type'] as String,
      hotPrice: map['hotPrice'] as int,
      coldPrice: map['coldPrice'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'Type': type,
      'hotPrice': hotPrice,
      'coldPrice': coldPrice,
    };
  }
}