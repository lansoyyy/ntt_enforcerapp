import 'package:enforcer_app/screens/auth/app_startup_gate.dart';
import 'package:enforcer_app/services/app_lock_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  AppLockController.instance.start();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppLockController.instance.navigatorKey,
      home: const AppStartupGate(),
    );
  }
}
