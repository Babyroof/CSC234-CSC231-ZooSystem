import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'package:zoopernova_zoo_system/core/routes/app_routes.dart';
import 'package:zoopernova_zoo_system/core/services/biometric_service.dart';
import 'package:zoopernova_zoo_system/core/utils/validators.dart';
import 'package:zoopernova_zoo_system/features/auth/presentation/providers/auth_providers.dart';
import 'package:zoopernova_zoo_system/features/auth/presentation/widgets/custom_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _backendError;
  bool _biometricReady = false; // available + enabled + active session

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearErrorOnType);
    _passwordController.addListener(_clearErrorOnType);
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final enabled = await BiometricService.isEnabled();
    if (mounted) setState(() => _biometricReady = enabled);
  }

  void _clearErrorOnType() {
    if (_backendError != null) {
      setState(() => _backendError = null);
      _formKey.currentState?.validate();
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearErrorOnType);
    _passwordController.removeListener(_clearErrorOnType);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) => AppValidators.email(value);

  String? _validatePassword(String? value) {
    if (_backendError != null) return _backendError;
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final result = await ref
          .read(loginUseCaseProvider)
          .call(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) {
        if (result == 'Success') {
          // Await dialog before navigating — avoids using unmounted context.
          await _promptEnableBiometric();
          if (mounted) context.go(AppRoute.home);
        } else {
          setState(
            () => _backendError = result ?? 'Email or Password is not correct',
          );
          _formKey.currentState!.validate();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login error')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _promptEnableBiometric() async {
    // Timeout guards against platform-channel hangs in test/CI environments.
    final available = await BiometricService.isAvailable()
        .timeout(const Duration(seconds: 3), onTimeout: () => false);
    final alreadyEnabled = await BiometricService.isEnabled();
    if (!available || alreadyEnabled || !mounted) return;

    final enable = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enable Biometric Login'),
        content: const Text(
          'Use fingerprint or face ID to sign in faster next time?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
    if (enable == true) await BiometricService.setEnabled(true);
  }

  Future<void> _handleBiometricLogin() async {
    final success = await BiometricService.authenticate();
    if (success && mounted) {
      context.go(AppRoute.home);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.35,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  image: DecorationImage(
                    image: AssetImage('lib/assets/images/background.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(color: Colors.black.withValues(alpha: 0.1)),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: const DecorationImage(
                                image: AssetImage('lib/assets/images/logo.png'),
                                fit: BoxFit.cover,
                              ),
                              color: AppColors.background,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Welcome to',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              height: 1.0,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Zoopernova let\'s get start',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              height: 1.0,
                              color: AppColors.grey,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomTextField(
                                  label: 'Email',
                                  hintText: 'Enter Email',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _validateEmail,
                                ),
                                const SizedBox(height: 20),
                                CustomTextField(
                                  label: 'Password',
                                  hintText: 'Enter Password',
                                  controller: _passwordController,
                                  isPassword: true,
                                  validator: _validatePassword,
                                ),
                                const SizedBox(height: 32),
                                if (_biometricReady) ...[
                                  SizedBox(
                                    width: double.infinity,
                                    height: 46,
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          _isLoading
                                              ? null
                                              : _handleBiometricLogin,
                                      icon: const Icon(
                                        Icons.fingerprint,
                                        color: AppColors.primary,
                                      ),
                                      label: const Text(
                                        'Sign in with Biometric',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: AppColors.primary,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    AppColors.white,
                                                  ),
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16,
                                              color: AppColors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Do not have an account? ',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  color: AppColors.grey,
                                ),
                              ),
                              Semantics(
                                container: true,
                                label: 'Sign Up',
                                button: true,
                                excludeSemantics: true,
                                child: GestureDetector(
                                  onTap: () => context.push(AppRoute.register),
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: GestureDetector(
                              onTap: () => context.go(AppRoute.home),
                              child: const Text(
                                'Continue as Guest',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                  color: AppColors.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
