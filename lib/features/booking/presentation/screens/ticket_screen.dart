import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/zoo_bottom_nav.dart';
import '../../constants/booking_pricing.dart';
import '../../domain/entities/selected_add_on_entity.dart';
import '../providers/booking_providers.dart';
import 'ticket_history_screen.dart';

class TicketScreen extends ConsumerWidget {
  const TicketScreen({super.key});

  String _formatDate(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[d.weekday - 1]}, ${d.day.toString().padLeft(2, '0')}/${months[d.month - 1]}/${d.year}';
  }

  void _showQrSheet(BuildContext context, String ticketId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TicketQrSheet(ticketId: ticketId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios,
            size: 18,
            color: AppColors.black,
          ),
        ),
        title: const Text(
          'Tickets',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TicketHistoryScreen()),
            ),
            child: const Padding(
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.history, size: 24, color: AppColors.black),
            ),
          ),
        ],
      ),
      body: upcomingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(
              child: Text(
                'No upcoming tickets',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            itemCount: bookings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _TicketCard(
                ticketId: booking.id,
                date: _formatDate(booking.date),
                adultCount: booking.adultTotal,
                kidCount: booking.childTotal,
                elderCount: booking.elderTotal,
                adultUnit: BookingPricing.adultPrice,
                kidUnit: BookingPricing.kidPrice,
                elderUnit: BookingPricing.elderPrice,
                totalAmount: booking.totalPrice ?? booking.totalAmount,
                selectedAddOns: booking.selectedAddOns,
                onQrTap: () => _showQrSheet(context, booking.id),
              );
            },
          );
        },
      ),
      bottomNavigationBar: ZooBottomNav(currentIndex: 2),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.ticketId,
    required this.date,
    required this.adultCount,
    required this.kidCount,
    required this.elderCount,
    required this.adultUnit,
    required this.kidUnit,
    required this.elderUnit,
    required this.totalAmount,
    required this.selectedAddOns,
    required this.onQrTap,
  });

  final String ticketId;
  final String date;
  final int adultCount;
  final int kidCount;
  final int elderCount;
  final int adultUnit;
  final int kidUnit;
  final int elderUnit;
  final int totalAmount;
  final List<SelectedAddOnEntity> selectedAddOns;
  final VoidCallback onQrTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.confirmation_num_rounded,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${ticketId.length > 8 ? ticketId.substring(0, 8).toUpperCase() : ticketId.toUpperCase()}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: onQrTap,
                  child: const Icon(
                    Icons.qr_code_scanner,
                    size: 28,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
          if (adultCount > 0)
            _TicketItem(
              icon: Icons.person_outline,
              label: 'Adult',
              count: adultCount,
              unitPrice: adultUnit,
            ),
          if (kidCount > 0)
            _TicketItem(
              icon: Icons.face_retouching_natural,
              label: 'Kid',
              count: kidCount,
              unitPrice: kidUnit,
            ),
          if (elderCount > 0)
            _TicketItem(
              icon: Icons.elderly,
              label: 'Elder',
              count: elderCount,
              unitPrice: elderUnit,
            ),
          if (selectedAddOns.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Divider(
                height: 1,
                color: AppColors.background,
                thickness: 1.5,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Add-ons',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.grey,
                ),
              ),
            ),
            ...selectedAddOns.map(
              (a) => _AddonItem(icon: Icons.add_circle_outline, label: a.name),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Divider(
              height: 1,
              color: AppColors.background,
              thickness: 1.5,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '฿$totalAmount',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Status',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.grey,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Paid by QR Code',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TicketItem extends StatelessWidget {
  const _TicketItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.unitPrice,
  });

  final IconData icon;
  final String label;
  final int count;
  final int unitPrice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: AppColors.black),
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
                  '$unitPrice ฿',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${count}x',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddonItem extends StatelessWidget {
  const _AddonItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
          ),
          const Spacer(),
          Icon(Icons.check_circle, size: 18, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _TicketQrSheet extends StatelessWidget {
  const _TicketQrSheet({required this.ticketId});

  final String ticketId;

  @override
  Widget build(BuildContext context) {
    final qrData = 'ZOOPERNOVA-TICKET:$ticketId';
    final qrSize = MediaQuery.of(context).size.width - 88;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ticket QR Code',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '#$ticketId',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: qrSize,
              backgroundColor: AppColors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Show this QR at the zoo entrance',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
