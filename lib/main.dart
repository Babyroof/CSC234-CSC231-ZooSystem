import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:zoopernova_zoo_system/firebase_options.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ต้องมี await และ DefaultFirebaseOptions
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
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