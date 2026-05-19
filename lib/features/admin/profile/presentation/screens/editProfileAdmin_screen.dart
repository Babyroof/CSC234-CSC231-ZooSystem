import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'package:zoopernova_zoo_system/core/widgets/sidebarAdmin.dart';
import '../../models/profile_admin_model.dart';
import '../../services/profile_admin_service.dart';

class EditProfileAdminScreen extends ConsumerStatefulWidget {
  const EditProfileAdminScreen({super.key, this.profile});

  final ProfileAdminModel? profile;

  @override
  ConsumerState<EditProfileAdminScreen> createState() =>
      _EditProfileAdminScreenState();
}

class _EditProfileAdminScreenState
    extends ConsumerState<EditProfileAdminScreen> {
  late final TextEditingController _firstnameCtrl;
  late final TextEditingController _lastnameCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstnameCtrl = TextEditingController(
      text: widget.profile?.firstname ?? '',
    );
    _lastnameCtrl = TextEditingController(text: widget.profile?.lastname ?? '');
  }

  @override
  void dispose() {
    _firstnameCtrl.dispose();
    _lastnameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final firstname = _firstnameCtrl.text.trim();
    final lastname = _lastnameCtrl.text.trim();

    if (firstname.isEmpty || lastname.isEmpty) {
      _showSnackBar('Name and Surname cannot be empty');
      return;
    }

    setState(() => _saving = true);

    try {
      await ref
          .read(profileAdminServiceProvider)
          .updateProfile(firstname: firstname, lastname: lastname);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showSnackBar('Error saving profile: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                              'Profile Management',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                Expanded(
                                  child: _EditField(
                                    label: 'Name',
                                    controller: _firstnameCtrl,
                                    hint: 'fill name',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _EditField(
                                    label: 'Surname',
                                    controller: _lastnameCtrl,
                                    hint: 'fill surname',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _ReadOnlyField(
                              label: 'Email',
                              value: widget.profile?.email ?? '',
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  width: 120,
                                  height: 44,
                                  child: OutlinedButton(
                                    onPressed: _saving
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
                                  width: 120,
                                  height: 44,
                                  child: ElevatedButton(
                                    onPressed: _saving ? null : _save,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.adminPrimary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: _saving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Confirm',
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

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    required this.hint,
  });

  final String label;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
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
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.adminTextMuted,
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.adminBorderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.adminBorderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.adminPrimary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
            color: AppColors.adminBg,
            border: Border.all(color: AppColors.adminBorderLight),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.isEmpty ? '' : value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.adminTextMuted,
            ),
          ),
        ),
      ],
    );
  }
}
