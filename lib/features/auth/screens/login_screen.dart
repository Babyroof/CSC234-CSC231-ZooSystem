import 'package:flutter/material.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'package:zoopernova_zoo_system/features/auth/widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    // Simple email validation
    if (!value.contains('@') || !value.contains('.')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate login delay
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful')),
        );
        // TODO: Navigate to home screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToSignUp() {
    Navigator.pushNamed(context, '/register');
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
              // Top Image Section (Giraffe background-like section)
              Container(
                height: MediaQuery.of(context).size.height * 0.35,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  image: DecorationImage(
                    image: AssetImage('lib/core/images/background.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  // Overlay for better text visibility
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
              // Bottom Content Section
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
                          // Logo Placeholder
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: const DecorationImage(
                                image: AssetImage('lib/core/images/logo.png'),
                                fit: BoxFit.cover,
                              ),
                            color: AppColors.background,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Welcome Text
                          Text(
                            'Welcome to',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              height: 1.0,
                              letterSpacing: 0,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Description
                          Text(
                            'Zoopernova let’s get start',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              height: 1.0,
                              letterSpacing: 0,
                              color: AppColors.grey,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Login Form
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Email Field
                                CustomTextField(
                                  label: 'Email',
                                  hintText: 'Enter Email',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _validateEmail,
                                ),
                                const SizedBox(height: 20),
                                // Password Field
                                CustomTextField(
                                  label: 'Password',
                                  hintText: 'Enter Password',
                                  controller: _passwordController,
                                  isPassword: true,
                                  validator: _validatePassword,
                                ),
                                const SizedBox(height: 32),
                                // Sign In Button
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
                                                      AppColors.white),
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            'Sign In',
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16,
                                              height: 22 / 16,
                                              letterSpacing: 0,
                                              color: AppColors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Sign Up Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Do not have an account? ',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  height: 1.0,
                                  letterSpacing: 0,
                                  color: AppColors.grey,
                                ),
                              ),
                              GestureDetector(
                                onTap: _navigateToSignUp,
                                child: Text(
                                  'Sign Up',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    height: 1.0,
                                    letterSpacing: 0,
                                    color: AppColors.black,
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
