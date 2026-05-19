import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoopernova_zoo_system/core/widgets/zoo_bottom_nav.dart';
import 'package:zoopernova_zoo_system/features/auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final current = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

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
        .read(profileNotifierProvider.notifier)
        .changePassword(
          _currentPasswordController.text.trim(),
          _newPasswordController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == 'Success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
      await ref.read(logoutUseCaseProvider).call();
      if (mounted) {
        context.go('/login');
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(
            Icons.arrow_back_ios,
            size: 16,
            color: Color(0xFF10161F),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Change Password',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF10161F),
          ),
        ),
      ),
      extendBody: true,
      bottomNavigationBar: ZooBottomNav(currentIndex: 3),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Current Password'),
                const SizedBox(height: 12),
                _buildPasswordField(
                  controller: _currentPasswordController,
                  hint: 'Enter current password',
                  obscure: _obscureCurrent,
                  errorText: _currentPasswordError,
                  onToggle: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                  onChanged: (_) =>
                      setState(() => _currentPasswordError = null),
                ),
                const SizedBox(height: 24),
                _buildLabel('New Password'),
                const SizedBox(height: 12),
                _buildPasswordField(
                  controller: _newPasswordController,
                  hint: 'Enter new password',
                  obscure: _obscureNew,
                  errorText: _newPasswordError,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  onChanged: (_) => setState(() => _newPasswordError = null),
                ),
                const SizedBox(height: 24),
                _buildLabel('Confirm New Password'),
                const SizedBox(height: 12),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  hint: 'Confirm new password',
                  obscure: _obscureConfirm,
                  errorText: _confirmPasswordError,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  onChanged: (_) =>
                      setState(() => _confirmPasswordError = null),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(125, 220, 122, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF000000),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required ValueChanged<String> onChanged,
    String? errorText,
  }) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFFCCCCCC),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 14.0,
            ),
            filled: true,
            fillColor: hasError
                ? const Color(0xFFFFF0F0)
                : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: hasError
                  ? const BorderSide(color: Color(0xFFE53935), width: 1)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFE53935)
                    : const Color(0xFF10161F),
                width: 1,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: const Color(0xFF999999),
              ),
              onPressed: onToggle,
            ),
          ),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF000000),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 14,
                color: Color(0xFFE53935),
              ),
              const SizedBox(width: 4),
              Text(
                errorText,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFFE53935),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
