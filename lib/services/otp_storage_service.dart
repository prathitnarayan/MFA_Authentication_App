import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OTPStorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _accountsKey = 'otp_accounts';

  // Save all accounts to secure storage
  static Future<void> saveAccounts(List<Map<String, dynamic>> accounts) async {
    // Remove the 'otp' field before saving as it's generated dynamically
    final accountsToSave = accounts.map((account) {
      final Map<String, dynamic> accountCopy = Map.from(account);
      accountCopy.remove('otp'); // Don't save the generated OTP
      return accountCopy;
    }).toList();

    final String jsonString = jsonEncode(accountsToSave);
    await _secureStorage.write(key: _accountsKey, value: jsonString);
  }

  // Load all accounts from secure storage
  static Future<List<Map<String, dynamic>>> loadAccounts() async {
    try {
      final String? jsonString = await _secureStorage.read(key: _accountsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((item) {
        final Map<String, dynamic> account = Map<String, dynamic>.from(item);
        account['otp'] = ''; // Initialize OTP field
        return account;
      }).toList();
    } catch (e) {
      print('Error loading accounts: $e');
      return [];
    }
  }

  // Add a new account
  static Future<bool> addAccount(Map<String, dynamic> newAccount) async {
    final List<Map<String, dynamic>> accounts = await loadAccounts();
    
    // Check if account already exists (based on secret and issuer and account name)
    final bool exists = accounts.any((account) => 
        account['secret'] == newAccount['secret'] && 
        account['issuer'] == newAccount['issuer'] &&
        account['accountName'] == newAccount['accountName']);
    
    if (!exists) {
      accounts.add(newAccount);
      await saveAccounts(accounts);
      return true; // Successfully added
    }
    return false; // Already exists
  }

  // Get account count
  static Future<int> getAccountCount() async {
    final accounts = await loadAccounts();
    return accounts.length;
  }

  // Check if a specific account exists
  static Future<bool> accountExists(String secret, String issuer, String accountName) async {
    final accounts = await loadAccounts();
    return accounts.any((account) => 
        account['secret'] == secret && 
        account['issuer'] == issuer &&
        account['accountName'] == accountName);
  }

  // Remove an account
  static Future<void> removeAccount(int index) async {
    final List<Map<String, dynamic>> accounts = await loadAccounts();
    if (index >= 0 && index < accounts.length) {
      accounts.removeAt(index);
      await saveAccounts(accounts);
    }
  }

  // Clear all accounts (useful for logout or reset)
  static Future<void> clearAllAccounts() async {
    await _secureStorage.delete(key: _accountsKey);
  }

  // Check if any accounts exist
  static Future<bool> hasAccounts() async {
    final accounts = await loadAccounts();
    return accounts.isNotEmpty;
  }
}