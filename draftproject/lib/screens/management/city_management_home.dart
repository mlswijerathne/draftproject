import 'package:flutter/material.dart';

class CityManagementHomeScreen extends StatelessWidget {
  const CityManagementHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('City Management Home'),
      ),
      body: Center(
        child: Text('Welcome, City Management!'),
      ),
    );
  }
}