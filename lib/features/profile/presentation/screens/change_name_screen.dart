import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoopernova_zoo_system/core/widgets/zoo_bottom_nav.dart';
import '../providers/profile_providers.dart';

class ChangeNameScreen extends ConsumerStatefulWidget {
  final String currentFirstname;
  final String currentLastname;

  const ChangeNameScreen({
    super.key,
    required this.currentFirstname,
    required this.currentLastname,
  });

  @override
  ConsumerState<ChangeNameScreen> createState() => _ChangeNameScreenState();
}

class _ChangeNameScreenState extends ConsumerState<ChangeNameScreen> {
  late final TextEditingController _firstnameController;
  late final TextEditingController _lastnameController;
  bool _isLoading = false;
  String? _firstnameError;
  String? _lastnameError;

  @override
  void initState() {
    super.initState();
    _firstnameController = TextEditingController();
    _lastnameController = TextEditingController();
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    super.dispose();
  }

  bool _validate() {
    final firstErr = _firstnameController.text.trim().isEmpty
        ? 'Please enter a firstname'
        : null;
    final lastErr = _lastnameController.text.trim().isEmpty
        ? 'Please enter a lastname'
        : null;
    setState(() {
      _firstnameError = firstErr;
      _lastnameError = lastErr;
    });
    return firstErr == null && lastErr == null;
  }

  Future<void> _saveName() async {
    if (!_validate()) return;
    setState(() => _isLoading = true);

    final result = await ref
        .read(profileNotifierProvider.notifier)
        .updateProfile({
          'firstname': _firstnameController.text.trim(),
          'lastname': _lastnameController.text.trim(),
        });

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == 'Success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully')),
      );
      Navigator.pop(context);
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
          'Edit Name',
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
                  'Current Name',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.currentFirstname} ${widget.currentLastname}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF999999),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'New Firstname',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _firstnameController,
                  hint: 'Enter your firstname',
                  errorText: _firstnameError,
                  onChanged: (_) => setState(() => _firstnameError = null),
                ),
                const SizedBox(height: 24),
                const Text(
                  'New Lastname',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _lastnameController,
                  hint: 'Enter your lastname',
                  errorText: _lastnameError,
                  onChanged: (_) => setState(() => _lastnameError = null),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveName,
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
                            'Save Changes',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
    String? errorText,
  }) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 50,
          child: TextField(
            controller: controller,
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
