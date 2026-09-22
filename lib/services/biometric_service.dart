import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

enum BiometricSupport { available, notEnrolled, unsupported }

enum BiometricAuthResult {
  success,
  failed,
  cancelled,
  lockedOut,
  unavailable,
}

class BiometricStatus {
  const BiometricStatus(this.support, {this.biometrics = const []});

  final BiometricSupport support;
  final List<BiometricType> biometrics;

  bool get isAvailable => support == BiometricSupport.available;

  bool get hasFace => biometrics.contains(BiometricType.face);

  bool get hasFingerprint => biometrics.contains(BiometricType.fingerprint);
}

class BiometricService {
  BiometricService({LocalAuthentication? localAuthentication})
      : _localAuthentication =
            localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  Future<BiometricStatus> getStatus() async {
    try {
      final isSupported = await _localAuthentication.isDeviceSupported();
      if (!isSupported) {
        return const BiometricStatus(BiometricSupport.unsupported);
      }

      final canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
      if (!canCheckBiometrics) {
        return const BiometricStatus(BiometricSupport.unsupported);
      }

      final biometrics = await _localAuthentication.getAvailableBiometrics();
      if (biometrics.isEmpty) {
        return const BiometricStatus(BiometricSupport.notEnrolled);
      }

      return BiometricStatus(BiometricSupport.available, biometrics: biometrics);
    } on MissingPluginException {
      return const BiometricStatus(BiometricSupport.unsupported);
    } on PlatformException {
      return const BiometricStatus(BiometricSupport.unsupported);
    }
  }

  Future<BiometricAuthResult> authenticate() async {
    try {
      final didAuthenticate = await _localAuthentication.authenticate(
        localizedReason: 'Authenticate to access the enforcer app',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Biometric authentication required',
            cancelButton: 'Cancel',
          ),
          IOSAuthMessages(cancelButton: 'Cancel'),
        ],
      );

      return didAuthenticate
          ? BiometricAuthResult.success
          : BiometricAuthResult.cancelled;
    } on PlatformException catch (error) {
      switch (error.code) {
        case 'NotAvailable':
        case 'NotEnrolled':
        case 'passcode_not_set':
          return BiometricAuthResult.unavailable;
        case 'LockedOut':
        case 'PermanentlyLockedOut':
          return BiometricAuthResult.lockedOut;
        default:
          return BiometricAuthResult.failed;
      }
    } on MissingPluginException {
      return BiometricAuthResult.unavailable;
    }
  }
}
