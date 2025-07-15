// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp/otp.dart';
import 'package:qr_code_auth/pages/qr_code_page.dart';
import 'package:qr_code_auth/pages/settings.dart';
import 'package:qr_code_auth/pages/auth_page.dart';
import 'package:qr_code_auth/services/otp_storage_service.dart'; // Add this import

class HomePage extends StatefulWidget {
  final String? secret;
  final String? issuer;
  final String? accountName;

  const HomePage({super.key, this.secret, this.issuer, this.accountName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _showTOTP = true;
  late Timer _timer;
  List<Map<String, dynamic>> otpAccounts = [];
  int secondsRemaining = 30;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAccounts();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTOTPs());
  }

  Future<void> _initializeAccounts() async {
    try {
      // Load existing accounts from storage
      otpAccounts = await OTPStorageService.loadAccounts();

      // If new account data is provided, add it
      if (widget.secret != null &&
          widget.issuer != null &&
          widget.accountName != null) {
        final newAccount = {
          'secret': widget.secret!,
          'issuer': widget.issuer!,
          'accountName': widget.accountName!,
          'otp': '',
        };

        final bool added = await OTPStorageService.addAccount(newAccount);
        if (added) {
          otpAccounts = await OTPStorageService.loadAccounts();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'New account "${widget.issuer}" added successfully!',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account "${widget.issuer}" already exists!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      _generateAllTOTPs();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing accounts: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading accounts. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleTOTPVisibility() {
    setState(() {
      _showTOTP = !_showTOTP;
    });
  }

  void _generateAllTOTPs() {
    final now = DateTime.now();
    setState(() {
      for (var account in otpAccounts) {
        account['otp'] = OTP.generateTOTPCodeString(
          account['secret'],
          now.millisecondsSinceEpoch,
          algorithm: Algorithm.SHA1,
          interval: 30,
          length: 6,
          isGoogle: true,
        );
      }
      secondsRemaining = 30 - (now.second % 30);
    });
  }

  void _updateTOTPs() {
    final now = DateTime.now();
    final newRemaining = 30 - (now.second % 30);
    if (newRemaining == 30) _generateAllTOTPs();
    setState(() => secondsRemaining = newRemaining);
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP copied to clipboard'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteAccount(int index) async {
    try {
      await OTPStorageService.removeAccount(index);
      otpAccounts = await OTPStorageService.loadAccounts();
      _generateAllTOTPs();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account removed'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing account'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Navigation logic
  void _navBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
      print("Current page index: $_selectedIndex");
    });
  }

  // Pages for each bottom nav item
  final List<Widget> _pages = [
    AuthPage(), // Actual Auth content page
  ];

  Widget _buildIndividualTimer(double progress) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          // Background circle
          Icon(Icons.access_time_outlined, size: 24, color: Colors.grey[400]),
          // Progress indicator
          Positioned.fill(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.3 ? Colors.blue[700]! : Colors.orange[600]!,
              ),
            ),
          ),
          // Moon icon overlay
          Icon(
            Icons.circle,
            size: 24,
            color: progress > 0.3 ? Colors.blue[700] : Colors.orange[600],
          ),
        ],
      ),
    );
  }

  Widget _buildOTPList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.blue[900]));
    }

    if (otpAccounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No accounts added yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the camera icon to scan a QR code',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Global timer display
          // Container(
          //   margin: const EdgeInsets.only(bottom: 20),
          //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //   decoration: BoxDecoration(
          //     color: Colors.blue[50],
          //     borderRadius: BorderRadius.circular(8),
          //     border: Border.all(color: Colors.blue[200]!),
          //   ),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       Icon(Icons.access_time, size: 16, color: Colors.blue[900]),
          //       SizedBox(width: 8),
          //       Text(
          //         'All codes refresh in $secondsRemaining seconds',
          //         style: TextStyle(
          //           fontSize: 16,
          //           fontWeight: FontWeight.w500,
          //           color: Colors.blue[900],
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // OTP List with individual timers
          ...otpAccounts.asMap().entries.map((entry) {
            final int index = entry.key;
            final Map<String, dynamic> account = entry.value;
            final double progress = secondsRemaining / 30.0;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.blue[100]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with issuer, timer, and actions
                  Row(
                    children: [
                      // Issuer icon and name
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.security,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account['issuer'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              account['accountName'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Individual timer with moon icon
                      Column(
                        children: [
                          _buildIndividualTimer(progress),
                          SizedBox(height: 4),
                          Text(
                            '${secondsRemaining}s',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: progress > 0.3
                                  ? Colors.blue[700]
                                  : Colors.orange[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 8),
                      // Action buttons
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                        onSelected: (value) {
                          switch (value) {
                            case 'copy':
                              _copyToClipboard(account['otp']);
                              break;
                            case 'delete':
                              _showDeleteConfirmation(index);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'copy',
                            child: Row(
                              children: [
                                Icon(Icons.copy, size: 18),
                                SizedBox(width: 8),
                                Text('Copy Code'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // OTP Code display
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _copyToClipboard(account['otp']),
                            child: Text(
                              _showTOTP
                                  ? _formatOTP(account['otp'])
                                  : '•••  •••',
                              style: const TextStyle(
                                fontSize: 28,
                                letterSpacing: 3.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.copy,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          onPressed: () => _copyToClipboard(account['otp']),
                          tooltip: 'Copy to clipboard',
                        ),
                      ],
                    ),
                  ),
                  // Progress bar for visual indication
                  SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress > 0.3 ? Colors.blue[600]! : Colors.orange[500]!,
                    ),
                    minHeight: 3,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  String _formatOTP(String otp) {
    if (otp.length == 6) {
      return '${otp.substring(0, 3)}  ${otp.substring(3, 6)}';
    }
    return otp;
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text(
            'Are you sure you want to delete this account? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount(index);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Authenticator",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue[900],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _generateAllTOTPs();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Codes refreshed'),
                  duration: Duration(seconds: 1),
                  backgroundColor: Colors.green,
                ),
              );
            },
            tooltip: 'Refresh all codes',
          ),
          IconButton(
            icon: Icon(Icons.add_a_photo_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QRCodePage()),
              );
            },
            tooltip: 'Add new account',
          ),
        ],
      ),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.80,
        child: Drawer(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  height: 120,
                  decoration: const BoxDecoration(color: Colors.blueAccent),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Authenticator',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      // Text(
                      //   '${otpAccounts.length} account${otpAccounts.length != 1 ? 's' : ''}',
                      //   style: TextStyle(color: Colors.white70, fontSize: 14),
                      // ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Home'),
                  onTap: () {
                    Navigator.pop(context);
                    _navBottomBar(0);
                  },
                ),
                ListTile(
                  leading: Icon(
                    _showTOTP ? Icons.visibility : Icons.visibility_off,
                  ),
                  title: Text(_showTOTP ? 'Hide Code' : 'Show Code'),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleTOTPVisibility();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.refresh_rounded),
                  title: const Text('Refresh Codes'),
                  onTap: () {
                    Navigator.pop(context);
                    _generateAllTOTPs();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_center),
                  title: const Text('Help'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: const Text('Send Feedback'),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(left: 25, right: 25, top: 25),
        child: Column(
          children: [
            Flexible(child: _pages[_selectedIndex]),
            Expanded(child: SingleChildScrollView(child: _buildOTPList())),
          ],
        ),
      ),
    );
  }
}
