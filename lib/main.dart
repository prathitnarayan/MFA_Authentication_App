import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qr_code_auth/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = FlutterSecureStorage();
  final value = await storage.read(key: 'passkey_enabled');
  final isPasskeyEnabled = value == 'true';

  if (!isPasskeyEnabled) {
    debugPrint('[AUTH] Passkey not enabled - skipping authentication');
  } else {
    debugPrint('[AUTH] Passkey feature is enabled');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MFA Authenticator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AnimatedSplashScreen(
        duration: 1500,
        splash: Image.asset('lib/assets/icons/Logo_qr_au.png', height: 250),
        splashIconSize: 250,
        backgroundColor: Colors.white,
        splashTransition: SplashTransition.fadeTransition,
        nextScreen: HomePage(),
      ),
    );
  }
}
