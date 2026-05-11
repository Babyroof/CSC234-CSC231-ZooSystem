import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isDetecting = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isDetecting) return;
    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    if (barcode?.rawValue == null) return;

    setState(() => _isDetecting = false);
    _controller.stop();
    _showResultSheet(barcode!.rawValue!);
  }

  void _showResultSheet(String value) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.qr_code_2, color: AppColors.primary, size: 24),
                SizedBox(width: 8),
                Text(
                  'QR Code Detected',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _isDetecting = true);
                      _controller.start();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Scan Again',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;
    final result = await _controller.analyzeImage(image.path);
    if (result == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No QR Code found in this image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // Dark overlay + viewfinder
          CustomPaint(
            painter: _QrOverlayPainter(),
            child: const SizedBox.expand(),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'Scan QR Code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _controller.toggleTorch(),
                    icon: const Icon(
                      Icons.flash_on_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Align QR code within the frame',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _pickFromGallery,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Choose from Gallery',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
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

class _QrOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const scanSize = 260.0;
    const cornerLength = 32.0;
    const cornerWidth = 4.0;

    final center = Offset(size.width / 2, size.height / 2);
    final scanRect = Rect.fromCenter(
      center: center,
      width: scanSize,
      height: scanSize,
    );

    // Semi-transparent overlay
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(
          RRect.fromRectAndRadius(scanRect, const Radius.circular(12)),
        ),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    // Corner markers (L-shaped, สีเขียว)
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerWidth
      ..strokeCap = StrokeCap.round;

    final l = scanRect.left;
    final t = scanRect.top;
    final r = scanRect.right;
    final b = scanRect.bottom;

    // Top-left
    canvas.drawLine(Offset(l, t + cornerLength), Offset(l, t + 4), paint);
    canvas.drawLine(Offset(l + 4, t), Offset(l + cornerLength, t), paint);
    // Top-right
    canvas.drawLine(Offset(r - cornerLength, t), Offset(r - 4, t), paint);
    canvas.drawLine(Offset(r, t + 4), Offset(r, t + cornerLength), paint);
    // Bottom-left
    canvas.drawLine(Offset(l, b - cornerLength), Offset(l, b - 4), paint);
    canvas.drawLine(Offset(l + 4, b), Offset(l + cornerLength, b), paint);
    // Bottom-right
    canvas.drawLine(Offset(r - cornerLength, b), Offset(r - 4, b), paint);
    canvas.drawLine(Offset(r, b - cornerLength), Offset(r, b - 4), paint);
  }

  @override
  bool shouldRepaint(_QrOverlayPainter oldDelegate) => false;
}
