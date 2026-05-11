import 'package:flutter/material.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'package:zoopernova_zoo_system/core/routes/app_routes.dart';
import 'package:zoopernova_zoo_system/features/admin/auth/services/admin_auth_service.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.adminPrimary,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.white,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.white),
            onPressed: () async {
              await AdminAuthService().logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoute.adminLogin);
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Admin Dashboard\n(Coming soon)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.black,
          ),
        ),
      ),
    );
  }
}
