import 'package:flutter/material.dart';

import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onSell;

  const ProductCard({super.key, required this.product, required this.onSell});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            height: 100,
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.orange),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),

          // Product Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.category,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                // Harga
                Text(
                  'Rp ${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 6),

                // Sold (di bawah harga)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Sold: ${product.totalSold}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSell,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text(
                      'Sell Product',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
