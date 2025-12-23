import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ApiService _apiService = ApiService();
  List<CartItem> _cartItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _loading = true);

    _cartItems = await _apiService.fetchCart();

    setState(() => _loading = false);
  }

  double get totalPrice {
    return _cartItems.fold(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _cartItems.isEmpty
                      ? const Center(child: Text('Cart is empty'))
                      : ListView.builder(
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) {
                            final item = _cartItems[index];
                            return ListTile(
                              leading: Image.network(
                                item.product.imageUrl,
                                width: 50,
                                fit: BoxFit.cover,
                              ),
                              title: Text(item.product.name),
                              subtitle: Text(
                                'Rp ${item.product.price.toStringAsFixed(0)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () async {
                                      int newQty = item.quantity - 1;
                                      await _apiService.updateCartQty(
                                        productId: item.product.id,
                                        quantity: newQty,
                                      );
                                      if (newQty <= 0) {
                                        setState(() {
                                          _cartItems.removeAt(index);
                                        });
                                      } else {
                                        setState(() {
                                          _cartItems[index] = CartItem(
                                            product: item.product,
                                            quantity: newQty,
                                          );
                                        });
                                      }
                                    },
                                  ),

                                  Text(item.quantity.toString()),

                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () async {
                                      int newQty = item.quantity + 1;
                                      await _apiService.updateCartQty(
                                        productId: item.product.id,
                                        quantity: newQty,
                                      );
                                      setState(() {
                                        _cartItems[index] = CartItem(
                                          product: item.product,
                                          quantity: newQty,
                                        );
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // TOTAL & CHECKOUT
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Rp ${totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Checkout (next step 🚀)'),
                              ),
                            );
                          },
                          child: const Text('Checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
