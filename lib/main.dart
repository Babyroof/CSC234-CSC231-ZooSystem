import 'package:flutter/material.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zoo System App',
      debugShowCheckedModeBanner: false,
      
      theme: AppTheme.lightTheme, 
      
      initialRoute: AppRoute.main, 
      routes: AppRoute.getRoutes(),
    );
  }
}