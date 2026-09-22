import 'package:enforcer_app/screens/auth/biometric_lock_screen.dart';
import 'package:enforcer_app/screens/auth/login_screen.dart';
import 'package:enforcer_app/services/app_lock_controller.dart';
import 'package:enforcer_app/services/biometric_service.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key, this.biometricService});

  final BiometricService? biometricService;

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  late final BiometricService _biometricService =
      widget.biometricService ?? BiometricService();

  Widget? _destination;

  @override
  void initState() {
    super.initState();
    _resolveDestination();
  }

  Future<void> _resolveDestination() async {
    Widget destination = const LoginScreen();

    final token = GetStorage().read('token');
    if (token != null && token.toString().isNotEmpty) {
      final status = await _biometricService.getStatus();
      if (status.isAvailable) {
        destination = BiometricLockScreen(
          onVisibilityChanged: AppLockController.instance.setLockVisibility,
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _destination = destination;
    });
  }

  @override
  Widget build(BuildContext context) {
    final destination = _destination;

    if (destination == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 100,
                backgroundColor: Colors.transparent,
                backgroundImage: AssetImage('assets/images/logo.png'),
              ),
              SizedBox(height: 30),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return destination;
  }
}
