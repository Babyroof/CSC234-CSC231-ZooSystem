import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/zoo_bottom_nav.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

// ── Provider ─────────────────────────────────────────────────────────────────

final _bookingHistoryProvider = StreamProvider.autoDispose<List<BookingModel>>(
  (ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return BookingService().getPastBookings(uid);
  },
);

// ── Screen ───────────────────────────────────────────────────────────────────

class TicketHistoryScreen extends ConsumerWidget {
  const TicketHistoryScreen({super.key});

  void _showQrSheet(BuildContext context, String bookingId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TicketQrSheet(bookingId: bookingId),
    );
  }

  String _formatDate(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[d.weekday - 1]}, ${d.day.toString().padLeft(2, '0')}/${months[d.month - 1]}/${d.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_bookingHistoryProvider);

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
          'History',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load history',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.grey,
            ),
          ),
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(
              child: Text(
                'No booking history yet.',
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
              final shortId = booking.id.length > 8
                  ? booking.id.substring(0, 8).toUpperCase()
                  : booking.id.toUpperCase();
              return _HistoryCard(
                ticketId: shortId,
                date: _formatDate(booking.date),
                amount: booking.totalPrice ?? booking.totalAmount,
                status: booking.status,
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

// ── History Card ──────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final String ticketId;
  final String date;
  final int amount;
  final String status;
  final VoidCallback onQrTap;

  const _HistoryCard({
    required this.ticketId,
    required this.date,
    required this.amount,
    required this.status,
    required this.onQrTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = status.toLowerCase() == 'pending';
    final statusColor = isPending ? AppColors.grey : AppColors.primary;
    final statusIcon = isPending
        ? Icons.hourglass_empty_outlined
        : Icons.check_circle_outline;
    final statusLabel = isPending ? 'Pending' : 'Paid by QR Code';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ticket icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.confirmation_num_rounded,
              size: 34,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#$ticketId',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: onQrTap,
                      child: const Icon(
                        Icons.qr_code_scanner,
                        size: 24,
                        color: AppColors.black,
                      ),
                    ),
                  ],
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
                const SizedBox(height: 4),
                Text(
                  '฿$amount',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Status',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(statusIcon, size: 15, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ticket QR Bottom Sheet ────────────────────────────────────────────────────

class _TicketQrSheet extends StatelessWidget {
  final String bookingId;

  const _TicketQrSheet({required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final qrData = 'ZOOPERNOVA-TICKET:$bookingId';

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
            '#${bookingId.length > 8 ? bookingId.substring(0, 8).toUpperCase() : bookingId.toUpperCase()}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
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
              size: 200,
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
