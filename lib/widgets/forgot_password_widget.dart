import 'dart:convert';

import 'package:enforcer_app/network/endpoints.dart';
import 'package:enforcer_app/widgets/text_widget.dart';
import 'package:enforcer_app/widgets/textfield_widget.dart';
import 'package:enforcer_app/widgets/toast_widget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

forgotpassword(BuildContext context) {
  return showDialog(
    context: context,
    builder: ((context) {
      final formKey = GlobalKey<FormState>();
      final TextEditingController emailController = TextEditingController();

      return AlertDialog(
        backgroundColor: Colors.grey[300],
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFieldWidget(
                hint: 'Email',
                textCapitalization: TextCapitalization.none,
                inputType: TextInputType.emailAddress,
                label: 'Email',
                controller: emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email address';
                  }
                  final emailRegex =
                      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: (() {
              Navigator.pop(context);
            }),
            child: TextWidget(
              text: 'Cancel',
              fontSize: 12,
              color: Colors.black,
            ),
          ),
          TextButton(
            onPressed: (() async {
              if (formKey.currentState!.validate()) {
                try {
                  final url =
                      Uri.parse('${ApiEndpoints.baseUrl}forgot-password');

                  final response = await http.post(
                    url,
                    headers: {
                      'Content-Type': 'application/json',
                      'Accept': 'application/json',
                    },
                    body: jsonEncode({"email": emailController.text}),
                  );

                  showToast(jsonDecode(response.body)['message']);

                  Navigator.pop(context);
                } catch (e) {
                  String errorMessage = '';

                  showToast(errorMessage);
                  Navigator.pop(context);
                }
              }
            }),
            child: TextWidget(
              text: 'Continue',
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ],
      );
    }),
  );
}
