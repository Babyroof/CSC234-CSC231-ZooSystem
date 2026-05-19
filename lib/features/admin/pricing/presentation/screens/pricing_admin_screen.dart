import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'package:zoopernova_zoo_system/core/widgets/adminTopHeader.dart';
import 'package:zoopernova_zoo_system/core/widgets/sidebarAdmin.dart';
import '../../services/pricing_admin_service.dart';

// ---------------------------------------------------------------------------
// Screen

class PricingAdminScreen extends StatefulWidget {
  const PricingAdminScreen({super.key});

  @override
  State<PricingAdminScreen> createState() => _PricingAdminScreenState();
}

class _PricingAdminScreenState extends State<PricingAdminScreen> {
  final PricingAdminService _service = PricingAdminService();

  late final TextEditingController _adultController;
  late final TextEditingController _childController;
  late final TextEditingController _elderController;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _adultController = TextEditingController();
    _childController = TextEditingController();
    _elderController = TextEditingController();
    _loadPricing();
  }

  @override
  void dispose() {
    _adultController.dispose();
    _childController.dispose();
    _elderController.dispose();
    super.dispose();
  }

  Future<void> _loadPricing() async {
    setState(() {
      _isLoading = true;
      _successMessage = null;
      _errorMessage = null;
    });
    try {
      final data = await _service.getPricing();
      if (!mounted) return;
      _adultController.text = '${data['adultPrice'] ?? 0}';
      _childController.text = '${data['childPrice'] ?? 0}';
      _elderController.text = '${data['elderPrice'] ?? 0}';
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to load pricing: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final adult = int.tryParse(_adultController.text.trim());
    final child = int.tryParse(_childController.text.trim());
    final elder = int.tryParse(_elderController.text.trim());

    if (adult == null || child == null || elder == null) {
      setState(() => _errorMessage = 'All prices must be valid numbers.');
      return;
    }

    setState(() {
      _isSaving = true;
      _successMessage = null;
      _errorMessage = null;
    });

    try {
      await _service.updatePricing(
        adultPrice: adult,
        childPrice: child,
        elderPrice: elder,
      );
      if (!mounted) return;
      setState(() => _successMessage = 'Pricing updated successfully.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to save pricing: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBg,
      body: Row(
        children: [
          const AdminSidebar(activeIndex: 6),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminTopHeader(title: 'Pricing Management'),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _PricingForm(
                                adultController: _adultController,
                                childController: _childController,
                                elderController: _elderController,
                                isSaving: _isSaving,
                                successMessage: _successMessage,
                                errorMessage: _errorMessage,
                                onSave: _save,
                                onRefresh: _loadPricing,
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

// ---------------------------------------------------------------------------

class _PricingForm extends StatelessWidget {
  const _PricingForm({
    required this.adultController,
    required this.childController,
    required this.elderController,
    required this.isSaving,
    required this.onSave,
    required this.onRefresh,
    this.successMessage,
    this.errorMessage,
  });

  final TextEditingController adultController;
  final TextEditingController childController;
  final TextEditingController elderController;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onRefresh;
  final String? successMessage;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ticket Prices',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.adminTextDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'These prices are used as the baseline ticket cost per visitor type.',
              style: TextStyle(fontSize: 14, color: AppColors.adminTextMuted),
            ),
            const SizedBox(height: 28),
            _PriceField(
              label: 'Adult Price (฿)',
              hint: '300',
              controller: adultController,
            ),
            const SizedBox(height: 18),
            _PriceField(
              label: 'Child Price (฿)',
              hint: '150',
              controller: childController,
            ),
            const SizedBox(height: 18),
            _PriceField(
              label: 'Elder Price (฿)',
              hint: '40',
              controller: elderController,
            ),
            const SizedBox(height: 32),
            if (successMessage != null) ...[
              _StatusBanner(message: successMessage!, isError: false),
              const SizedBox(height: 16),
            ],
            if (errorMessage != null) ...[
              _StatusBanner(message: errorMessage!, isError: true),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                OutlinedButton(
                  onPressed: isSaving ? null : onRefresh,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.adminBorderGreen),
                    foregroundColor: AppColors.adminPrimary,
                    minimumSize: const Size(100, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Refresh'),
                ),
                const SizedBox(width: 14),
                ElevatedButton(
                  onPressed: isSaving ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 44),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _PriceField extends StatelessWidget {
  const _PriceField({
    required this.label,
    required this.hint,
    required this.controller,
  });

  final String label;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.adminTextDark,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 240,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.adminTextMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.adminBorderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.adminPrimary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final bg = isError ? AppColors.adminDangerBg : const Color(0xFFE6F4EA);
    final fg = isError ? AppColors.adminDanger : const Color(0xFF2E7D32);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
