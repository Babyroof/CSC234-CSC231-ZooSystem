import 'package:flutter/material.dart';
import 'package:zoopernova_zoo_system/core/widgets/zoo_bottom_nav.dart';

class TicketScreen extends StatelessWidget {
  const TicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: ZooBottomNav(currentIndex: 2),
    );
  }
}