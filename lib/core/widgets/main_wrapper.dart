import 'package:flutter/material.dart';
import 'package:zoopernova_zoo_system/features/map/screens/map_screen.dart';
import 'package:zoopernova_zoo_system/features/profile/screens/profile_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/booking/screens/ticket_screen.dart';

class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({super.key});

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const MapScreen(),
    const TicketScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, 
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5), 
            )
          ]
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCustomNavItem(0, Icons.home_filled, 'Home'),
                _buildCustomNavItem(1, Icons.map_outlined, 'Map'),
                _buildCustomNavItem(2, Icons.confirmation_num_outlined, 'Tickets'),
                _buildCustomNavItem(3, Icons.person_outline, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), 
          margin: const EdgeInsets.symmetric(horizontal: 4), 
          padding: const EdgeInsets.symmetric(vertical: 14), 
          
          decoration: BoxDecoration(
            color: isSelected ? AppColors.menuSelected : Colors.transparent,
            borderRadius: BorderRadius.circular(24), 
          ),
          
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.navIcon : AppColors.navIcon, 
                size: 28,
              ),
              const SizedBox(height: 6), 
              Text(
                label,
                maxLines: 1, 
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? AppColors.navIcon : AppColors.navIcon, 
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14, 
                  fontFamily: 'Inter', 
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}