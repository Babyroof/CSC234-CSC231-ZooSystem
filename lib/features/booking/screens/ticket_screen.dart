import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/zoo_bottom_nav.dart';
import 'ticket_history_screen.dart';

// ── Local providers ──────────────────────────────────────────────────────────

final _ticketIdProvider = Provider.autoDispose<String>((_) {
  final rng = Random();
  return 'TK${(rng.nextInt(9000) + 1000)}';
});

// ── Screen ───────────────────────────────────────────────────────────────────

class TicketScreen extends ConsumerWidget {
  final Map<String, dynamic> bookingArgs;

  const TicketScreen({super.key, this.bookingArgs = const {}});

  String _formatDate(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
    final ticketId = ref.watch(_ticketIdProvider);

    final totalAmount = bookingArgs['totalAmount'] as int? ?? 0;
    final adultCount = bookingArgs['adultCount'] as int? ?? 0;
    final kidCount = bookingArgs['kidCount'] as int? ?? 0;
    final elderCount = bookingArgs['elderCount'] as int? ?? 0;
    final adultUnit = bookingArgs['adultUnitPrice'] as int? ?? 0;
    final kidUnit = bookingArgs['kidUnitPrice'] as int? ?? 0;
    final elderUnit = bookingArgs['elderUnitPrice'] as int? ?? 0;
    final dateMs = bookingArgs['dateMs'] as int?;
    final date = dateMs != null
        ? DateTime.fromMillisecondsSinceEpoch(dateMs)
        : DateTime.now();

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
              MaterialPageRoute(
                builder: (_) => const TicketHistoryScreen(),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.only(right: 20),
              child: Icon(
                Icons.history,
                size: 24,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          _TicketCard(
            ticketId: ticketId,
            date: _formatDate(date),
            adultCount: adultCount,
            kidCount: kidCount,
            elderCount: elderCount,
            adultUnit: adultUnit,
            kidUnit: kidUnit,
            elderUnit: elderUnit,
            totalAmount: totalAmount,
            onQrTap: () => _showQrSheet(context, ticketId),
          ),
        ],
      ),
      bottomNavigationBar: ZooBottomNav(currentIndex: 2),
    );
  }
}

// ── Ticket Card ───────────────────────────────────────────────────────────────

class _TicketCard extends StatelessWidget {
  final String ticketId;
  final String date;
  final int adultCount;
  final int kidCount;
  final int elderCount;
  final int adultUnit;
  final int kidUnit;
  final int elderUnit;
  final int totalAmount;
  final VoidCallback onQrTap;

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
    required this.onQrTap,
  });

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
          // Ticket icon
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

          // Ticket ID row
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
                      '#$ticketId',
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

          // Ticket items
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

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Divider(height: 1, color: AppColors.background, thickness: 1.5),
          ),

          // Total amount
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

          // Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Text(
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

// ── Ticket Item Row ───────────────────────────────────────────────────────────

class _TicketItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final int unitPrice;

  const _TicketItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.unitPrice,
  });

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

// ── Ticket QR Bottom Sheet ────────────────────────────────────────────────────

class _TicketQrSheet extends StatelessWidget {
  final String ticketId;

  const _TicketQrSheet({required this.ticketId});

  @override
  Widget build(BuildContext context) {
    final qrData = 'ZOOPERNOVA-TICKET:$ticketId';
    // Fill available width: screen - sheet horizontal padding (24*2) - container padding (20*2)
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
