import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:receipt_manager/screens/expense_chart_screen.dart';
import 'package:receipt_manager/screens/profile_screen.dart';
import 'package:receipt_manager/screens/welcome_screen.dart';

import '../screens/receipt_list_screen.dart';
import '../services/user_service.dart';

class CustomDrawer extends StatefulWidget {
  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final UserService _userService = UserService();
  String? userName;
  String? city;
  String? country;
  File? profileImage;

  @override
  void initState() {
    super.initState();
    _userService.getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userService.fetchUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error fetching user data');
        }

        if (snapshot.hasData && snapshot.data!.data() != null) {
          final userData = snapshot.data!.data();
          userName = userData?['userName'] ?? 'No Name';
          city = userData?['city'] ?? 'No City';
          country = userData?['country'] ?? 'No Country';
          final profileImagePath = userData?['profileImagePath'];
          if (profileImagePath != null) {
            profileImage = File(profileImagePath);
          }
        }

        return Drawer(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                UserAccountsDrawerHeader(
                  margin: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: Colors.lightBlueAccent,
                  ),
                  currentAccountPicture: Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: CircleAvatar(
                      radius: 50.0,
                      backgroundColor: Colors.white,
                      backgroundImage: profileImage != null
                          ? FileImage(profileImage!)
                          : null,
                      child: profileImage == null
                          ? Icon(
                              Icons.person,
                              size: 30.0,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                  accountName: Row(
                    children: [
                      Expanded(
                        child: Text(
                          userName ?? 'No Name',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  accountEmail: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$city, $country',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        _userService.loggedInUser?.email ?? 'No Email',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.home),
                  title: Text('Home'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.receipt),
                  title: Text('Receipts'),
                  onTap: () {
                    Navigator.pushNamed(context, ReceiptListScreen.id);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.bar_chart),
                  title: Text('Reports'),
                  onTap: () {
                    Navigator.pushNamed(context, ExpenseChartScreen.id);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profile'),
                  onTap: () {
                    Navigator.pushNamed(context, ProfileScreen.id);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                  onTap: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, WelcomeScreen.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
