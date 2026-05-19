import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/booking_entity.dart';
import '../providers/booking_providers.dart';

final _countdownProvider =
    StateNotifierProvider.autoDispose<_CountdownNotifier, int>(
      (_) => _CountdownNotifier(180),
    );

class _CountdownNotifier extends StateNotifier<int> {
  _CountdownNotifier(super.seconds) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state > 0) {
        state--;
      } else {
        _timer?.cancel();
      }
    });
  }

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class PaymentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> bookingArgs;

  const PaymentScreen({super.key, this.bookingArgs = const {}});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String? _qrCodeBase64;
  bool _isLoadingCharge = true;
  bool _navigated = false;
  StreamSubscription<BookingEntity?>? _bookingSub;

  int get _totalAmount => widget.bookingArgs['totalAmount'] as int? ?? 0;

  @override
  void initState() {
    super.initState();
    _initPayment();
  }

  Future<void> _initPayment() async {
    final bookingId = widget.bookingArgs['bookingId'] as String?;
    if (bookingId == null || bookingId.isEmpty) {
      setState(() => _isLoadingCharge = false);
      return;
    }

    try {
      final result = await ref
          .read(createPaymentChargeUseCaseProvider)
          .call(bookingId: bookingId, amount: _totalAmount);
      try {
        await ref
            .read(updateChargeIdUseCaseProvider)
            .call(bookingId: bookingId, chargeId: result.chargeId);
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingCharge = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save charge ID: $e')),
          );
        }
        return;
      }
      if (mounted) {
        setState(() {
          _qrCodeBase64 = result.qrCodeBase64;
          _isLoadingCharge = false;
        });
      }
      _bookingSub = ref
          .read(watchBookingUseCaseProvider)
          .call(bookingId)
          .listen((booking) {
            if (booking?.status == 'Done' && !_navigated && mounted) {
              _navigated = true;
              context.push('/ticket');
            }
          });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCharge = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Payment setup failed: $e')));
      }
    }
  }

  Future<void> _onCountdownExpired() async {
    final bookingId = widget.bookingArgs['bookingId'] as String?;
    if (bookingId == null || bookingId.isEmpty) return;
    await _bookingSub?.cancel();
    _bookingSub = null;
    try {
      await ref
          .read(updateBookingStatusUseCaseProvider)
          .call(bookingId: bookingId, status: 'Cancelled');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to cancel booking: $e')));
      }
    }
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _bookingSub?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final seconds = ref.watch(_countdownProvider);
    final refId = widget.bookingArgs['bookingId'] as String? ?? '';
    final isExpired = seconds == 0;
    final timeLabel = _formatTime(seconds);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    ref.listen<int>(_countdownProvider, (prev, next) {
      if (prev != null && prev > 0 && next == 0) {
        _onCountdownExpired();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'QR Payment',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          const Text(
            'Time Remaining',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeLabel,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: isExpired ? AppColors.grey : AppColors.black,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.qr_code_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'ZooPernova\nPayment',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              '฿ $_totalAmount',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (isExpired)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 2,
                                ),
                              ),
                              child: const SizedBox(
                                width: 180,
                                height: 180,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.timer_off_outlined,
                                      size: 48,
                                      color: AppColors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'QR Expired',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        color: AppColors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: _isLoadingCharge || _qrCodeBase64 == null
                                  ? const SizedBox(
                                      width: double.infinity,
                                      height: 300,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : SizedBox(
                                      width: double.infinity,
                                      height: 300,
                                      child: SvgPicture.memory(
                                        Uint8List.fromList(
                                          base64Decode(_qrCodeBase64!),
                                        ),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                            ),
                          const SizedBox(height: 16),
                          const Text(
                            'Scan QR to complete payment',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'ZOOPERNOVA ZOO',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ref. ID: $refId',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPad + 16),
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
                          'Payment Status',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isExpired ? 'Expired' : 'Checking...',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isExpired
                                ? AppColors.change
                                : AppColors.black,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Time Remaining',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeLabel,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.black,
                            side: const BorderSide(
                              color: AppColors.grey,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => context.push('/ticket'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Done Payment',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ),
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
