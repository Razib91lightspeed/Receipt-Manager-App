import 'package:flutter/material.dart';
import 'package:receipt_manager/screens/login_screen.dart';

import '../components/custom_drawer.dart';
import '../components/rounded_button.dart'; // Import the RoundedButton widget
import '../services/user_service.dart';

class SettingScreen extends StatefulWidget {
  static const String id = 'setting_screen';

  const SettingScreen({super.key});

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Prevents closing the dialog by clicking outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear All History'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Are you sure you want to clear all history? This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _clearHistory(); // Proceed with clearing history
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearHistory() async {
    try {
      await _userService.clearAllHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All history cleared successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing history: $e')),
      );
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Prevents closing the dialog by clicking outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Are you sure you want to delete your account? This action cannot be undone and you will lose all your data.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _deleteAccount(); // Proceed with deleting account
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    try {
      await _userService.deleteUser();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account deleted successfully!')),
      );
      Navigator.pushReplacementNamed(context, LoginScreen.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Settings'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      drawer: CustomDrawer(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: RoundedButton(
                    color: Colors.orange,
                    title: 'Clear Receipt History',
                    onPressed: () {
                      _confirmClearHistory(context);
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: RoundedButton(
                    color: Colors.red,
                    title: 'Delete Account',
                    onPressed: () {
                      _confirmDeleteAccount(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
