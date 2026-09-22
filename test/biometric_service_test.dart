import 'package:enforcer_app/services/biometric_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class _FakeLocalAuthentication extends LocalAuthentication {
  _FakeLocalAuthentication({
    this.supported = true,
    this.canCheck = true,
    this.biometrics = const <BiometricType>[],
    this.authenticateResult = false,
    this.statusError,
    this.authenticateError,
  });

  final bool supported;
  final bool canCheck;
  final List<BiometricType> biometrics;
  final bool authenticateResult;
  final Object? statusError;
  final Object? authenticateError;

  @override
  Future<bool> get canCheckBiometrics async {
    _throwStatusError();
    return canCheck;
  }

  @override
  Future<bool> isDeviceSupported() async {
    _throwStatusError();
    return supported;
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    _throwStatusError();
    return biometrics;
  }

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<AuthMessages> authMessages = const <AuthMessages>[],
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    final error = authenticateError;
    if (error != null) {
      throw error;
    }
    return authenticateResult;
  }

  void _throwStatusError() {
    final error = statusError;
    if (error != null) {
      throw error;
    }
  }
}

void main() {
  group('BiometricService.getStatus', () {
    test('returns unsupported when the plugin is missing', () async {
      final service = BiometricService(
        localAuthentication: _FakeLocalAuthentication(
          statusError: MissingPluginException('no plugin'),
        ),
      );

      final status = await service.getStatus();

      expect(status.support, BiometricSupport.unsupported);
      expect(status.isAvailable, isFalse);
    });

    test('returns unsupported when the device has no biometric support',
        () async {
      final service = BiometricService(
        localAuthentication: _FakeLocalAuthentication(supported: false),
      );

      final status = await service.getStatus();

      expect(status.support, BiometricSupport.unsupported);
    });

    test('returns unsupported when biometrics cannot be checked', () async {
      final service = BiometricService(
        localAuthentication: _FakeLocalAuthentication(canCheck: false),
      );

      final status = await service.getStatus();

      expect(status.support, BiometricSupport.unsupported);
    });

    test('returns notEnrolled when no biometrics are enrolled', () async {
      final service = BiometricService(
        localAuthentication: _FakeLocalAuthentication(),
      );

      final status = await service.getStatus();

      expect(status.support, BiometricSupport.notEnrolled);
      expect(status.isAvailable, isFalse);
    });

    test('returns available with the enrolled biometric types', () async {
      final service = BiometricService(
        localAuthentication: _FakeLocalAuthentication(
          biometrics: const <BiometricType>[BiometricType.face],
        ),
      );

      final status = await service.getStatus();

      expect(status.support, BiometricSupport.available);
      expect(status.isAvailable, isTrue);
      expect(status.hasFace, isTrue);
    });
  });

  group('BiometricService.authenticate', () {
    test('returns success when the device authenticates', () async {
      final service = BiometricService(
        localAuthentication:
            _FakeLocalAuthentication(authenticateResult: true),
      );

      expect(await service.authenticate(), BiometricAuthResult.success);
    });

    test('returns cancelled when the prompt is dismissed', () async {
      final service = BiometricService(
        localAuthentication:
            _FakeLocalAuthentication(authenticateResult: false),
      );

      expect(await service.authenticate(), BiometricAuthResult.cancelled);
    });

    test('maps lockout errors', () async {
      final service = BiometricService(
        localAuthentication: _FakeLocalAuthentication(
          authenticateError: PlatformException(code: 'LockedOut'),
        ),
      );

      expect(await service.authenticate(), BiometricAuthResult.lockedOut);
    });

    test('maps not enrolled errors to unavailable', () async {
      final service = BiometricService(
        localAuthentication: _FakeLocalAuthentication(
          authenticateError: PlatformException(code: 'NotEnrolled'),
        ),
      );

      expect(await service.authenticate(), BiometricAuthResult.unavailable);
    });

    test('maps missing plugin to unavailable', () async {
      final service = BiometricService(
        localAuthentication: _FakeLocalAuthentication(
          authenticateError: MissingPluginException('no plugin'),
        ),
      );

      expect(await service.authenticate(), BiometricAuthResult.unavailable);
    });
  });
}
