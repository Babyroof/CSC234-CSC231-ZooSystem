import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'package:zoopernova_zoo_system/core/routes/app_routes.dart';
import 'package:zoopernova_zoo_system/core/widgets/sidebarAdmin.dart';
import 'change_password_admin_screen.dart';
import '../models/profile_admin_model.dart';
import '../services/profile_admin_service.dart';

class ProfileAdminScreen extends ConsumerStatefulWidget {
  const ProfileAdminScreen({super.key});

  @override
  ConsumerState<ProfileAdminScreen> createState() => _ProfileAdminScreenState();
}

class _ProfileAdminScreenState extends ConsumerState<ProfileAdminScreen> {
  ProfileAdminModel? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ref.read(profileAdminServiceProvider).getProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBg,
      body: Row(
        children: [
          const AdminSidebar(activeIndex: -1),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : _ProfileView(
                                profile: _profile,
                                onEdit: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    AppRoute.adminEditProfile,
                                    arguments: _profile,
                                  );
                                  _loadProfile();
                                },
                                onChangePassword: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ChangePasswordAdminScreen(),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.profile,
    required this.onEdit,
    required this.onChangePassword,
  });

  final ProfileAdminModel? profile;
  final VoidCallback onEdit;
  final VoidCallback onChangePassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Management',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _ReadField(
                label: 'Name',
                value: profile?.firstname ?? '',
                hint: 'fill name',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ReadField(
                label: 'Surname',
                value: profile?.lastname ?? '',
                hint: 'fill surname',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ReadField(
          label: 'Email',
          value: profile?.email ?? '',
          hint: 'email@mail.com',
        ),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Password',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.adminBorderLight),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '••••••••••',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.adminTextDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: onChangePassword,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    side: const BorderSide(color: AppColors.adminPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      color: AppColors.adminPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 120,
            height: 44,
            child: ElevatedButton(
              onPressed: onEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Edit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadField extends StatelessWidget {
  const _ReadField({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final isEmpty = value.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.adminBorderLight),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isEmpty ? hint : value,
            style: TextStyle(
              fontSize: 14,
              color: isEmpty
                  ? AppColors.adminTextMuted
                  : AppColors.adminTextDark,
            ),
          ),
        ),
      ],
    );
  }
}
