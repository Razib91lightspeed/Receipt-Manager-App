import 'package:flutter/material.dart';

import '../services/budget_service.dart';
import 'authentication_provider.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetService _budgetService = BudgetService();
  AuthenticationProvider? _authProvider; // Reference to AuthenticationProvider

  List<Map<String, dynamic>> _budgets = [];
  Map<String, dynamic>? _budgetByCategory;

  List<Map<String, dynamic>> get budgets => _budgets;
  Map<String, dynamic>? get budgetByCategory => _budgetByCategory;

  // Setter for AuthenticationProvider
  set authProvider(AuthenticationProvider authProvider) {
    _authProvider = authProvider;
    notifyListeners();
  }

  // Helper to get user email from AuthenticationProvider
  String? get _userEmail => _authProvider?.user?.email;

  // Fetch all budgets for the current user
  Future<void> loadUserBudgets() async {
    if (_userEmail != null) {
      _budgets = await _budgetService.fetchUserBudgets(_userEmail!);
      notifyListeners();
    }
  }

  // Update budgets for the current user
  Future<void> updateUserBudgets(List<Map<String, dynamic>> budgetList) async {
    if (_userEmail != null) {
      await _budgetService.updateUserBudgets(_userEmail!, budgetList);
      await loadUserBudgets(); // Refresh after updating
    }
  }

  // Fetch budget by category ID for the current user
  Future<void> loadBudgetByCategoryId(String categoryId) async {
    if (_userEmail != null) {
      _budgetByCategory =
          await _budgetService.fetchBudgetByCategoryId(_userEmail!, categoryId);
      notifyListeners();
    }
  }
}
