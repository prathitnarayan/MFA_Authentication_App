import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppLockWrapper extends StatefulWidget {
  final Widget child;

  const AppLockWrapper({super.key, required this.child});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper>
    with WidgetsBindingObserver {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final LocalAuthentication _auth = LocalAuthentication();

  bool _authenticated = false;
  bool _appLockEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLockStatus();
  }

  Future<void> _loadLockStatus() async {
    final status = await _storage.read(key: 'passkey_enabled');
    _appLockEnabled = status == 'true';
    if (_appLockEnabled) await _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate to continue',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (mounted) setState(() => _authenticated = authenticated);
    } on PlatformException catch (e) {
      print('Biometric error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_appLockEnabled) {
      if (state == AppLifecycleState.resumed) {
        _authenticate(); // lock triggered on resume
      } else if (state == AppLifecycleState.paused) {
        _authenticated = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_appLockEnabled && !_authenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.child;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
