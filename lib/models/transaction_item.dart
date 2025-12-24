class TransactionItem {
  final String productId;
  final String name;
  final String category;
  final double price;
  final int quantity;

  TransactionItem({
    required this.productId,
    required this.name,
    required this.category,
    required this.price,
    required this.quantity,
  });

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      productId: map['productId'],
      name: map['name'],
      category: map['category'],
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'category': category,
      'price': price,
      'quantity': quantity,
    };
  }
}
