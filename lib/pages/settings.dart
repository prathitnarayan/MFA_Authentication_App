import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final LocalAuthentication auth = LocalAuthentication();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  bool _isPasskeyEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPasskeyState();
  }

  Future<void> _checkPasskeyState() async {
    try {
      final value = await secureStorage.read(key: 'passkey_enabled');
      print('Read value from storage: $value'); // Debug log
      setState(() {
        _isPasskeyEnabled = value == 'true';
        _isLoading = false;
      });
    } catch (e) {
      print('Error reading from secure storage: $e');
      setState(() {
        _isPasskeyEnabled = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePasskeyAccess() async {
    try {
      // Check if device supports biometrics
      final isDeviceSupported = await auth.isDeviceSupported();
      if (!isDeviceSupported) {
        _showSnackbar("Device does not support biometric authentication");
        return;
      }

      // Check available biometrics
      final availableBiometrics = await auth.getAvailableBiometrics();
      print('Available biometrics: $availableBiometrics'); // Debug log

      if (availableBiometrics.isEmpty) {
        _showSnackbar("No biometric authentication methods available");
        return;
      }

      // Check if biometrics can be used
      final canCheckBiometrics = await auth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        _showSnackbar("Biometric features unavailable on this device");
        return;
      }

      // Attempt authentication
      final didAuthenticate = await auth.authenticate(
        localizedReason: _isPasskeyEnabled
            ? 'Authenticate to disable app lock'
            : 'Authenticate to enable app lock',
        options: const AuthenticationOptions(
          biometricOnly: false, // Allow PIN/password fallback
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        final newState = !_isPasskeyEnabled;

        // Update storage first
        await secureStorage.write(
          key: 'passkey_enabled',
          value: newState.toString(),
        );

        // Verify the write operation
        final verifyValue = await secureStorage.read(key: 'passkey_enabled');
        print('Verification read: $verifyValue'); // Debug log

        // Update UI state
        setState(() {
          _isPasskeyEnabled = newState;
        });

        _showSnackbar(
          _isPasskeyEnabled ? "App lock enabled" : "App lock disabled",
        );
      } else {
        _showSnackbar("Authentication failed or cancelled");
      }
    } catch (e) {
      print('Authentication error: $e'); // Debug log
      _showSnackbar("Authentication error: ${e.toString()}");
    }
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    }
  }

  // Debug method to check storage
  Future<void> _debugStorage() async {
    try {
      final allKeys = await secureStorage.readAll();
      print('All storage keys: $allKeys');
    } catch (e) {
      print('Error reading all storage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.blue[900],
        actions: [
          // Debug button - remove in production
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _debugStorage,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  leading: Icon(
                    _isPasskeyEnabled ? Icons.lock : Icons.lock_open,
                    color: _isPasskeyEnabled ? Colors.green : Colors.grey,
                  ),
                  title: Text(
                    _isPasskeyEnabled ? 'Disable App Lock' : 'Enable App Lock',
                  ),
                  subtitle: Text(
                    _isPasskeyEnabled
                        ? 'App lock is currently enabled'
                        : 'App lock is currently disabled',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: _isPasskeyEnabled,
                        onChanged: (value) => _togglePasskeyAccess(),
                      ),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                  onTap: _togglePasskeyAccess,
                ),
                const Divider(),
                // Additional settings items can be added here
              ],
            ),
    );
  }
}
