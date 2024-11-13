import 'package:flutter/material.dart';
import 'package:receipt_manager/constants/app_colors.dart';

import 'custom_button.dart';

class LogoutPopup extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const LogoutPopup(
      {required this.onConfirm, required this.onCancel, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 20, vertical: 12), // Reduced vertical padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            thickness: 3,
            color: purple40,
            endIndent: 165,
            indent: 165,
          ),
          SizedBox(height: 8),
          Text(
            'Logout?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Are you sure do you wanna logout?',
            style: TextStyle(
              fontSize: 18,
              color: light20,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: CustomButton(
                      text: "No",
                      backgroundColor: purple20,
                      textColor: purple100,
                      onPressed: () {
                        Navigator.of(context).pop();
                      } // Close the popup},
                      ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: CustomButton(
                    text: "Yes",
                    backgroundColor: purple100,
                    textColor: light80,
                    onPressed: () {},
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
