import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoopernova_zoo_system/core/widgets/zoo_bottom_nav.dart';
import 'package:zoopernova_zoo_system/features/auth/services/auth_service.dart';
import '../services/profile_notifier.dart';

class ChangePhoneNumberScreen extends ConsumerStatefulWidget {
  final String currentPhoneNumber;

  const ChangePhoneNumberScreen({super.key, required this.currentPhoneNumber});

  @override
  ConsumerState<ChangePhoneNumberScreen> createState() =>
      _ChangePhoneNumberScreenState();
}

class _ChangePhoneNumberScreenState
    extends ConsumerState<ChangePhoneNumberScreen> {
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _passwordController;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _phoneError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _phoneNumberController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final phone = _phoneNumberController.text.trim();
    final password = _passwordController.text.trim();

    String? phoneErr;
    String? passwordErr;

    if (phone.isEmpty) {
      phoneErr = 'Please enter a phone number';
    } else if (phone.length != 10) {
      phoneErr = 'Phone number must be 10 digits';
    }

    if (password.isEmpty) passwordErr = 'Please enter your password';

    setState(() {
      _phoneError = phoneErr;
      _passwordError = passwordErr;
    });

    return phoneErr == null && passwordErr == null;
  }

  Future<void> _changePhone() async {
    if (!_validate()) return;
    setState(() => _isLoading = true);

    final result = await ref
        .read(profileNotifierProvider.notifier)
        .updatePhoneWithAuth(
          _passwordController.text.trim(),
          _phoneNumberController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == 'Success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number updated successfully')),
      );
      await AuthService().logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } else if (result == 'wrong-password') {
      setState(() => _passwordError = 'Password is incorrect');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios,
            size: 16,
            color: Color(0xFF10161F),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Phone Number',
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
                const Text(
                  'Current Phone Number',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.currentPhoneNumber,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF999999),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'New Phone Number',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 12),
                _buildPhoneField(),
                const SizedBox(height: 24),
                const Text(
                  'Password',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 12),
                _buildPasswordField(),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePhone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(125, 220, 122, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Change Phone Number',
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

  Widget _buildPhoneField() {
    final hasError = _phoneError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 50,
          child: TextField(
            controller: _phoneNumberController,
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() => _phoneError = null),
            decoration: InputDecoration(
              hintText: '0812345678',
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFFCCCCCC),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
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
            ),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF000000),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          _buildErrorRow(_phoneError!),
        ],
      ],
    );
  }

  Widget _buildPasswordField() {
    final hasError = _passwordError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          onChanged: (_) => setState(() => _passwordError = null),
          decoration: InputDecoration(
            hintText: 'Enter your password',
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
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: const Color(0xFF999999),
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
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
          _buildErrorRow(_passwordError!),
        ],
      ],
    );
  }

  Widget _buildErrorRow(String message) {
    return Row(
      children: [
        const Icon(Icons.error_outline, size: 14, color: Color(0xFFE53935)),
        const SizedBox(width: 4),
        Text(
          message,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: Color(0xFFE53935),
          ),
        ),
      ],
    );
  }
}
