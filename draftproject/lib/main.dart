import 'package:draftproject/screens/management/city_management_home.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'package:flutter/material.dart';
import 'package:draftproject/screens/resident/home_screen.dart'; // Import HomeScreen
import 'package:draftproject/screens/auth/login_screen.dart'; // Import LoginScreen
import 'package:draftproject/screens/auth/register_screen.dart'; // Import RegisterScreen
import 'utils/theme.dart'; // Import AppTheme
import 'package:draftproject/screens/auth/loading_screen.dart';
import 'package:draftproject/screens/resident/resident_location.dart';
import 'package:draftproject/screens/driver/driver_home.dart';
import 'package:draftproject/screens/resident/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding is initialized
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waste Management',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/loading', // Set initial route to LoginScreen
      routes: {
        '/login': (context) => LoginScreen(), // Route for LoginScreen
        '/register': (context) => SignUpScreen(), // Route for RegisterScreen
        '/home': (context) => const HomeScreen(), // Route for HomeScreen
        '/loading':(context) => LoadingScreen(),
        '/resident_location' : (context) => ResidentLocation(),
        '/driver_home': (context) => DriverHomeScreen(),
        '/city_management_home': (context) => CityManagementHomeScreen(),
        '/resident_profile': (context) => ProfileScreen(),
        
      },
    );
  }
}