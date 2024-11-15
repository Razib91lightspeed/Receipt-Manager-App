import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../logger.dart';
import '../services/receipt_service.dart';
import 'authentication_provider.dart';
import 'category_provider.dart';

class ReceiptProvider extends ChangeNotifier {
  final ReceiptService _receiptService = ReceiptService();
  AuthenticationProvider? _authProvider;
  CategoryProvider? _categoryProvider;

  DocumentSnapshot<Map<String, dynamic>>? _receiptsSnapshot;
  Map<String, double>? _groupedReceiptsByCategory;
  Map<String, double>? _groupedReceiptsByInterval;
  Map<String, DateTime>? _oldestAndNewestDates;
  List<Map<String, dynamic>> _filteredReceipts = []; // Filtered list of receipts
  List<Map<String, dynamic>> get allReceipts => _allReceipts;
  List<Map<String, dynamic>> get filteredReceipts => _filteredReceipts; // Getter for filtered receipts
  // Stores all fetched receipts for search and filtering
  List<Map<String, dynamic>> _allReceipts = [];
  int? _receiptCount;

  DocumentSnapshot<Map<String, dynamic>>? get receiptsSnapshot =>
      _receiptsSnapshot;
  Map<String, double>? get groupedReceiptsByCategory =>
      _groupedReceiptsByCategory;
  Map<String, double>? get groupedReceiptsByInterval =>
      _groupedReceiptsByInterval;
  Map<String, DateTime>? get oldestAndNewestDates => _oldestAndNewestDates;
  int? get receiptCount => _receiptCount;

  // Inject AuthenticationProvider and CategoryProvider
  set authProvider(AuthenticationProvider authProvider) {
    _authProvider = authProvider;
    notifyListeners();
  }

  set categoryProvider(CategoryProvider categoryProvider) {
    _categoryProvider = categoryProvider;
    // Set default selected categories to include all category IDs
    _selectedCategoryIds = _categoryProvider!.categories
        .map((cat) => cat['id'] as String)
        .toList();
    _selectedCategoryIds.add('null');
    notifyListeners();
  }

  // Helper to get user email from AuthenticationProvider
  String? get _userEmail => _authProvider?.user?.email;

  List<String> _selectedPaymentMethods = [
    'Credit Card',
    'Debit Card',
    'Cash',
    'Other'
  ];
  String _sortOrder = 'Newest';
  List<String> _selectedCategoryIds = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to update filters
  void updateFilters({
    required List<String> paymentMethods,
    required String sortOrder,
    required List<String> categoryIds,
  }) {
    _selectedPaymentMethods = paymentMethods;
    _sortOrder = sortOrder;
    _selectedCategoryIds = categoryIds;
    notifyListeners(); // Notify to rebuild with updated filters
  }

  // Method to filter receipts based on the search query
  void searchReceipts(String query) {
    if (_receiptsSnapshot == null) return; // Exit if there is no data yet

    final allReceipts = (_receiptsSnapshot!.data()?['receiptlist'] ?? [])
        .cast<Map<String, dynamic>>();

    // If the query is empty, reset to show all receipts
    if (query.isEmpty) {
      _filteredReceipts = List.from(allReceipts);
    } else {
      _filteredReceipts = allReceipts.where((receipt) {
        final merchant = receipt['merchantName']?.toLowerCase() ?? '';
        final itemName = receipt['itemName']?.toLowerCase() ?? '';
        final description = receipt['description']?.toLowerCase() ?? '';
        final amount = receipt['amount']?.toString() ?? '';

        // Check if any field contains the query (case-insensitive)
        return merchant.contains(query.toLowerCase()) ||
            itemName.contains(query.toLowerCase()) ||
            description.contains(query.toLowerCase()) ||
            amount.contains(query);
      }).toList();
    }

    notifyListeners(); // Notify consumers of changes
  }


  Stream<List<Map<String, dynamic>>> fetchReceipts() async* {
    try {
      logger.i("Fetching receipts for user: $_userEmail");
      final userDoc = _firestore.collection('receipts').doc(_userEmail);

      await for (var snapshot in userDoc.snapshots()) {
        if (snapshot.data() == null) {
          logger.i("No receipt data found for user: $_userEmail");
          yield [];
          continue;
        }
        _allReceipts = (snapshot.data()?['receiptlist'] ?? [])
            .cast<Map<String, dynamic>>();
        yield _allReceipts;


        List<Map<String, dynamic>> allReceipts =
            (snapshot.data()?['receiptlist'] ?? [])
                .cast<Map<String, dynamic>>();
        logger.i("Total receipts fetched: ${allReceipts.length}");

        // Get categories from CategoryProvider to map category details
        final categories = _categoryProvider?.categories ?? [];

        // Apply category and payment method filters with default values
        List<Map<String, dynamic>> filteredReceipts =
            allReceipts.where((receipt) {
          // Set default values for categoryId and paymentMethod if they are missing
          String categoryId = receipt['categoryId'] ?? 'null';
          String paymentMethod = receipt['paymentMethod'] ?? '';

          bool matchesCategory = false;
          bool matchesPayment = false;

          print("Category ID: $categoryId");
          print("Selected Category IDs: $_selectedCategoryIds");
          if (_selectedCategoryIds.contains(categoryId)) {
            matchesCategory = true;
          } else {
            print(
                "Category ID $categoryId does not match any in $_selectedCategoryIds");
          }

          print("Payment Method: $paymentMethod");
          print("Selected Payment Methods: $_selectedPaymentMethods");
          if (_selectedPaymentMethods.isEmpty ||
              _selectedPaymentMethods.contains(paymentMethod)) {
            matchesPayment = true;
          } else {
            print(
                "Payment Method $paymentMethod does not match any in $_selectedPaymentMethods");
          }

          // Log the filtering result for debugging
          if (!matchesCategory) {
            logger.i("Receipt filtered out by category: $categoryId");
          }
          if (!matchesPayment) {
            logger.i("Receipt filtered out by payment method: $paymentMethod");
          }

          return matchesCategory && matchesPayment;
        }).map((receipt) {
          // Add categoryName and categoryIcon to each receipt based on categoryId
          final category = categories.firstWhere(
            (cat) => cat['id'] == receipt['categoryId'],
            orElse: () => {'name': 'Unknown', 'icon': '❓'},
          );

          return {
            ...receipt,
            'categoryName': category['name'],
            'categoryIcon': category['icon'],
          };
        }).toList();

        logger.i("Receipts after filtering: ${filteredReceipts.length}");

        // Apply sorting based on amount or date
        try {
          filteredReceipts.sort((a, b) {
            int result;
            if (_sortOrder == 'Highest' || _sortOrder == 'Lowest') {
              result = (b['amount'] as double).compareTo(a['amount'] as double);
              if (_sortOrder == 'Lowest') result = -result;
            } else {
              DateTime dateA = (a['date'] as Timestamp).toDate();
              DateTime dateB = (b['date'] as Timestamp).toDate();
              result = dateB.compareTo(dateA);
              if (_sortOrder == 'Oldest') result = -result;
            }
            return result;
          });
        } catch (e) {
          logger.e("Error while sorting receipts: $e");
        }

        logger.i("Yielding ${filteredReceipts.length} sorted receipts.");
        yield filteredReceipts;
      }
    } catch (e) {
      logger.e("Error fetching receipts: $e");
      yield [];
    }
  }

  // Fetch receipt count
  Future<void> loadReceiptCount() async {
    if (_userEmail != null) {
      _receiptCount = await _receiptService.getReceiptCount(_userEmail!);
      notifyListeners();
    }
  }

  // Add a new receipt with category details
  Future<void> addReceipt({required Map<String, dynamic> receiptData}) async {
    if (_userEmail != null) {
      await _receiptService.addReceipt(
          email: _userEmail!, receiptData: receiptData);
      await loadReceiptCount();
    }
  }

  // Update an existing receipt
  Future<void> updateReceipt({
    required String receiptId,
    required Map<String, dynamic> updatedData,
    String? paymentMethod,
  }) async {
    if (_userEmail != null) {
      await _receiptService.updateReceipt(
        email: _userEmail!,
        receiptId: receiptId,
        updatedData: updatedData,
        paymentMethod: paymentMethod,
      );
      await loadReceiptCount();
    }
  }

  // Delete a receipt
  Future<void> deleteReceipt(String receiptId) async {
    if (_userEmail != null) {
      await _receiptService.deleteReceipt(_userEmail!, receiptId);
      await loadReceiptCount();
    }
  }

  // Set category ID to null for receipts with a specific category ID
  Future<void> setReceiptsCategoryToNull(String categoryId) async {
    if (_userEmail != null) {
      await _receiptService.setReceiptsCategoryToNull(_userEmail!, categoryId);
      notifyListeners();
    }
  }

  // Group receipts by category within a date range, including category details
  Future<void> groupReceiptsByCategory(
      DateTime startDate, DateTime endDate) async {
    if (_userEmail != null) {
      _groupedReceiptsByCategory =
          await _receiptService.groupReceiptsByCategory(
        _userEmail!,
        startDate,
        endDate,
      );

      // Map category details (name and icon) to the grouped result
      _groupedReceiptsByCategory =
          _groupedReceiptsByCategory?.map((key, value) {
        final category = _categoryProvider?.categories.firstWhere(
          (cat) => cat['id'] == key,
          orElse: () => {'name': 'Unknown', 'icon': '❓'},
        );
        return MapEntry(
          '${category?['name']} ${category?['icon']}',
          value,
        );
      });

      notifyListeners();
    }
  }

  // Group receipts by interval within a date range
  Future<void> groupReceiptsByInterval(
    TimeInterval interval,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (_userEmail != null) {
      _groupedReceiptsByInterval =
          await _receiptService.groupReceiptsByInterval(
        _userEmail!,
        interval,
        startDate,
        endDate,
      );
      notifyListeners();
    }
  }

  Future<void> fetchDailyGroupedReceipts(
      DateTime startDate, DateTime endDate) async {
    if (_userEmail != null) {
      await groupReceiptsByInterval(TimeInterval.day, startDate, endDate);
    }
  }

  // Get oldest and newest dates of receipts
  Future<void> loadOldestAndNewestDates() async {
    if (_userEmail != null) {
      _oldestAndNewestDates =
          await _receiptService.getOldestAndNewestDates(_userEmail!);
      notifyListeners();
    }
  }
}
