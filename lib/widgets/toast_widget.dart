import 'package:flutter/material.dart';

void showToast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
