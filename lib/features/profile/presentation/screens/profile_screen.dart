import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'package:zoopernova_zoo_system/core/constants/app_strings.dart';
import 'package:zoopernova_zoo_system/core/routes/app_routes.dart';
import 'package:zoopernova_zoo_system/core/services/biometric_service.dart';
import 'package:zoopernova_zoo_system/core/widgets/zoo_bottom_nav.dart';
import 'package:zoopernova_zoo_system/features/auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import 'change_name_screen.dart';
import 'change_password_screen.dart';
import 'change_phone_number_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      bottomNavigationBar: const ZooBottomNav(currentIndex: 3),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Failed to load profile')),
        data: (user) {
          if (user == null) {
            return SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => GoRouter.of(context).canPop()
                              ? context.pop()
                              : context.go(AppRoute.home),
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
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person,
                          size: 96,
                          color: AppColors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'You are browsing as a Guest',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: () => context.push(AppRoute.login),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => GoRouter.of(context).canPop()
                            ? context.pop()
                            : context.go(AppRoute.home),
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
                  const Icon(Icons.person, size: 96, color: AppColors.black),
                  const SizedBox(height: 12),
                  Text(
                    '${user.firstname} ${user.lastname}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
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
                          onEditTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNameScreen(
                                currentFirstname: user.firstname,
                                currentLastname: user.lastname,
                              ),
                            ),
                          ),
                          hasDivider: true,
                        ),
                        _buildRow(
                          icon: Icons.alternate_email,
                          label: AppStrings.email,
                          subtitle: user.email ?? '',
                          hasDivider: true,
                        ),
                        _buildRow(
                          icon: Icons.lock_outline,
                          label: AppStrings.password,
                          onEditTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen(),
                            ),
                          ),
                          hasDivider: true,
                        ),
                        _buildRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone Number',
                          subtitle: user.phoneNumber ?? '',
                          onEditTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangePhoneNumberScreen(
                                currentPhoneNumber: user.phoneNumber ?? '',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _BiometricToggle(),
                  const SizedBox(height: 16),
                  // Lock App only shown on mobile — Web has no biometric unlock
                  if (!kIsWeb) Semantics(
                    label: 'Lock App',
                    button: true,
                    child: GestureDetector(
                    onTap: () {
                      if (context.mounted) context.go(AppRoute.login);
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
                          Icon(Icons.lock_outline, size: 22, color: AppColors.black),
                          SizedBox(width: 16),
                          Text(
                            'Lock App',
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
                  )), // end Semantics
                  const SizedBox(height: 12),
                  // Sign Out — clears Firebase session completely
                  Semantics(
                    label: 'Sign Out',
                    button: true,
                    child: GestureDetector(
                    onTap: () async {
                      await ref.read(logoutUseCaseProvider).call();
                      ref.invalidate(profileNotifierProvider);
                      if (context.mounted) context.go(AppRoute.login);
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
                          Icon(Icons.logout, size: 22, color: AppColors.change),
                          SizedBox(width: 16),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.change,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )), // end Semantics
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
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
          const Divider(
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

// Encapsulates its own async state — no changes needed to ProfileScreen.
class _BiometricToggle extends StatefulWidget {
  const _BiometricToggle();

  @override
  State<_BiometricToggle> createState() => _BiometricToggleState();
}

class _BiometricToggleState extends State<_BiometricToggle> {
  bool _available = false;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final available = await BiometricService.isAvailable();
    final enabled = await BiometricService.isEnabled();
    if (mounted) setState(() { _available = available; _enabled = enabled; });
  }

  Future<void> _toggle(bool value) async {
    await BiometricService.setEnabled(value);
    if (mounted) setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.fingerprint,
            size: 22,
            color: _available ? AppColors.black : AppColors.grey,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biometric Login',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _available ? AppColors.black : AppColors.grey,
                  ),
                ),
                if (!_available)
                  const Text(
                    'Set up fingerprint in device Settings first',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.grey,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: _enabled,
            onChanged: _available ? _toggle : null,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}
