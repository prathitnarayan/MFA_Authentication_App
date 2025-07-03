// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:qr_code_auth/pages/qr_code_page.dart';
import 'package:qr_code_auth/pages/login_page.dart';
import 'package:qr_code_auth/pages/auth_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[700],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Jio Authenticator",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue[900],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        // actions: [
        //   IconButton(
        //     onPressed: () {},
        //     icon: const Icon(Icons.logout, color: Colors.white),
        //   ),
        // ],
      ),
      body: Center(
        child: Container(
          height: 400,
          width: 350,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.blue[400],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Login",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const TextField(
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Username",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(height: 15),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QRCodePage()),
                  );
                },
                child: const Text("Login"),
              ),
              // const SizedBox(height: 12),
              // TextButton(
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => const AuthPage()),
              //     );
              //   },
              //   child: const Text(
              //     "New User? Register Here",
              //     style: TextStyle(color: Colors.white),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
