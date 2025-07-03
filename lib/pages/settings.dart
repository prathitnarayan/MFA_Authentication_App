import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final MobileScannerController _controller = MobileScannerController();
  final LocalAuthentication auth = LocalAuthentication();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  bool _isScanning = true;
  bool _isProcessing = false;
  bool _isPasskeyEnabled = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
    _checkPasskeyState();
  }

  Future<void> _requestCameraPermission() async {
    await Permission.camera.request();
  }

  Future<void> _checkPasskeyState() async {
    final value = await secureStorage.read(key: 'passkey_enabled');
    setState(() {
      _isPasskeyEnabled = value == 'true';
    });
  }

  Future<void> _togglePasskeyAccess() async {
    try {
      final isDeviceSupported = await auth.isDeviceSupported();
      if (!isDeviceSupported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Device security not supported")),
        );
        return;
      }

      final availableBiometrics = await auth.getAvailableBiometrics();
      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Authenticate to enable app access security',
        options: const AuthenticationOptions(
          biometricOnly: false, // Allows PIN/Pattern/Password fallback
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        setState(() => _isPasskeyEnabled = !_isPasskeyEnabled);
        await secureStorage.write(
          key: 'passkey_enabled',
          value: _isPasskeyEnabled.toString(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isPasskeyEnabled
                  ? "Passkey access enabled"
                  : "Passkey access disabled",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Authentication error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.blue[900],
      ),
      body: ListView(
        children: [
          // ListTile(
          //   leading: const Icon(Icons.privacy_tip),
          //   title: const Text('Privacy Screen'),
          //   trailing: const Icon(Icons.arrow_forward_ios),
          //   onTap: () {
          //     // Placeholder for future privacy screen toggle
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(content: Text("Privacy Screen tapped")),
          //     );
          //   },
          // ),
          ListTile(
            leading: Icon(
              _isPasskeyEnabled ? Icons.lock_open : Icons.lock_outline,
              color: _isPasskeyEnabled ? Colors.green : Colors.grey,
            ),
            title: Text(
              _isPasskeyEnabled
                  ? 'Disable Passkey Access'
                  : 'Enable Passkey Access',
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _togglePasskeyAccess,
          ),
        ],
      ),
    );
  }
}
