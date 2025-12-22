class Product {
  final String id;
  final String name;
  final String category;
  final String description; // 🔥 NEW
  final double price;
  int totalSold;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description, // 🔥 NEW
    required this.price,
    required this.totalSold,
    required this.imageUrl,
  });

  factory Product.fromMap(Map<String, dynamic> map, String docId) {
    return Product(
      id: docId,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '', // 🔥 NEW
      price: (map['price'] ?? 0).toDouble(),
      totalSold: map['totalSold'] ?? 0,
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'description': description, // 🔥 NEW
      'price': price,
      'totalSold': totalSold,
      'imageUrl': imageUrl,
    };
  }
}
