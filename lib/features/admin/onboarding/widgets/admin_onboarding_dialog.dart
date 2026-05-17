import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'package:zoopernova_zoo_system/core/routes/app_routes.dart';

const _kPrefKey = 'admin_onboarding_v1_done';

class _StepData {
  const _StepData({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.description,
    required this.actionLabel,
    this.previewImage,
    this.route,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String description;
  final String actionLabel;
  final String? previewImage; // asset path; null on final "done" step
  final String? route;

  bool get isAdvanceOnly => !isLastStep && route == null;
  bool get isLastStep => actionLabel == 'Start Managing';
}

const _steps = <_StepData>[
  _StepData(
    icon: Icons.map_outlined,
    iconBg: Color(0xFFE8F5E9),
    title: 'Upload Your Zoo Map',
    description:
        'Start by uploading your zoo\'s map image from your device. '
        'This map will be used to pin animal locations later. '
        'Go to the Map page and click "Upload Map" to get started.',
    actionLabel: 'Go to Map',
    previewImage: 'lib/assets/images/onboarding/step1_map.png',
    route: AppRoute.adminMapUploaded,
  ),
  _StepData(
    icon: Icons.location_on_outlined,
    iconBg: Color(0xFFFFF9C4),
    title: 'Set Up Your Zones',
    description:
        'Divide your zoo into zones (e.g. Africa, Asia, Australia). '
        'Zones help organize animals by habitat area. '
        'Go to the Zone page and click "Create New Zone" to add your zones.',
    actionLabel: 'Go to Zones',
    previewImage: 'lib/assets/images/onboarding/step2_zones.png',
    route: AppRoute.adminZones,
  ),
  _StepData(
    icon: Icons.pets_outlined,
    iconBg: Color(0xFFE8F5E9),
    title: 'Register Your Animals',
    description:
        'Add animals to your inventory. Each animal requires a name, '
        'photo, description, and zone assignment. A QR code will be '
        'auto-generated for each animal. Go to the Animals page and '
        'click "Register New Animal".',
    actionLabel: 'Go to Animals',
    previewImage: 'lib/assets/images/onboarding/step3_animals.png',
    route: AppRoute.adminAnimals,
  ),
  _StepData(
    icon: Icons.push_pin_outlined,
    iconBg: Color(0xFFE3F2FD),
    title: 'Set Animal Locations',
    description:
        'After adding an animal, click the "Set Map" button on the '
        'Add Animal form. A map popup will appear — tap on the map to '
        'place a pin at the animal\'s exact location, then click '
        '"Confirm" to save the coordinates.',
    actionLabel: 'Understood',
    previewImage: 'lib/assets/images/onboarding/step4_add_animal.png',
    route: null,
  ),
  _StepData(
    icon: Icons.celebration_outlined,
    iconBg: Color(0xFFFCE4EC),
    title: 'Create Events',
    description:
        'Events follow the same setup process as animals — fill in '
        'event details and use "Set Map" to pin the event location on '
        'your zoo map. Go to the Events page to get started.',
    actionLabel: 'Go to Events',
    previewImage: 'lib/assets/images/onboarding/step5_pin_map.png',
    route: AppRoute.adminEvents,
  ),
  _StepData(
    icon: Icons.book_outlined,
    iconBg: Color(0xFFE8EAF6),
    title: 'Track Bookings',
    description:
        'The Bookings page lets you view all ticket reservations. '
        'You can search by visitor name or booking ID, filter by status '
        '(done / pending / cancel), and manage individual bookings as '
        'needed. No setup required — bookings appear automatically.',
    actionLabel: 'Go to Bookings',
    previewImage: 'lib/assets/images/onboarding/step6_bookings.png',
    route: AppRoute.adminBookings,
  ),
  _StepData(
    icon: Icons.check_circle_outline,
    iconBg: Color(0xFFE8F5E9),
    title: "You're all set!",
    description:
        'Your zoo management system is ready to use. '
        'You can revisit this guide anytime from the Help menu.',
    actionLabel: 'Start Managing',
    route: null,
  ),
];

// Total setup steps (excludes the final "done" card); must stay in sync with _steps
const _kMainStepCount = 6;

class AdminOnboardingDialog extends StatefulWidget {
  const AdminOnboardingDialog({super.key});

  /// Shows the onboarding dialog if this admin has not completed it yet.
  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(_kPrefKey) ?? false;
    if (!context.mounted || done) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => const AdminOnboardingDialog(),
    );
  }

  @override
  State<AdminOnboardingDialog> createState() => _AdminOnboardingDialogState();
}

class _AdminOnboardingDialogState extends State<AdminOnboardingDialog>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  _StepData get _current => _steps[_index];
  bool get _isFirst => _index == 0;
  bool get _isLast => _index == _steps.length - 1;

  Future<void> _markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefKey, true);
  }

  Future<void> _goTo(int newIndex) async {
    await _anim.reverse();
    if (!mounted) return;
    setState(() => _index = newIndex);
    _anim.forward();
  }

  Future<void> _handleAction() async {
    if (_isLast) {
      await _markDone();
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (_current.isAdvanceOnly) {
      _goTo(_index + 1);
      return;
    }

    await _markDone();
    if (!mounted) return;
    final nav = Navigator.of(context);
    nav.pop();
    if (_current.route != null && _current.route != AppRoute.adminAnimals) {
      nav.pushReplacementNamed(_current.route!);
    }
  }

  Future<void> _handleSkip() async {
    await _markDone();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(index: _index, total: _steps.length),
                Flexible(
                  child: SingleChildScrollView(
                    child: FadeTransition(
                      opacity: _fade,
                      child: _StepBody(step: _current),
                    ),
                  ),
                ),
                _Footer(
                  step: _current,
                  isFirst: _isFirst,
                  isLast: _isLast,
                  canNext: !_isLast,
                  onBack: _isFirst ? null : () => _goTo(_index - 1),
                  onNext: () => _goTo(_index + 1),
                  onAction: _handleAction,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final isLast = index == total - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(36, 24, 36, 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.adminBorderLight)),
      ),
      child: Row(
        children: [
          Text(
            isLast ? 'Complete' : 'Step ${index + 1} of $_kMainStepCount',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.adminTextMuted,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          Row(
            children: List.generate(total, (i) {
              final active = i == index;
              final done = i < index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                margin: const EdgeInsets.only(left: 7),
                width: active ? 32 : 12,
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: active
                      ? AppColors.adminPrimary
                      : done
                      ? AppColors.adminPrimary.withValues(alpha: 0.35)
                      : AppColors.adminBorderMedium,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.step});

  final _StepData step;

  @override
  Widget build(BuildContext context) {
    final hasImage = step.previewImage != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(36, hasImage ? 28 : 48, 36, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (hasImage) ...[
            _ScreenshotPreview(assetPath: step.previewImage!, icon: step.icon),
            const SizedBox(height: 24),
          ] else ...[
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: step.iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(step.icon, size: 60, color: AppColors.adminPrimary),
            ),
            const SizedBox(height: 28),
          ],
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.adminTextDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.adminTextMuted,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenshotPreview extends StatelessWidget {
  const _ScreenshotPreview({required this.assetPath, required this.icon});

  final String assetPath;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.adminBorderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            assetPath,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (context, error, stack) => Container(
              color: AppColors.adminImagePlaceholder,
              child: Icon(icon, size: 48, color: AppColors.adminPrimary),
            ),
          ),
          // Subtle gradient fade at the bottom for a polished crop effect
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.55),
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

class _Footer extends StatelessWidget {
  const _Footer({
    required this.step,
    required this.isFirst,
    required this.isLast,
    required this.canNext,
    required this.onBack,
    required this.onNext,
    required this.onAction,
  });

  final _StepData step;
  final bool isFirst;
  final bool isLast;
  final bool canNext;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 18, 32, 22),
      decoration: BoxDecoration(
        color: AppColors.adminCardBg,
        border: Border(top: BorderSide(color: AppColors.adminBorderLight)),
      ),
      child: Row(
        children: [
          const Spacer(),
          if (!isFirst) ...[
            _OutlineBtn(label: '← Back', onPressed: onBack!),
            const SizedBox(width: 8),
          ],
          if (canNext) ...[
            _OutlineBtn(label: 'Next →', onPressed: onNext),
            const SizedBox(width: 8),
          ],
          if (isLast)
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                step.actionLabel,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.adminTextDark,
        side: const BorderSide(color: AppColors.adminBorderMedium),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 17)),
    );
  }
}
