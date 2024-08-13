import 'dart:convert';
import 'package:enforcer_app/widgets/toast_widget.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:enforcer_app/network/api_service.dart';
import 'package:enforcer_app/network/endpoints.dart';
import 'package:enforcer_app/screens/home_screen.dart';
import 'package:enforcer_app/widgets/button_widget.dart';
import 'package:enforcer_app/widgets/forgot_password_widget.dart';
import 'package:enforcer_app/widgets/text_widget.dart';
import 'package:enforcer_app/widgets/textfield_widget.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  final network = Network();

  final box = GetStorage();

  Future<void> login(String enforcerEmail, String enforcerPassword) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}auth/token');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({"email": enforcerEmail, "password": enforcerPassword}),
    );

    if (response.statusCode == 200) {
      box.write('token', jsonDecode(response.body)['token']);

      print(jsonDecode(response.body));

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) {
          return false;
        },
      );
    } else {
      showToast(jsonDecode(response.body)['message']);
    }
  }

  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Placeholder
                  const CircleAvatar(
                    radius: 100,
                    backgroundColor: Colors.transparent,
                    backgroundImage: AssetImage(
                      'assets/images/logo.png',
                    ), // Replace with your logo asset
                  ),

                  const Text(
                    'Welcome to Traffic Violation Ticketing System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFieldWidget(
                    hasValidator: false,
                    hint: 'Enter email',
                    borderColor: Colors.grey,
                    label: 'Email',
                    controller: email,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      TextFieldWidget(
                        hasValidator: false,
                        hint: 'Enter password',
                        showEye: true,
                        borderColor: Colors.grey,
                        label: 'Password',
                        isObscure: true,
                        controller: password,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters long';
                          }

                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: TextButton(
                          onPressed: () {
                            forgotpassword(context);
                          },
                          child: TextWidget(
                            text: 'Forgot password?',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ButtonWidget(
                    label: 'Login',
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        login(email.text, password.text);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
