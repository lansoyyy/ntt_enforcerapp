import 'package:enforcer_app/screens/home_screen.dart';
import 'package:enforcer_app/services/biometric_service.dart';
import 'package:enforcer_app/widgets/button_widget.dart';
import 'package:enforcer_app/widgets/text_widget.dart';
import 'package:flutter/material.dart';

class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({
    super.key,
    this.asOverlay = false,
    this.biometricService,
    this.onVisibilityChanged,
  });

  /// When true the screen was pushed on top of an existing session and pops
  /// itself on success. When false it is the initial screen and replaces
  /// itself with the home screen on success.
  final bool asOverlay;

  final BiometricService? biometricService;

  final ValueChanged<bool>? onVisibilityChanged;

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  late final BiometricService _biometricService =
      widget.biometricService ?? BiometricService();

  BiometricStatus? _status;
  String? _message;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    widget.onVisibilityChanged?.call(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatus();
      _authenticate();
    });
  }

  @override
  void dispose() {
    widget.onVisibilityChanged?.call(false);
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final status = await _biometricService.getStatus();
    if (!mounted) return;
    setState(() {
      _status = status;
    });
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;

    setState(() {
      _authenticating = true;
      _message = null;
    });

    final result = await _biometricService.authenticate();
    if (!mounted) return;

    switch (result) {
      case BiometricAuthResult.success:
        _unlock();
      case BiometricAuthResult.unavailable:
        // Biometrics were removed or disabled while locked. The requirement
        // is to skip the feature on devices that no longer support it.
        _unlock();
      case BiometricAuthResult.lockedOut:
        setState(() {
          _authenticating = false;
          _message = 'Too many failed attempts. Try again in 30 seconds.';
        });
      case BiometricAuthResult.cancelled:
        setState(() {
          _authenticating = false;
          _message = 'Authentication cancelled.';
        });
      case BiometricAuthResult.failed:
        setState(() {
          _authenticating = false;
          _message = 'Biometric not recognized. Please try again.';
        });
    }
  }

  void _unlock() {
    if (!mounted) return;

    if (widget.asOverlay) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) {
        return false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final icon = _status?.hasFace == true ? Icons.face : Icons.fingerprint;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 100,
                  backgroundColor: Colors.transparent,
                  backgroundImage: AssetImage('assets/images/logo.png'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'App Locked',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Verify your identity to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                Icon(
                  icon,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 40,
                  child: Center(
                    child: _message == null
                        ? const SizedBox.shrink()
                        : TextWidget(
                            text: _message!,
                            fontSize: 14,
                            color: Colors.red,
                            maxLines: 3,
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                ButtonWidget(
                  label: _authenticating ? 'Waiting...' : 'Authenticate',
                  onPressed: _authenticating ? () {} : _authenticate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
