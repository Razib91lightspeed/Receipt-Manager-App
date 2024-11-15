import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logger.dart';
import '../services/receipt_service.dart';
import 'authentication_provider.dart';
import 'category_provider.dart';

enum TimeInterval { day, week, month, year }

class ReceiptProvider extends ChangeNotifier {
  final ReceiptService _receiptService = ReceiptService();
  AuthenticationProvider? _authProvider;
  CategoryProvider? _categoryProvider;

  // State properties
  // Default date range: start date is one year ago, end date is today
  DateTime? _startDate = DateTime(
      DateTime.now().year - 1, DateTime.now().month, DateTime.now().day);
  DateTime? _endDate = DateTime.now();
  String _sortOption = "Newest";
  List<String> _selectedPaymentMethods = [
    'Credit Card',
    'Debit Card',
    'Cash',
    'Others'
  ];
  List<String> _selectedCategoryIds = [];

  Map<String, Map<String, dynamic>>? _groupedReceiptsByCategory;
  Map<String, double>? _groupedReceiptsByDate;
  Map<String, double>? _groupedReceiptsByInterval;

  List<Map<String, dynamic>> _allReceipts = [];
  List<Map<String, dynamic>> _filteredReceipts = [];
  int? _receiptCount;
  Map<String, DateTime>? _oldestAndNewestDates;

  List<Map<String, dynamic>> get allReceipts => _allReceipts;
  int? get receiptCount => _receiptCount;
  Map<String, DateTime>? get oldestAndNewestDates => _oldestAndNewestDates;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  List<String> get selectedPaymentMethods => _selectedPaymentMethods;
  List<String> get selectedCategoryIds => _selectedCategoryIds;
  Map<String, Map<String, dynamic>>? get groupedReceiptsByCategory =>
      _groupedReceiptsByCategory;
  Map<String, double>? get groupedReceiptsByDate => _groupedReceiptsByDate;
  Map<String, double>? get groupedReceiptsByInterval =>
      _groupedReceiptsByInterval;
  List<Map<String, dynamic>> get filteredReceipts => _filteredReceipts;
  String get sortOption => _sortOption;

  // Inject AuthenticationProvider and CategoryProvider
  set authProvider(AuthenticationProvider authProvider) {
    _authProvider = authProvider;
    notifyListeners();
  }

  set categoryProvider(CategoryProvider categoryProvider) {
    _categoryProvider = categoryProvider;
    _selectedCategoryIds = _categoryProvider!.categories
        .map((cat) => cat['id'] as String)
        .toList();
    _selectedCategoryIds.add('null');
    notifyListeners();
  }

  String? get _userEmail => _authProvider?.user?.email;

  TimeInterval _selectedInterval = TimeInterval.month;

  TimeInterval get selectedInterval => _selectedInterval;

  void updateInterval(TimeInterval interval) {
    _selectedInterval = interval;
    groupByInterval(interval); // Regroup receipts based on the new interval
    notifyListeners();
  }

  // Update filters
  void updateFilters({
    required String sortOption,
    required List<String> paymentMethods,
    required List<String> categoryIds,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _sortOption = sortOption;
    _selectedPaymentMethods = paymentMethods;
    _selectedCategoryIds = categoryIds;
    _startDate = startDate;
    _endDate = endDate;

    // Log updated filters
    print('Updated Filters:');
    print('Sort Option: $_sortOption');
    print('Payment Methods: $_selectedPaymentMethods');
    print('Category IDs: $_selectedCategoryIds');
    print('Start Date: $_startDate');
    print('End Date: $_endDate');

    notifyListeners();
  }

// Fetch and filter receipts
  Stream<List<Map<String, dynamic>>> fetchReceipts() async* {
    try {
      final userDoc =
          FirebaseFirestore.instance.collection('receipts').doc(_userEmail);
      await for (var snapshot in userDoc.snapshots()) {
        if (snapshot.data() == null) {
          print('No receipts found.');
          yield [];
          continue;
        }

        _allReceipts = (snapshot.data()?['receiptlist'] ?? [])
            .cast<Map<String, dynamic>>();

        // Apply filters
        _filteredReceipts = _applyFilters(_allReceipts);

        // Log filtered receipts
        print('Filtered Receipts (${_filteredReceipts.length}):');
        for (var receipt in _filteredReceipts) {
          print(receipt);
        }

        yield _filteredReceipts;
      }
    } catch (e) {
      logger.e("Error fetching receipts: $e");
      yield [];
    }
  }

  // Apply filters to receipts
  List<Map<String, dynamic>> _applyFilters(
      List<Map<String, dynamic>> receipts) {
    const primaryMethods = ['Credit Card', 'Debit Card', 'Cash'];

    // Apply filters
    final filteredReceipts = receipts.where((receipt) {
      // Handle default values for missing fields
      final categoryId = receipt['categoryId'] ?? 'null';
      final paymentMethod = receipt['paymentMethod'] ?? '';
      final date = (receipt['date'] as Timestamp?)?.toDate() ?? DateTime.now();

      // Check if the category matches
      final matchesCategory = _selectedCategoryIds.contains(categoryId);

      // Check if the payment method matches
      bool matchesPaymentMethod;
      if (_selectedPaymentMethods.isEmpty ||
          _selectedPaymentMethods.contains(paymentMethod)) {
        matchesPaymentMethod = true;
      } else if (_selectedPaymentMethods.contains('Others')) {
        // If "Others" is selected, match any method not in primaryMethods
        matchesPaymentMethod = !primaryMethods.contains(paymentMethod);
      } else {
        matchesPaymentMethod = false;
      }

      // Check if the date falls within the selected range
      final matchesDate = (_startDate == null || date.isAfter(_startDate!)) &&
          (_endDate == null || date.isBefore(_endDate!));

      // Log for debugging
      logger.i("Category ID: $categoryId, Matches Category: $matchesCategory");
      logger.i(
          "Payment Method: $paymentMethod, Matches Payment: $matchesPaymentMethod");
      logger.i("Date: $date, Matches Date Range: $matchesDate");

      return matchesCategory && matchesPaymentMethod && matchesDate;
    }).map((receipt) {
      // Map category details if available
      final category = _categoryProvider?.categories.firstWhere(
        (cat) => cat['id'] == receipt['categoryId'],
        orElse: () => {'name': 'Unknown', 'icon': '❓'},
      );

      return {
        ...receipt,
        'categoryName': category?['name'],
        'categoryIcon': category?['icon'],
      };
    }).toList();

    // Add sorting logic for Newest and Oldest
    filteredReceipts.sort((a, b) {
      final dateA = (a['date'] as Timestamp).toDate();
      final dateB = (b['date'] as Timestamp).toDate();
      final amountA = (a['amount'] as num?)?.toDouble() ?? 0.0;
      final amountB = (b['amount'] as num?)?.toDouble() ?? 0.0;

      if (_sortOption == 'Newest') {
        return dateB.compareTo(dateA); // Descending by date
      } else if (_sortOption == 'Oldest') {
        return dateA.compareTo(dateB); // Ascending by date
      } else if (_sortOption == 'Highest') {
        return amountB.compareTo(amountA); // Descending by amount
      } else if (_sortOption == 'Lowest') {
        return amountA.compareTo(amountB); // Ascending by amount
      }
      return 0; // Default: no sorting
    });

    // Log sorted receipts
    logger.i("Sorted Receipts (${filteredReceipts.length}):");
    for (var receipt in filteredReceipts) {
      logger.i(receipt);
    }

    return filteredReceipts;
  }

  // Group receipts by category
  void groupByCategory() {
    _groupedReceiptsByCategory = {};
    for (var receipt in _filteredReceipts) {
      final categoryId = receipt['categoryId'] ?? 'null';
      final amount = (receipt['amount'] as num?)?.toDouble() ?? 0.0;
      final categoryName = receipt['categoryName'];
      final categoryIcon = receipt['categoryIcon'];
      // If the categoryId already exists, update the amount
      if (_groupedReceiptsByCategory!.containsKey(categoryId)) {
        _groupedReceiptsByCategory![categoryId]!['total'] += amount;
      } else {
        // If the categoryId does not exist, initialize with name, icon, and amount
        _groupedReceiptsByCategory![categoryId] = {
          'total': amount,
          'name': categoryName,
          'icon': categoryIcon,
        };
      }
    }

    notifyListeners();
  }

  // Group receipts by date
  void groupByDate() {
    _groupedReceiptsByDate = {};
    for (var receipt in _filteredReceipts) {
      final date = (receipt['date'] as Timestamp?)?.toDate() ?? DateTime.now();
      final dateKey = "${date.year}-${date.month}-${date.day}";
      final amount = (receipt['amount'] as num?)?.toDouble() ?? 0.0;
      _groupedReceiptsByDate![dateKey] =
          (_groupedReceiptsByDate![dateKey] ?? 0.0) + amount;
    }
    notifyListeners();
  }

  // Group receipts by interval
  void groupByInterval(TimeInterval interval) {
    _groupedReceiptsByInterval = {};
    for (var receipt in _filteredReceipts) {
      final date = (receipt['date'] as Timestamp?)?.toDate() ?? DateTime.now();
      final amount = (receipt['amount'] as num?)?.toDouble() ?? 0.0;

      // Generate group key based on interval
      String groupKey;
      switch (interval) {
        case TimeInterval.day:
          groupKey = DateFormat('yyyy-MM-dd').format(date);
          break;
        case TimeInterval.week:
          groupKey = '${date.year}-W${getWeekNumber(date)}';
          break;
        case TimeInterval.month:
          groupKey = DateFormat('yyyy-MM').format(date);
          break;
        case TimeInterval.year:
          groupKey = DateFormat('yyyy').format(date);
          break;
      }

      // Add the amount to the appropriate group
      _groupedReceiptsByInterval![groupKey] =
          (_groupedReceiptsByInterval![groupKey] ?? 0.0) + amount;
    }

    notifyListeners();
  }

// Helper function to calculate the week number
  int getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil();
  }

  // Search receipts by query
  void searchReceipts(String query) {
    if (_allReceipts.isEmpty) return;

    if (query.isEmpty) {
      _filteredReceipts = List.from(_allReceipts);
    } else {
      final lowerCaseQuery = query.toLowerCase();
      print("Search query: $query");

      _filteredReceipts = _allReceipts.where((receipt) {
        print("Checking receipt: $receipt");
        final matches = receipt.entries.any((entry) {
          final value = entry.value?.toString().toLowerCase() ?? '';
          print(
              "Field: ${entry.key}, Value: $value, Matches: ${value.contains(lowerCaseQuery)}");
          return value.contains(lowerCaseQuery);
        });
        print("Receipt matches: $matches");
        return matches;
      }).toList();
    }

    print("Filtered Receipts: $_filteredReceipts");
    notifyListeners();
  }

  // Add receipt
  Future<void> addReceipt({required Map<String, dynamic> receiptData}) async {
    if (_userEmail != null) {
      await _receiptService.addReceipt(
          email: _userEmail!, receiptData: receiptData);
      notifyListeners();
    }
  }

  // Update receipt
  Future<void> updateReceipt({
    required String receiptId,
    required Map<String, dynamic> updatedData,
  }) async {
    if (_userEmail != null) {
      await _receiptService.updateReceipt(
        email: _userEmail!,
        receiptId: receiptId,
        updatedData: updatedData,
      );
      notifyListeners();
    }
  }

  // Delete receipt
  Future<void> deleteReceipt(String receiptId) async {
    if (_userEmail != null) {
      await _receiptService.deleteReceipt(_userEmail!, receiptId);
      notifyListeners();
    }
  }

  // Set receipts' category ID to null
  Future<void> setReceiptsCategoryToNull(String categoryId) async {
    if (_userEmail != null) {
      await _receiptService.setReceiptsCategoryToNull(_userEmail!, categoryId);
      notifyListeners();
    }
  }

  // Fetch receipt count
  Future<void> loadReceiptCount() async {
    if (_userEmail != null) {
      _receiptCount = _allReceipts.length;
      notifyListeners();
    }
  }

  // Get oldest and newest dates of receipts
  Future<void> loadOldestAndNewestDates() async {
    DateTime? oldestDate;
    DateTime? newestDate;

    for (var receipt in _allReceipts) {
      DateTime receiptDate = (receipt['date'] as Timestamp).toDate();

      // Check for the oldest date
      if (oldestDate == null || receiptDate.isBefore(oldestDate)) {
        oldestDate = receiptDate;
      }

      // Check for the newest date
      if (newestDate == null || receiptDate.isAfter(newestDate)) {
        newestDate = receiptDate;
      }
    }

    // Update the provider's state with the oldest and newest dates
    _oldestAndNewestDates = {
      'oldestDate': oldestDate ?? DateTime.now(),
      'newestDate': newestDate ?? DateTime.now(),
    };

    notifyListeners();
  }
}
