import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // removes unnecessary space
  }
}

// // Dummy OTPTile widget for now (replace with real implementation)
// class OTPTile extends StatelessWidget {
//   const OTPTile({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       child: ListTile(
//         leading: Icon(Icons.lock_outline),
//         title: Text('OTP Entry'),
//         subtitle: Text('Enter the code received via SMS.'),
//         trailing: Icon(Icons.arrow_forward_ios),
//       ),
//     );
//   }
// }
