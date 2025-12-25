import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/sale_transaction.dart';
import '../models/transaction_item.dart';

class ApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
  Future<void> sellProduct(Product product, {int quantity = 1}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final transRef = _firestore.collection('transactions').doc();

    SaleTransaction transaction = SaleTransaction(
      id: transRef.id,
      userId: user.uid,
      createdAt: DateTime.now(),
      items: [
        TransactionItem(
          productId: product.id,
          name: product.name,
          category: product.category,
          price: product.price,
          quantity: quantity,
        ),
      ],
      totalPrice: product.price * quantity,
    );

    // save transaction
    await transRef.set(transaction.toMap());

    // update total sold
    await _firestore.collection('products').doc(product.id).update({
      'totalSold': FieldValue.increment(quantity),
    });
  }

  // =========================
  // FETCH TRANSACTIONS
  // =========================
  Future<List<SaleTransaction>> fetchTransactions() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final snapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: user.uid)
        .get();

    return snapshot.docs.map((doc) {
      return SaleTransaction.fromMap(doc.data(), doc.id);
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
  // CHECKOUT (1 transaksi)
  // =========================
  Future<void> checkout() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final cartItems = await fetchCart();

    if (cartItems.isEmpty) return;

    double totalPrice = 0;
    List<Map<String, dynamic>> items = [];

    for (var cartItem in cartItems) {
      totalPrice += cartItem.product.price * cartItem.quantity;

      items.add({
        'productId': cartItem.product.id,
        'name': cartItem.product.name,
        'category': cartItem.product.category,
        'price': cartItem.product.price,
        'quantity': cartItem.quantity,
      });

      // update total sold
      await _firestore.collection('products').doc(cartItem.product.id).update({
        'totalSold': FieldValue.increment(cartItem.quantity),
      });
    }

    // simpan 1 transaksi
    await _firestore.collection('transactions').add({
      'userId': user.uid,
      'createdAt': Timestamp.now(),
      'totalPrice': totalPrice,
      'items': items,
    });

    // Clear cart
    await _firestore.collection('carts').doc('active_cart').delete();
  }
  // =========================
  // UPDATE CART QUANTITY (ALTERNATIVE)

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
