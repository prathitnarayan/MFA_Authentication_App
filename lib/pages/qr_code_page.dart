import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_page.dart';

class QRCodePage extends StatefulWidget {
  const QRCodePage({super.key});

  @override
  State<QRCodePage> createState() => _QRCodePageState();
}

class _QRCodePageState extends State<QRCodePage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanning = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission is required to scan QR codes.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning || _isProcessing) return;

    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || !code.startsWith("otpauth://")) return;

    setState(() {
      _isProcessing = true;
      _isScanning = false;
    });

    _controller.stop();

    final parsed = _parseOTPAuthURI(code);
    if (parsed == null) {
      _showError("Invalid QR code format. Please try again.");
      _resetScanner();
      return;
    }

    // Show success message and navigate back with new account data
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Account "${parsed['issuer']}" added successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate back to HomePage with the new account data
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
    setState(() {
      _isProcessing = false;
      _isScanning = true;
    });
    _controller.start();
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
          IconButton(
            icon: Icon(_controller.torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
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
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
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
      ),
    );
  }
}