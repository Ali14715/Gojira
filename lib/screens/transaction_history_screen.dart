import 'package:flutter/material.dart';

import '../models/sale_transaction.dart';
import '../services/api_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  _TransactionHistoryScreenState createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final ApiService _apiService = ApiService();
  List<SaleTransaction> _allTransactions = [];
  List<SaleTransaction> _filteredTransactions = [];
  bool _isLoading = true;
  bool _showFilters = false; // Add this for filter visibility

  // Filter variables
  String _selectedCategory = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      _allTransactions = await _apiService.fetchTransactions();
      _applyFilters();
    } catch (e) {
      print('Failed to load transactions: $e');
      _allTransactions = [];
      _filteredTransactions = [];
    }
    setState(() => _isLoading = false);
  }

  void _onSearchChanged() {
    _searchQuery = _searchController.text.toLowerCase();
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredTransactions = _allTransactions.where((transaction) {
        // Search filter
        bool matchesSearch =
            _searchQuery.isEmpty ||
            transaction.items.any(
              (item) => item.name.toLowerCase().contains(_searchQuery),
            );

        // Category filter
        bool matchesCategory =
            _selectedCategory == 'All' ||
            transaction.items.any((item) => item.category == _selectedCategory);

        // Date filter
        bool matchesDate = true;
        if (_startDate != null && _endDate != null) {
          matchesDate =
              transaction.createdAt.isAfter(
                _startDate!.subtract(const Duration(days: 1)),
              ) &&
              transaction.createdAt.isBefore(
                _endDate!.add(const Duration(days: 1)),
              );
        }

        return matchesSearch && matchesCategory && matchesDate;
      }).toList();

      // Sort by date descending
      _filteredTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _applyFilters();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'All';
      _startDate = null;
      _endDate = null;
      _searchController.clear();
      _filteredTransactions = List.from(_allTransactions);
      _filteredTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get unique categories
    final categories = {
      'All',
      ..._allTransactions.expand((t) => t.items.map((i) => i.category)),
    };

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Transaction History',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Column(
              children: [
                // FILTERS
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Search bar with filter toggle
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search by product name...',
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.grey,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _showFilters ? Icons.filter_list_off : Icons.filter_list,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showFilters = !_showFilters;
                                });
                              },
                            ),
                          ],
                        ),

                        // Filter options (shown when _showFilters is true)
                        if (_showFilters) ...[
                          const SizedBox(height: 8),
                          // Category and Date filters
                          Row(
                            children: [
                              // Category dropdown
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  items: categories.map((category) {
                                    return DropdownMenuItem(
                                      value: category,
                                      child: Text(category),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value!;
                                      _applyFilters();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Date range button
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _selectDateRange,
                                  icon: const Icon(
                                    Icons.date_range,
                                    color: Colors.black,
                                  ),
                                  label: Text(
                                    _startDate != null && _endDate != null
                                        ? '${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}'
                                        : 'Select Date Range',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Clear filters
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: _clearFilters,
                              child: const Text('Clear Filters'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // TRANSACTION LIST
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No transactions found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _filteredTransactions[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ExpansionTile(
                                title: Row(
                                  children: [
                                    Text(
                                      'Rp.${transaction.totalPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${transaction.createdAt.day}/${transaction.createdAt.month}/${transaction.createdAt.year}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  '${transaction.items.length} item(s)',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                children: transaction.items.map((item) {
                                  return ListTile(
                                    title: Text(item.name),
                                    subtitle: Text(
                                      '${item.category} - Qty: ${item.quantity}',
                                    ),
                                    trailing: Text(
                                      'Rp.${(item.price * item.quantity).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
