import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import '../models/sale_transaction.dart';

class ApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =========================
  // FETCH ALL PRODUCTS
  // =========================
  Future<List<Product>> fetchProducts() async {
    QuerySnapshot snapshot = await _firestore.collection('products').get();

    return snapshot.docs.map((doc) {
      return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  // =========================
  // ADD PRODUCT (CREATE)
  // =========================
  Future<void> addProduct({
    required String name,
    required String category,
    required double price,
    required String imageUrl,
    required String description,
  }) async {
    final docRef = _firestore.collection('products').doc();

    await docRef.set({
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'totalSold': 0,
      'imageUrl': imageUrl,
    });
  }

  // =========================
  // UPDATE PRODUCT (UPDATE)
  // =========================
  Future<void> updateProduct({
    required String id,
    required String name,
    required String category,
    required double price,
    required String imageUrl,
    required String description,
  }) async {
    await _firestore.collection('products').doc(id).update({
      'name': name,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
    });
  }

  // =========================
  // DELETE PRODUCT (HARD DELETE)
  // =========================
  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  // =========================
  // SELL PRODUCT (TRANSACTION)
  // =========================
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

    // save transaction
    await transRef.set(transaction.toMap());

    // update total sold
    await _firestore.collection('products').doc(product.id).update({
      'totalSold': FieldValue.increment(1),
    });
  }

  // =========================
  // FETCH TRANSACTIONS
  // =========================
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
