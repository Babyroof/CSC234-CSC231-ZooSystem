import 'package:flutter/material.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'package:zoopernova_zoo_system/core/routes/app_routes.dart';

class ZooBottomNav extends StatelessWidget {
  final int currentIndex;

  const ZooBottomNav({
    super.key,
    required this.currentIndex,
  });

  void _handleTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    final routes = [
      AppRoute.home,
      AppRoute.map,
      AppRoute.ticket,
      AppRoute.profile,
    ];

    Navigator.pushReplacementNamed(context, routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              _NavItem(index: 0, icon: Icons.home_filled,
                  label: 'Home', currentIndex: currentIndex,
                  onTap: (i) => _handleTap(context, i)),
              _NavItem(index: 1, icon: Icons.map_outlined,
                  label: 'Map', currentIndex: currentIndex,
                  onTap: (i) => _handleTap(context, i)),
              _NavItem(index: 2, icon: Icons.confirmation_num_outlined,
                  label: 'Tickets', currentIndex: currentIndex,
                  onTap: (i) => _handleTap(context, i)),
              _NavItem(index: 3, icon: Icons.person_outline,
                  label: 'Profile', currentIndex: currentIndex,
                  onTap: (i) => _handleTap(context, i)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final int index;
  final IconData icon;
  final String label;
  final int currentIndex;
  final Function(int) onTap;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isPressed = false;

  bool get _isActive => widget.index == widget.currentIndex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap(widget.index),
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: (_isActive || _isPressed)
                ? AppColors.menuSelected
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: _isActive ? AppColors.navIcon : AppColors.navIcon,
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                maxLines: 1,
                style: TextStyle(
                  color: _isActive ? AppColors.navIcon : AppColors.navIcon,
                  fontWeight:
                      _isActive ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 12,
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