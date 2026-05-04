import 'package:flutter/material.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'package:zoopernova_zoo_system/core/constants/app_strings.dart';
import 'package:zoopernova_zoo_system/core/widgets/zoo_bottom_nav.dart';
import 'package:zoopernova_zoo_system/features/auth/models/auth_model.dart';
import 'package:zoopernova_zoo_system/features/auth/services/auth_service.dart';
import '../services/profile_service.dart';
import 'change_phone_number_screen.dart';
import 'change_name_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final userData = await ProfileService().getUserProfile();
    if (mounted) {
      setState(() {
        _currentUser = userData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      bottomNavigationBar: ZooBottomNav(currentIndex: 3),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_ios,
                            size: 16,
                            color: AppColors.black,
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Profile',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Avatar
                    const Icon(Icons.person, size: 96, color: AppColors.black),
                    const SizedBox(height: 12),

                    // Full Name
                    Text(
                      _currentUser != null
                          ? '${_currentUser!.firstname} ${_currentUser!.lastname}'
                          : 'Unknown User',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info Card
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildRow(
                            icon: Icons.badge_outlined,
                            label: 'Name',
                            onEditTap: _currentUser == null
                                ? null
                                : () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChangeNameScreen(
                                          currentFirstname:
                                              _currentUser!.firstname,
                                          currentLastname:
                                              _currentUser!.lastname,
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      setState(() => _isLoading = true);
                                      _fetchUserProfile();
                                    }
                                  },
                            hasDivider: true,
                          ),
                          _buildRow(
                            icon: Icons.alternate_email,
                            label: AppStrings.email,
                            subtitle: _currentUser?.email ?? '',
                            hasDivider: true,
                          ),
                          _buildRow(
                            icon: Icons.lock_outline,
                            label: AppStrings.password,
                            subtitle: 'last update xx/xx/xxxx',
                            hasDivider: true,
                          ),
                          _buildRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone Number',
                            subtitle: _currentUser?.phoneNumber ?? '',
                            onEditTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChangePhoneNumberScreen(
                                    currentPhoneNumber:
                                        _currentUser?.phoneNumber ?? '',
                                  ),
                                ),
                              );
                              setState(() => _isLoading = true);
                              _fetchUserProfile();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Log Out Card
                    GestureDetector(
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        await AuthService().logout();
                        navigator.pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.logout, size: 22, color: AppColors.black),
                            SizedBox(width: 16),
                            Text(
                              'Log Out',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String label,
    String? subtitle,
    VoidCallback? onEditTap,
    bool hasDivider = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.black),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onEditTap != null)
                GestureDetector(
                  onTap: onEditTap,
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.grey,
                  ),
                ),
            ],
          ),
        ),
        if (hasDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.background,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
