class SaleTransaction {
  final String id;
  final String productId;
  final String productName;
  final String category;
  final double price;
  final DateTime date;

  SaleTransaction({
    required this.id,
    required this.productId,
    required this.productName,
    required this.category,
    required this.price,
    required this.date,
  });

  factory SaleTransaction.fromMap(Map<String, dynamic> map, String id) {
    return SaleTransaction(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      category: map['category'] ?? '',
      price: map['price'] ?? 0.0,
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'category': category,
      'price': price,
      'date': date.toIso8601String(),
    };
  }
}
