import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/add_on_entity.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/selected_add_on_entity.dart';
import '../providers/booking_providers.dart';

// Local checkout loading state (UI only)
final _checkoutLoadingProvider = StateProvider.autoDispose<bool>((_) => false);

class BookingScreen extends ConsumerWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingFormNotifierProvider);
    final notifier = ref.read(bookingFormNotifierProvider.notifier);
    final addOnsAsync = ref.watch(activeAddOnsProvider);

    // Sync add-ons into form state when loaded
    ref.listen<AsyncValue<List<AddOnEntity>>>(
      activeAddOnsProvider,
      (_, next) => next.whenData(notifier.setLoadedAddOns),
    );

    final loadedAddOns = addOnsAsync.valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _AppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Date'),
                    const SizedBox(height: 8),
                    _DatePickerRow(
                      selectedDate: state.selectedDate,
                      onDateSelected: notifier.setDate,
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle('Ticket Types'),
                    const SizedBox(height: 8),
                    _card(
                      children: [
                        _TicketRow(
                          icon: Icons.person_outline,
                          label: 'Adult',
                          price: state.adultPrice,
                          ageRange: 'Age 9 - 59',
                          count: state.adultCount,
                          onIncrement: notifier.incrementAdult,
                          onDecrement: state.adultCount > 0
                              ? notifier.decrementAdult
                              : null,
                        ),
                        _divider(),
                        _TicketRow(
                          icon: Icons.child_care,
                          label: 'Kid',
                          price: state.kidPrice,
                          ageRange: 'Age 1 - 8',
                          count: state.kidCount,
                          onIncrement: notifier.incrementKid,
                          onDecrement: state.kidCount > 0
                              ? notifier.decrementKid
                              : null,
                        ),
                        _divider(),
                        _TicketRow(
                          icon: Icons.elderly,
                          label: 'Elder',
                          price: state.elderPrice,
                          ageRange: 'Age 60+',
                          count: state.elderCount,
                          onIncrement: notifier.incrementElder,
                          onDecrement: state.elderCount > 0
                              ? notifier.decrementElder
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle('Add-ons'),
                    const SizedBox(height: 8),
                    if (addOnsAsync.isLoading && loadedAddOns.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else if (addOnsAsync.hasError)
                      Text(
                        'Error loading add-ons: ${addOnsAsync.error}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      )
                    else if (loadedAddOns.isEmpty)
                      const Text(
                        'No add-ons available',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      )
                    else
                      _card(
                        children: [
                          for (int i = 0; i < loadedAddOns.length; i++) ...[
                            if (i > 0) _divider(),
                            _AddonRow(
                              icon: Icons.add_circle_outline,
                              label: loadedAddOns[i].name,
                              priceLabel:
                                  loadedAddOns[i].priceType == 'per_person'
                                  ? '${loadedAddOns[i].price} ฿ / person'
                                  : '${loadedAddOns[i].price} ฿ / booking',
                              isSelected: state.selectedAddOnIds.contains(
                                loadedAddOns[i].id,
                              ),
                              onToggle: () =>
                                  notifier.toggleAddOn(loadedAddOns[i].id),
                              isRecommended: false,
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ),
            _BottomBar(state: state, loadedAddOns: loadedAddOns),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      fontFamily: 'Inter',
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.black,
    ),
  );

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(children: children),
  );

  Widget _divider() => Divider(
    height: 1,
    thickness: 1,
    color: AppColors.background,
    indent: 16,
    endIndent: 16,
  );
}

// ── AppBar ────────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(
              Icons.arrow_back_ios,
              size: 16,
              color: AppColors.black,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Book Tickets',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

// ── Date Picker Row ───────────────────────────────────────────────────────────
class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime? selectedDate;
  final void Function(DateTime) onDateSelected;

  String _format(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '${days[d.weekday - 1]}, $dd / $mm / ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? now,
          firstDate: now,
          lastDate: now.add(const Duration(days: 365)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: AppColors.white,
                surface: AppColors.white,
                onSurface: AppColors.black,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onDateSelected(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: AppColors.grey,
            ),
            const SizedBox(width: 16),
            if (selectedDate == null) ...[
              _datePart('DD'),
              _slash(),
              _datePart('MM'),
              _slash(),
              _datePart('YYYY'),
            ] else
              Text(
                _format(selectedDate!),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _datePart(String label) => Text(
    label,
    style: const TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      color: AppColors.grey,
    ),
  );

  Widget _slash() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: Text(
      '/',
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: AppColors.grey,
      ),
    ),
  );
}

// ── Ticket Row ────────────────────────────────────────────────────────────────
class _TicketRow extends StatelessWidget {
  const _TicketRow({
    required this.icon,
    required this.label,
    required this.price,
    required this.ageRange,
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
  });

  final IconData icon;
  final String label;
  final int price;
  final String ageRange;
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label ticket — $price baht ($ageRange) — count: $count',
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _iconBox(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$price ฿',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ageRange,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            _CounterControl(
              count: count,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            ),
          ],
        ),
      ),
    ); // end Semantics
  }
}

// ── Add-on Row ────────────────────────────────────────────────────────────────
class _AddonRow extends StatelessWidget {
  const _AddonRow({
    required this.icon,
    required this.label,
    required this.priceLabel,
    required this.isSelected,
    required this.onToggle,
    this.isRecommended = false,
  });

  final IconData icon;
  final String label;
  final String priceLabel;
  final bool isSelected;
  final VoidCallback onToggle;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '$label add-on — $priceLabel — ${isSelected ? 'selected' : 'not selected'}',
      button: true,
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _iconBox(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 6),
                        _RecommendBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    priceLabel,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            _CounterControl(
              count: isSelected ? 1 : 0,
              onIncrement: isSelected ? null : onToggle,
              onDecrement: isSelected ? onToggle : null,
            ),
          ],
        ),
      ),
    ); // end Semantics
  }
}

// ── Counter Control ───────────────────────────────────────────────────────────
class _CounterControl extends StatelessWidget {
  const _CounterControl({
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int count;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    final canDec = count > 0 && onDecrement != null;
    final canInc = onIncrement != null;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, canDec ? onDecrement : null),
          SizedBox(
            width: 28,
            child: Center(
              child: Text(
                '$count',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ),
          ),
          _btn(Icons.add, canInc ? onIncrement : null),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap) {
    final isAdd = icon == Icons.add;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: isAdd ? 'Increase count' : 'Decrease count',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: onTap != null ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            size: 14,
            color: onTap != null ? AppColors.black : AppColors.grey,
          ),
        ),
      ),
    );
  }
}

// ── Recommend Badge ───────────────────────────────────────────────────────────
class _RecommendBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.thumb_up_alt_outlined, size: 10, color: AppColors.primary),
          const SizedBox(width: 3),
          Text(
            'Recommend',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Icon Box ──────────────────────────────────────────────────────────────────
Widget _iconBox(IconData icon) => Container(
  width: 44,
  height: 44,
  decoration: BoxDecoration(
    color: AppColors.background,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Icon(icon, size: 22, color: AppColors.black),
);

// ── Bottom Bar ────────────────────────────────────────────────────────────────
class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.state, required this.loadedAddOns});

  final BookingFormState state;
  final List<AddOnEntity> loadedAddOns;

  String _formatDate(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '${days[d.weekday - 1]}, $dd / $mm / ${d.year}';
  }

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to book tickets.')),
      );
      return;
    }

    ref.read(_checkoutLoadingProvider.notifier).state = true;

    try {
      final addOns = loadedAddOns
          .where((a) => state.selectedAddOnIds.contains(a.id))
          .map(
            (a) => SelectedAddOnEntity(
              addOnId: a.id,
              name: a.name,
              price: a.price,
              priceType: a.priceType,
            ),
          )
          .toList();

      final total = state.ticketTotal + state.addOnTotal;

      final booking = BookingEntity(
        id: '',
        userId: uid,
        adultTotal: state.adultCount,
        childTotal: state.kidCount,
        elderTotal: state.elderCount,
        date: state.selectedDate!,
        selectedAddOns: addOns,
        status: 'pending',
        adultUnitPrice: state.adultPrice,
        childUnitPrice: state.kidPrice,
        elderUnitPrice: state.elderPrice,
      );

      final bookingId = await ref
          .read(createBookingUseCaseProvider)
          .call(booking);

      if (!context.mounted) return;

      context.push(
        '/payment',
        extra: {
          'bookingId': bookingId,
          'totalAmount': total,
          'adultCount': state.adultCount,
          'kidCount': state.kidCount,
          'elderCount': state.elderCount,
          'adultUnitPrice': state.adultPrice,
          'kidUnitPrice': state.kidPrice,
          'elderUnitPrice': state.elderPrice,
          'dateMs': state.selectedDate?.millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
    } finally {
      if (ref.context.mounted) {
        ref.read(_checkoutLoadingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCheckout = state.totalPeople > 0 && state.selectedDate != null;
    final isLoading = ref.watch(_checkoutLoadingProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final displayTotal = state.ticketTotal + state.addOnTotal;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad + 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.selectedDate != null
                        ? _formatDate(state.selectedDate!)
                        : '- / - / -',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$displayTotal ฿',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (canCheckout && !isLoading)
                  ? () => _checkout(context, ref)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.grey.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Checkout',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
