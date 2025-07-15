import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_page.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class QRCodePage extends StatefulWidget {
  const QRCodePage({super.key});

  @override
  State<QRCodePage> createState() => _QRCodePageState();
}

class _QRCodePageState extends State<QRCodePage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanning = true;
  bool _isProcessing = false;
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    // Check current permission status first
    PermissionStatus status = await Permission.camera.request();
    print('Initial camera permission status: $status');

    if (!status.isGranted) {
      status = await Permission.camera.request();
      print('After request - camera permission status: $status');
    }

    if (status.isGranted) {
      setState(() {
        _isPermissionGranted = true;
      });
    } else if (status.isPermanentlyDenied) {
      // Show dialog to open app settings
      _showPermissionDialog();
    } else {
      // Handle denied, restricted, limited, or any other non-granted status
      print('Camera permission not granted. Status: $status');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Camera permission is required to scan QR codes. Status: $status',
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Try Again',
              textColor: Colors.white,
              onPressed: _requestCameraPermission,
            ),
          ),
        );
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'Please enable camera permission in app settings to use QR scanner.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>?> _processSecureQRCode(String encryptedQR) async {
    const AES_KEY = '12345678901234567890123456789012';
    const HMAC_KEY = 'my_secure_hmac_key';

    try {
      final key = encrypt.Key.fromUtf8(AES_KEY);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.ecb, padding: 'PKCS7'),
      );
      final encryptedBytes = encrypt.Encrypted.fromBase64(encryptedQR);
      final decrypted = encrypter.decrypt(encryptedBytes);

      print('Decrypted Payload: $decrypted');

      // Step 2: Format check
      final parts = decrypted.split('|');
      if (parts.length != 3) {
        throw FormatException(
          'Decrypted string is malformed: ${parts.length} parts found',
        );
      }

      final userId = parts[0];
      final secret = parts[1];
      final mac = parts[2];
      final payload = '$userId|$secret';

      final hmacSha256 = Hmac(sha256, utf8.encode(HMAC_KEY));
      final digest = hmacSha256.convert(utf8.encode(payload));
      final expectedMac = base64.encode(digest.bytes);

      if (expectedMac != mac) {
        throw Exception('Invalid MAC. Tampering detected.');
      }

      return {'secret': secret, 'issuer': 'SecureMFA', 'accountName': userId};
    } catch (e) {
      print('Failed to process QR: $e');
      return null;
    }
  }

  String _decrypt(String encryptedBase64, String keyStr) {
    final key = encrypt.Key.fromUtf8(keyStr);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.ecb),
    );
    final encrypted = encrypt.Encrypted.fromBase64(encryptedBase64);
    return encrypter.decrypt(encrypted);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!_isScanning || _isProcessing) return;

    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;

    setState(() {
      _isProcessing = true;
      _isScanning = false;
    });

    _controller.stop();

    try {
      // Case 1: Standard OTP QR
      if (code.startsWith("otpauth://")) {
        final parsed = _parseOTPAuthURI(code);
        if (parsed == null) {
          _showError("Invalid QR code format. Please try again.");
          _resetScanner();
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(
              secret: parsed['secret']!,
              issuer: parsed['issuer']!,
              accountName: parsed['accountName']!,
            ),
          ),
        );
        return;
      }

      // Case 2: Custom Secure QR
      final secureData = await _processSecureQRCode(code);
      if (secureData != null) {
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(
              secret: secureData['secret']!,
              issuer: secureData['issuer']!,
              accountName: secureData['accountName']!,
            ),
          ),
        );
        return;
      }

      _showError("Unsupported or tampered QR code.");
      _resetScanner();
    } catch (e) {
      _showError("Unsupported or invalid QR format.");
      _resetScanner();
    }
  }

  Map<String, String>? _parseOTPAuthURI(String uri) {
    try {
      final parsedUri = Uri.parse(uri);

      // Extract secret
      final secret = parsedUri.queryParameters['secret'];
      if (secret == null || secret.isEmpty) return null;

      // Extract account name and issuer
      final path = parsedUri.path.replaceFirst("/", "");
      String accountName = path;
      String issuer = parsedUri.queryParameters['issuer'] ?? 'Unknown';

      // Handle format: otpauth://totp/Issuer:account@example.com
      if (path.contains(":")) {
        final parts = path.split(":");
        if (parts.length >= 2) {
          issuer = parts[0];
          accountName = parts.sublist(1).join(":");
        }
      }

      // If issuer is still 'Unknown' but we have a colon-separated format, use the first part
      if (issuer == 'Unknown' && path.contains(":")) {
        issuer = path.split(":")[0];
      }

      return {
        'secret': secret.replaceAll(' ', '').toUpperCase(),
        'issuer': issuer,
        'accountName': accountName,
      };
    } catch (e) {
      print('Error parsing OTP URI: $e');
      return null;
    }
  }

  void _resetScanner() {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _isScanning = true;
    });
    _controller.start();
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _resetScanner,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          if (_isPermissionGranted)
            IconButton(
              icon: Icon(
                _controller.torchEnabled ? Icons.flash_on : Icons.flash_off,
              ),
              onPressed: () => _controller.toggleTorch(),
            ),
        ],
      ),
      body: _isPermissionGranted
          ? Stack(
              children: [
                MobileScanner(controller: _controller, onDetect: _onDetect),
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          const Text(
                            'Processing QR Code...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Scanner overlay
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // Instructions
                Positioned(
                  bottom: 100,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Position the QR code within the frame to scan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Camera permission required',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _requestCameraPermission,
                    child: const Text('Grant Permission'),
                  ),
                ],
              ),
            ),
    );
  }
}
