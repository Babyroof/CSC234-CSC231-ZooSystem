import 'package:flutter/material.dart';
import 'package:zoopernova_zoo_system/core/widgets/zoo_bottom_nav.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String userName = 'Jeffy Diddy';
  final String userEmail = 'abcd@gmail.com';
  final String userPhone = '099 xxx xxxx';
  final String lastPasswordUpdate = 'last update xx/xx/xxxx';

  void _handleLogOut() {
    // TODO: Implement logout functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: ZooBottomNav(currentIndex: 3),
    );
  }
}