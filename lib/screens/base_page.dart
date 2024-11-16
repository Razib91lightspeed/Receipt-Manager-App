import 'package:flutter/material.dart';
import 'package:receipt_manager/screens/report_page.dart';
import 'package:receipt_manager/screens/settings_page.dart';

import '../components/custom_bottom_nav_bar.dart';
import 'home_page.dart';
import 'receipt_list_page.dart';

class BasePage extends StatefulWidget {
  static const String id = 'base_page';
  const BasePage({super.key});

  @override
  BasePageState createState() => BasePageState();
}

class BasePageState extends State<BasePage> {
  int _selectedIndex = 1; // Default to the "Transaction" tab

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return HomePage();
      case 1:
        return ReceiptListPage();
      case 2:
        return ReportPage();
      case 3:
        return SettingsPage();
      default:
        return ReceiptListPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getSelectedPage(),
      bottomNavigationBar: CustomBottomNavBar(
        initialIndex: _selectedIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
