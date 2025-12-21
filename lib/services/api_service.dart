import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import '../models/sale_transaction.dart';

class ApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all products
  Future<List<Product>> fetchProducts() async {
    QuerySnapshot snapshot = await _firestore.collection('products').get();

    return snapshot.docs.map((doc) {
      return Product.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id, // 🔥 WAJIB
      );
    }).toList();
  }

  // Sell a product
  Future<void> sellProduct(Product product) async {
    final transRef = _firestore.collection('transactions').doc();

    SaleTransaction transaction = SaleTransaction(
      id: transRef.id,
      productId: product.id,
      productName: product.name,
      category: product.category,
      price: product.price,
      date: DateTime.now(),
    );

    // Save transaction
    await transRef.set(transaction.toMap());

    // Update totalSold
    await _firestore.collection('products').doc(product.id).update({
      'totalSold': FieldValue.increment(1), // 🔥 LEBIH AMAN
    });
  }

  // Fetch transactions
  Future<List<SaleTransaction>> fetchTransactions() async {
    QuerySnapshot snapshot = await _firestore.collection('transactions').get();

    return snapshot.docs.map((doc) {
      return SaleTransaction.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }
}
