import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'package:zoopernova_zoo_system/core/routes/app_routes.dart';
import 'package:zoopernova_zoo_system/core/widgets/sidebarAdmin.dart';
import 'package:zoopernova_zoo_system/features/auth/services/auth_service.dart';
import '../services/profile_admin_service.dart';

class ChangePasswordAdminScreen extends ConsumerStatefulWidget {
  const ChangePasswordAdminScreen({super.key});

  @override
  ConsumerState<ChangePasswordAdminScreen> createState() =>
      _ChangePasswordAdminScreenState();
}

class _ChangePasswordAdminScreenState
    extends ConsumerState<ChangePasswordAdminScreen> {
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    final current = _currentPasswordCtrl.text.trim();
    final newPass = _newPasswordCtrl.text.trim();
    final confirm = _confirmPasswordCtrl.text.trim();

    String? currentErr;
    String? newErr;
    String? confirmErr;

    if (current.isEmpty) currentErr = 'Please enter your current password';
    if (newPass.isEmpty) {
      newErr = 'Please enter a new password';
    } else if (newPass.length < 6) {
      newErr = 'Password must be at least 6 characters';
    }
    if (confirm.isEmpty) {
      confirmErr = 'Please confirm your new password';
    } else if (newPass.isNotEmpty && newPass != confirm) {
      confirmErr = 'Passwords do not match';
    }

    setState(() {
      _currentPasswordError = currentErr;
      _newPasswordError = newErr;
      _confirmPasswordError = confirmErr;
    });

    return currentErr == null && newErr == null && confirmErr == null;
  }

  Future<void> _changePassword() async {
    if (!_validate()) return;
    setState(() => _isLoading = true);

    final result = await ref
        .read(profileAdminServiceProvider)
        .changePassword(
          _currentPasswordCtrl.text.trim(),
          _newPasswordCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == 'Success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
      await AuthService().logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoute.adminLogin,
          (route) => false,
        );
      }
    } else if (result == 'wrong-password') {
      setState(() => _currentPasswordError = 'Current password is incorrect');
    } else {
      setState(() => _currentPasswordError = result);
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Change Password',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 28),
                            _PasswordField(
                              label: 'Current Password',
                              controller: _currentPasswordCtrl,
                              hint: 'Enter current password',
                              obscure: _obscureCurrent,
                              errorText: _currentPasswordError,
                              onToggle: () => setState(
                                () => _obscureCurrent = !_obscureCurrent,
                              ),
                              onChanged: (_) =>
                                  setState(() => _currentPasswordError = null),
                            ),
                            const SizedBox(height: 20),
                            _PasswordField(
                              label: 'New Password',
                              controller: _newPasswordCtrl,
                              hint: 'Enter new password',
                              obscure: _obscureNew,
                              errorText: _newPasswordError,
                              onToggle: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                              onChanged: (_) =>
                                  setState(() => _newPasswordError = null),
                            ),
                            const SizedBox(height: 20),
                            _PasswordField(
                              label: 'Confirm New Password',
                              controller: _confirmPasswordCtrl,
                              hint: 'Confirm new password',
                              obscure: _obscureConfirm,
                              errorText: _confirmPasswordError,
                              onToggle: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              onChanged: (_) =>
                                  setState(() => _confirmPasswordError = null),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  width: 120,
                                  height: 44,
                                  child: OutlinedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: AppColors.adminBorderMedium,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 160,
                                  height: 44,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _changePassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.adminPrimary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Change Password',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggle,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            obscureText: obscure,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.adminTextMuted,
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.adminTextMuted,
                ),
                onPressed: onToggle,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.adminBorderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: hasError
                      ? const Color(0xFFE53935)
                      : AppColors.adminBorderLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: hasError
                      ? const Color(0xFFE53935)
                      : AppColors.adminPrimary,
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 14,
                color: Color(0xFFE53935),
              ),
              const SizedBox(width: 4),
              Text(
                errorText!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFE53935)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
