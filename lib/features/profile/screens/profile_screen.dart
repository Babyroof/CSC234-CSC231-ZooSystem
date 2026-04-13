import 'package:flutter/material.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';

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
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                children: [
                  // Top bar with title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.black,
                      border: Border.all(
                        color: AppColors.black,
                        width: 4,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // User Name with edit icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          // TODO: Implement edit name functionality
                        },
                        child: const Icon(
                          Icons.edit,
                          size: 20,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Profile Information Section
            Container(
              color: AppColors.white,
              margin: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  // Email Section
                  _buildProfileItem(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    subtitle: userEmail,
                    showActionIcon: false,
                  ),
                  // Password Section
                  _buildProfileItem(
                    icon: Icons.lock_outline,
                    title: 'Password',
                    subtitle: lastPasswordUpdate,
                    showActionIcon: false,
                  ),
                  // Phone Number Section
                  _buildProfileItem(
                    icon: Icons.phone_outlined,
                    title: 'Phone Number',
                    subtitle: userPhone,
                    showActionIcon: true,
                    onEdit: () {
                      // TODO: Implement edit phone functionality
                    },
                  ),
                  // Log Out Section
                  GestureDetector(
                    onTap: _handleLogOut,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.logout,
                            size: 24,
                            color: AppColors.change,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Log Out',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool showActionIcon,
    VoidCallback? onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: AppColors.black,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (showActionIcon)
            GestureDetector(
              onTap: onEdit,
              child: const Icon(
                Icons.edit,
                size: 20,
                color: AppColors.grey,
              ),
            )
          else
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.grey,
            ),
        ],
      ),
    );
  }
}