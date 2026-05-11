import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'package:zoopernova_zoo_system/core/routes/app_routes.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key, required this.activeIndex});

  /// 0 = Animals, 1 = Bookings, 2 = Events, 3 = Map, 4 = Zone
  final int activeIndex;

  static const _menuItems = [
    (Icons.pets_outlined, 'Animals', AppRoute.adminAnimals),
    (Icons.book_outlined, 'Bookings', AppRoute.adminBookings),
    (Icons.celebration_outlined, 'Events', AppRoute.adminEvents),
    (Icons.map_outlined, 'Map', AppRoute.adminMap),
    (Icons.location_on_outlined, 'Zone', AppRoute.adminZones),
  ];

  static Route<dynamic> _adminFadeRoute(String routeName) {
    final builder = AppRoute.getRoutes()[routeName]!;
    return PageRouteBuilder<dynamic>(
      settings: RouteSettings(name: routeName),
      pageBuilder: (ctx, _, __) => builder(ctx),
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
          child: child,
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoute.login, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: AppColors.adminSidebar,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wildcare Service',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Zoo Management',
            style: TextStyle(color: AppColors.adminSidebarText, fontSize: 13),
          ),
          const SizedBox(height: 40),
          ...List.generate(_menuItems.length, (index) {
            final item = _menuItems[index];
            final isActive = index == activeIndex;
            return _SidebarItem(
              icon: item.$1,
              label: item.$2,
              isActive: isActive,
              onTap: isActive
                  ? null
                  : () {
                      if (kIsWeb) {
                        Navigator.of(
                          context,
                        ).pushReplacement(_adminFadeRoute(item.$3));
                      } else {
                        Navigator.pushReplacementNamed(context, item.$3);
                      }
                    },
            );
          }),
          const Spacer(),
          _SidebarItem(
            icon: Icons.logout,
            label: 'Logout',
            isActive: false,
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive
        ? Colors.white
        : _hovered
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.adminSidebarMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 36),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 22, color: color),
                const SizedBox(width: 14),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: widget.isActive
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
