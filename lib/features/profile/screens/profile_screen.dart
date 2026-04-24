import 'package:flutter/material.dart';
import 'package:zoopernova_zoo_system/core/widgets/zoo_bottom_nav.dart';
import 'change_phone_number_screen.dart';
import 'package:zoopernova_zoo_system/features/auth/models/auth_model.dart';
import 'package:zoopernova_zoo_system/features/auth/services/auth_service.dart';
import '../services/profile_service.dart';
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
    final profileService = ProfileService();
    final userData = await profileService.getUserProfile();

    if(mounted) {
      setState(() {
        _currentUser = userData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: ZooBottomNav(currentIndex: 3),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Back Button and Title
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios, size: 16),
                    ),
                    Expanded(
                      child: Center(
                        child: const Text(
                          'Profile',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 22 / 18,
                            letterSpacing: 0,
                            color: Color(0xFF10161F),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
                const SizedBox(height: 32),
                // Profile Picture
                Center(
                  child: const Icon(
                    Icons.person,
                    size: 120,
                    color: Color(0xFF10161F),
                  ),
                ),
                const SizedBox(height: 24),

                // User Name with Edit Icon
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      if (_currentUser == null) return;
                      
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangeNameScreen(
                            currentFirstname: _currentUser!.firstname,
                            currentLastname: _currentUser!.lastname,
                          ),
                        ),
                      );

                      if (result == true) {
                        setState(() {
                          _isLoading = true; 
                        });
                        _fetchUserProfile(); 
                        }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentUser != null ? '${_currentUser!.firstname} ${_currentUser!.lastname}' : 'Unknown User',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                            letterSpacing: 0,
                            color: Color(0xFF000000),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.mode_edit_outline_outlined, size: 17.5, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Email Section
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 0,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alternate_email, size: 24, color: Color(0xFF10161F)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF282828),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentUser?.email ?? 'No email',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF999999),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Icon(
                      //   Icons.arrow_forward_ios,
                      //   size: 16,
                      //   color: Colors.grey[400],
                      // ),
                    ],
                  ),
                ),

                // Password Section
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 0,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 24,
                        color: Color(0xFF10161F),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Password',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF282828),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'last update xx/xx/xxxx',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF999999),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Icon(
                      //   Icons.arrow_forward_ios,
                      //   size: 16,
                      //   color: Colors.grey[400],
                      // ),
                    ],
                  ),
                ),

                // Phone Number Section
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 0,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 24,
                        color: Color(0xFF10161F),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Phone Number',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF282828),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentUser?.phoneNumber ?? 'No phone number',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF999999),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChangePhoneNumberScreen(
                                currentPhoneNumber: _currentUser?.phoneNumber ?? '',
                              ),
                            ),
                          );
                        },
                        child: Icon(Icons.mode_edit_outline_outlined, size: 17.5, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Log Out Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      await AuthService().logout();
                      if(mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: const Color(0xFFFFFFFF),
                      foregroundColor: const Color(0xFF282828),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(Icons.logout),
                        const SizedBox(width: 16),
                        const Text(
                          'Log Out',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF282828),
                          ),
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
    );
  }
}