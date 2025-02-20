import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService auth = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              // Navigate to login screen and remove all previous routes
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login', // Replace with your login route name
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/driver_tracking');
          },
          child: const Text('Start Tracking'),
        ),
      ),
    );
  }
}