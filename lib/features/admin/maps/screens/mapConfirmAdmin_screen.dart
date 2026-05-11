import 'package:flutter/material.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';

class MapConfirmDialog extends StatelessWidget {
  const MapConfirmDialog({super.key, required this.x, required this.y});

  final int x;
  final int y;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 36, 32, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pin icon
              const Icon(Icons.location_on, color: Colors.red, size: 72),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Confirm Edit?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),

              // Coordinates row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CoordCell(label: 'X:', value: '$x'),
                  const SizedBox(width: 36),
                  _CoordCell(label: 'Y:', value: '$y'),
                ],
              ),
              const SizedBox(height: 20),

              // Body text
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.adminTextDark,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: 'Are you sure you want to move to '),
                    TextSpan(
                      text: 'this location',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: '?'),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.adminDanger,
                          width: 1.5,
                        ),
                        foregroundColor: AppColors.adminDanger,
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.adminDanger,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 52),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Edit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoordCell extends StatelessWidget {
  const _CoordCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.adminTextDark,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, color: AppColors.adminTextDark),
        ),
      ],
    );
  }
}
