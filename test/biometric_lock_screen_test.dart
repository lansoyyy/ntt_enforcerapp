import 'package:enforcer_app/screens/auth/biometric_lock_screen.dart';
import 'package:enforcer_app/services/biometric_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBiometricService extends BiometricService {
  _FakeBiometricService(this.results);

  final List<BiometricAuthResult> results;
  int calls = 0;

  @override
  Future<BiometricStatus> getStatus() async =>
      const BiometricStatus(BiometricSupport.available);

  @override
  Future<BiometricAuthResult> authenticate() async {
    final result = results[calls.clamp(0, results.length - 1)];
    calls++;
    return result;
  }
}

Future<void> _pumpLockScreen(
  WidgetTester tester,
  _FakeBiometricService service, {
  ValueChanged<bool>? onVisibilityChanged,
}) async {
  final navigatorKey = GlobalKey<NavigatorState>();

  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      home: const Scaffold(body: Center(child: Text('HOME SCREEN'))),
    ),
  );

  navigatorKey.currentState!.push(
    MaterialPageRoute(
      builder: (context) => BiometricLockScreen(
        asOverlay: true,
        biometricService: service,
        onVisibilityChanged: onVisibilityChanged,
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('auto-prompts once and unlocks when authentication succeeds',
      (tester) async {
    final service = _FakeBiometricService([BiometricAuthResult.success]);

    await _pumpLockScreen(tester, service);

    expect(service.calls, 1);
    expect(find.text('App Locked'), findsNothing);
    expect(find.text('HOME SCREEN'), findsOneWidget);
  });

  testWidgets('stays locked and shows the lockout message', (tester) async {
    final service = _FakeBiometricService([BiometricAuthResult.lockedOut]);

    await _pumpLockScreen(tester, service);

    expect(find.text('App Locked'), findsOneWidget);
    expect(find.textContaining('Too many failed attempts'), findsOneWidget);
    expect(find.text('HOME SCREEN'), findsNothing);
  });

  testWidgets('shows the cancelled message and unlocks on retry',
      (tester) async {
    final service = _FakeBiometricService([
      BiometricAuthResult.cancelled,
      BiometricAuthResult.success,
    ]);

    await _pumpLockScreen(tester, service);

    expect(find.textContaining('Authentication cancelled'), findsOneWidget);
    expect(find.text('App Locked'), findsOneWidget);

    await tester.tap(find.text('Authenticate'));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
    expect(find.text('HOME SCREEN'), findsOneWidget);
  });

  testWidgets('shows the not-recognized message on failure', (tester) async {
    final service = _FakeBiometricService([BiometricAuthResult.failed]);

    await _pumpLockScreen(tester, service);

    expect(find.textContaining('not recognized'), findsOneWidget);
    expect(find.text('App Locked'), findsOneWidget);
  });

  testWidgets('unlocks without prompting again when biometrics are gone',
      (tester) async {
    final service = _FakeBiometricService([BiometricAuthResult.unavailable]);

    await _pumpLockScreen(tester, service);

    expect(find.text('HOME SCREEN'), findsOneWidget);
  });

  testWidgets('reports lock visibility changes', (tester) async {
    final visibility = <bool>[];
    final service = _FakeBiometricService([BiometricAuthResult.success]);

    await _pumpLockScreen(
      tester,
      service,
      onVisibilityChanged: visibility.add,
    );

    expect(visibility.first, isTrue);
    expect(visibility.last, isFalse);
  });
}
