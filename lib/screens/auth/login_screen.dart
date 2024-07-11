import 'package:enforcer_app/widgets/button_widget.dart';
import 'package:enforcer_app/widgets/textfield_widget.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
              const SizedBox(height: 10),
              TextFieldWidget(
                label: 'Username',
                isRequred: true,
                controller: username,
              ),
              const SizedBox(height: 10),
              TextFieldWidget(
                label: 'Password',
                isRequred: true,
                isObscure: true,
                controller: password,
              ),
              const SizedBox(height: 30),
              ButtonWidget(
                label: 'Login',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
