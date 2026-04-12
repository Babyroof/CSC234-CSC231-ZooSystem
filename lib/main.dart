import 'package:flutter/material.dart';
import 'package:zoopernova_zoo_system/core/theme/app_theme.dart';
import 'package:zoopernova_zoo_system/features/auth/screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zoopernova Zoo System',
      theme: AppTheme.lightTheme(),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
