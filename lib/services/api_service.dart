import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item.dart';
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

  // =========================
  // FETCH CART ITEMS
  // =========================
  Future<List<CartItem>> fetchCart() async {
    final cartSnap = await _firestore
        .collection('carts')
        .doc('active_cart')
        .get();

    if (!cartSnap.exists) return [];

    final items = Map<String, dynamic>.from(cartSnap['items']);

    List<CartItem> result = [];

    for (final entry in items.entries) {
      final productDoc = await _firestore
          .collection('products')
          .doc(entry.key)
          .get();

      if (!productDoc.exists) continue;

      final product = Product.fromMap(productDoc.data()!, productDoc.id);

      result.add(CartItem(product: product, quantity: entry.value['qty']));
    }

    return result;
  }

  // =========================
  // ADD TO CART
  // =========================
  Future<void> addToCart(String productId) async {
    final cartRef = _firestore.collection('carts').doc('active_cart');

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(cartRef);

      Map<String, dynamic> items = {};

      if (snap.exists) {
        items = Map<String, dynamic>.from(snap['items'] ?? {});
      }

      if (items.containsKey(productId)) {
        items[productId]['qty'] += 1;
      } else {
        items[productId] = {'qty': 1};
      }

      tx.set(cartRef, {'items': items});
    });
  }

  // =========================
  // UPDATE CART QUANTITY
  // =========================
  Future<void> updateCartQty({
    required String productId,
    required int quantity,
  }) async {
    final cartRef = _firestore.collection('carts').doc('active_cart');

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(cartRef);

      if (!snap.exists) return;

      Map<String, dynamic> items = Map<String, dynamic>.from(
        snap['items'] ?? {},
      );

      if (quantity <= 0) {
        items.remove(productId);
      } else {
        items[productId] = {'qty': quantity};
      }

      tx.set(cartRef, {'items': items});
    });
  }

  // =========================
  // REMOVE CART ITEM
  // =========================
  Future<void> removeFromCart(String cartId) async {
    await _firestore.collection('cart').doc(cartId).delete();
  }

  // =========================
  // CHECKOUT
  // =========================
  Future<void> checkout() async {
    final cartSnapshot = await _firestore.collection('cart').get();

    for (var doc in cartSnapshot.docs) {
      final data = doc.data();
      final productId = data['productId'];
      final quantity = data['quantity'];

      final productDoc = await _firestore
          .collection('products')
          .doc(productId)
          .get();

      final product = Product.fromMap(
        productDoc.data() as Map<String, dynamic>,
        productDoc.id,
      );

      // buat transaksi
      await _firestore.collection('transactions').add({
        'productId': product.id,
        'productName': product.name,
        'category': product.category,
        'price': product.price,
        'quantity': quantity,
        'date': Timestamp.now(),
      });

      // update totalSold
      await _firestore.collection('products').doc(product.id).update({
        'totalSold': FieldValue.increment(quantity),
      });
    }

    // kosongkan cart
    final batch = _firestore.batch();
    for (var doc in cartSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> updateCartQusntity({
    required String cartId,
    required int qty,
  }) async {
    if (qty <= 0) {
      // kalau qty 0 atau kurang → hapus item cart
      await _firestore.collection('cart').doc(cartId).delete();
    } else {
      await _firestore.collection('cart').doc(cartId).update({'qty': qty});
    }
  }
}
