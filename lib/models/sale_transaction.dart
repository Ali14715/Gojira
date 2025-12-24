import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction_item.dart';

class SaleTransaction {
  final String id;
  final DateTime createdAt;
  final List<TransactionItem> items;
  final double totalPrice;

  SaleTransaction({
    required this.id,
    required this.createdAt,
    required this.items,
    required this.totalPrice,
  });

  factory SaleTransaction.fromMap(Map<String, dynamic> map, String id) {
    return SaleTransaction(
      id: id,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      totalPrice: (map['totalPrice'] as num).toDouble(),
      items: (map['items'] as List)
          .map((e) => TransactionItem.fromMap(e))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdAt': Timestamp.fromDate(createdAt),
      'totalPrice': totalPrice,
      'items': items.map((e) => e.toMap()).toList(),
    };
  }
}
