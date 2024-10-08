import 'package:flutter/material.dart';

const kTextFieldDecorationBase = InputDecoration(
  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.lightBlueAccent, width: 1.0),
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
);

// Function to apply dynamic parts of the InputDecoration
InputDecoration kTextFieldDecoration({String? hintText, Widget? suffixIcon}) {
  return kTextFieldDecorationBase.copyWith(
    hintText: hintText,
    suffixIcon: suffixIcon,
  );
}
