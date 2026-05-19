import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'package:zoopernova_zoo_system/core/routes/app_routes.dart';
import 'package:zoopernova_zoo_system/core/utils/validators.dart';
import 'package:zoopernova_zoo_system/features/auth/presentation/providers/auth_providers.dart';
import 'package:zoopernova_zoo_system/features/auth/presentation/widgets/custom_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateFirstname(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your firstname';
    return null;
  }

  String? _validateLastname(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your lastname';
    return null;
  }

  String? _validateEmail(String? value) => AppValidators.email(value);

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your phone number';
    if (!RegExp(r'^[0-9]+$').hasMatch(value))
      return 'Phone number must contain only digits';
    if (value.length != 10) return 'Phone number must be 10 digits';
    return null;
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await ref
        .read(registerUseCaseProvider)
        .call(
          firstname: _firstnameController.text.trim(),
          lastname: _lastnameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: '',
          phoneNumber: _phoneController.text.trim(),
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result == 'Success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully')),
        );
        context.go(AppRoute.login);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result ?? 'Signup failed')));
      }
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
                height: MediaQuery.of(context).size.height * 0.20,
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
                            'Sign Up',
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
                            'create an account to continue',
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
                                  label: 'Firstname',
                                  hintText: 'Enter Firstname',
                                  controller: _firstnameController,
                                  validator: _validateFirstname,
                                ),
                                const SizedBox(height: 20),
                                CustomTextField(
                                  label: 'Lastname',
                                  hintText: 'Enter lastname',
                                  controller: _lastnameController,
                                  validator: _validateLastname,
                                ),
                                const SizedBox(height: 20),
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
                                const SizedBox(height: 20),
                                CustomTextField(
                                  label: 'Phone Number',
                                  hintText: '0812345678',
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  validator: _validatePhone,
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleSignUp,
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
                                            'Sign Up',
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
                                'Already have an account? ',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  color: AppColors.grey,
                                ),
                              ),
                              Semantics(
                                container: true,
                                label: 'Sign In',
                                button: true,
                                excludeSemantics: true,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Text(
                                    'Sign In',
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
