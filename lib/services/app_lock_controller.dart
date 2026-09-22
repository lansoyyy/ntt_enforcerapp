import 'dart:async';

import 'package:enforcer_app/screens/auth/biometric_lock_screen.dart';
import 'package:enforcer_app/services/biometric_service.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class AppLockController with WidgetsBindingObserver {
  AppLockController._();

  static final AppLockController instance = AppLockController._();

  /// Short app switches (permission dialogs, system UI) should not lock.
  static const Duration resumeGracePeriod = Duration(seconds: 5);

  /// Grace period between a camera/picker flow returning and the re-arming
  /// of the resume lock, so the resumed lifecycle event is ignored.
  static const Duration suppressionReleaseDelay = Duration(seconds: 2);

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  late final BiometricService _biometricService = BiometricService();

  DateTime? _backgroundedAt;
  bool _lockVisible = false;
  bool _suppressed = false;
  Timer? _suppressionTimer;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
  }

  void stop() {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _suppressionTimer?.cancel();
  }

  bool get hasSession {
    final token = GetStorage().read('token');
    return token != null && token.toString().isNotEmpty;
  }

  void setLockVisibility(bool visible) {
    _lockVisible = visible;
  }

  /// Prevents the next resume from showing the lock screen. Used while an
  /// external activity (e.g. the camera) is on top of the app.
  void suppressNextLock() {
    _suppressionTimer?.cancel();
    _suppressed = true;
  }

  /// Re-arms the resume lock after a short delay to swallow the lifecycle
  /// event emitted when the external activity closes.
  void releaseLockSuppression() {
    _suppressionTimer?.cancel();
    _suppressionTimer = Timer(suppressionReleaseDelay, () {
      _suppressed = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _maybeLockOnResume();
    }
  }

  Future<void> _maybeLockOnResume() async {
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;

    if (backgroundedAt == null || _suppressed || _lockVisible || !hasSession) {
      return;
    }

    if (DateTime.now().difference(backgroundedAt) < resumeGracePeriod) {
      return;
    }

    final status = await _biometricService.getStatus();
    if (!status.isAvailable || !hasSession) return;

    await showLock();
  }

  Future<void> showLock() async {
    final navigator = navigatorKey.currentState;
    if (navigator == null || _lockVisible) return;

    _lockVisible = true;
    try {
      await navigator.push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => BiometricLockScreen(
            asOverlay: true,
            onVisibilityChanged: setLockVisibility,
          ),
        ),
      );
    } finally {
      _lockVisible = false;
    }
  }
}
