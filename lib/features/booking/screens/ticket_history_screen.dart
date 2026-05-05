import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/zoo_bottom_nav.dart';

// ── Mock history data ────────────────────────────────────────────────────────

const _mockHistory = [
  {'id': 'TK2847', 'date': 'Tue, 06/May/2026', 'amount': 690},
  {'id': 'TK1293', 'date': 'Sat, 19/Apr/2026', 'amount': 430},
  {'id': 'TK0571', 'date': 'Mon, 07/Apr/2026', 'amount': 190},
  {'id': 'TK3914', 'date': 'Sun, 23/Mar/2026', 'amount': 1050},
  {'id': 'TK0088', 'date': 'Fri, 14/Feb/2026', 'amount': 280},
];

// ── Screen ───────────────────────────────────────────────────────────────────

class TicketHistoryScreen extends StatelessWidget {
  const TicketHistoryScreen({super.key});

  void _showQrSheet(BuildContext context, String ticketId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TicketQrSheet(ticketId: ticketId),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        itemCount: _mockHistory.length,
        separatorBuilder: (context, i) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _mockHistory[index];
          final id = item['id'] as String;
          return _HistoryCard(
            ticketId: id,
            date: item['date'] as String,
            amount: item['amount'] as int,
            onQrTap: () => _showQrSheet(context, id),
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
  final VoidCallback onQrTap;

  const _HistoryCard({
    required this.ticketId,
    required this.date,
    required this.amount,
    required this.onQrTap,
  });

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: 8),
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
                    Icon(
                      Icons.check_circle_outline,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Paid by QR Code',
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
  final String ticketId;

  const _TicketQrSheet({required this.ticketId});

  @override
  Widget build(BuildContext context) {
    final qrData = 'ZOOPERNOVA-TICKET:$ticketId';

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
