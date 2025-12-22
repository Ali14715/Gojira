import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/sale_transaction.dart';
import '../services/api_service.dart';
import '../widgets/sales_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  List<SaleTransaction> _transactions = [];
  bool _isLoading = true;
  double _totalSales = 0;
  Map<String, double> _salesPerCategory = {};
  String _bestSellingProduct = '';
  final List<double> _salesTrend = List.filled(7, 0);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() async {
    try {
      _products = await _apiService.fetchProducts();
      _transactions = await _apiService.fetchTransactions();
      _computeData();
    } catch (e) {
      print('Failed to load dashboard data: $e');
      _products = [];
      _transactions = [];
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _computeData() {
    // Total sales
    _totalSales = _transactions.fold(0.0, (sum, t) => sum + t.price);

    // Sales per category
    _salesPerCategory = {};
    for (var t in _transactions) {
      _salesPerCategory[t.category] =
          (_salesPerCategory[t.category] ?? 0) + t.price;
    }

    // Best selling product
    if (_products.isNotEmpty) {
      Product best = _products.reduce(
        (a, b) => a.totalSold > b.totalSold ? a : b,
      );
      _bestSellingProduct = best.name;
    }

    // Sales trend for last 7 days
    DateTime now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      DateTime day = now.subtract(Duration(days: i));
      double sales = _transactions
          .where(
            (t) =>
                t.date.year == day.year &&
                t.date.month == day.month &&
                t.date.day == day.day,
          )
          .fold(0.0, (sum, t) => sum + t.price);
      _salesTrend[6 - i] = sales; // Reverse for chart (oldest to newest)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Business Overview',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Metrics Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Total Sales',
                          'Rp.${_totalSales.toStringAsFixed(0)}',
                          Icons.attach_money,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'Products',
                          '${_products.length}',
                          Icons.inventory,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Transactions',
                          '${_transactions.length}',
                          Icons.receipt,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'Categories',
                          '${_salesPerCategory.length}',
                          Icons.category,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Best Selling Product
                  Container(
                    padding: const EdgeInsets.all(20),
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
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber[600]),
                            const SizedBox(width: 8),
                            const Text(
                              'Best Selling Product',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _bestSellingProduct.isEmpty
                              ? 'No data available'
                              : _bestSellingProduct,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Sales by Category
                  Container(
                    padding: const EdgeInsets.all(20),
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
                        const Text(
                          'Sales by Category',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _salesPerCategory.isEmpty
                            ? const Text(
                                'No sales data available',
                                style: TextStyle(color: Colors.grey),
                              )
                            : Column(
                                children: _salesPerCategory.entries.map((
                                  entry,
                                ) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        Text(
                                          'Rp.${entry.value.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Sales Trend Chart
                  Container(
                    padding: const EdgeInsets.all(20),
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
                        const Text(
                          'Sales Trend (Last 7 Days)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: SalesChart(salesData: _salesTrend),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
