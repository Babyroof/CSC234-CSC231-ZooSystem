import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'mapUploadedAdmin.dart';
import 'mapConfirmAdmin_screen.dart';
import 'package:zoopernova_zoo_system/core/widgets/sidebarAdmin.dart';
import 'package:zoopernova_zoo_system/core/widgets/adminTopHeader.dart';

// ---------------------------------------------------------------------------
// Navigation arguments

class MapEditArgs {
  const MapEditArgs({
    required this.itemId,
    required this.isAnimal,
    required this.name,
    required this.x,
    required this.y,
  });

  final String itemId;
  final bool isAnimal;
  final String name;
  final int x;
  final int y;
}

// ---------------------------------------------------------------------------
// Screen

class MapEditAdminScreen extends ConsumerStatefulWidget {
  const MapEditAdminScreen({super.key, required this.args});

  final MapEditArgs args;

  @override
  ConsumerState<MapEditAdminScreen> createState() => _MapEditAdminScreenState();
}

class _MapEditAdminScreenState extends ConsumerState<MapEditAdminScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _mapUrl;
  List<MapPinModel> _otherPins = [];
  late int _editX;
  late int _editY;

  @override
  void initState() {
    super.initState();
    _editX = widget.args.x;
    _editY = widget.args.y;
    _loadData();
  }

  Future<void> _loadData() async {
    final service = ref.read(mapUploadedServiceProvider);
    final results = await Future.wait([service.getMapUrl(), service.getPins()]);
    final allPins = results[1] as List<MapPinModel>;

    setState(() {
      _mapUrl = results[0] as String?;
      _otherPins = allPins
          .where((p) => p.itemId != widget.args.itemId)
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _onMapTap(Offset local, Size canvasSize) async {
    if (_isSaving) return;

    final newX = ((local.dx / canvasSize.width) * 1000).round().clamp(0, 1000);
    final newY = ((local.dy / canvasSize.height) * 1000).round().clamp(0, 1000);

    // Preview the pin at the tapped position
    setState(() {
      _editX = newX;
      _editY = newY;
    });

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => MapConfirmDialog(x: newX, y: newY),
    );

    if (confirmed != true) {
      // Revert preview back to last saved position
      setState(() {
        _editX = widget.args.x;
        _editY = widget.args.y;
      });
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(mapUploadedServiceProvider)
          .updateLocation(widget.args.itemId, widget.args.isAnimal, newX, newY);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving position: $e')));
        setState(() {
          _editX = widget.args.x;
          _editY = widget.args.y;
        });
      }
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
          const AdminSidebar(activeIndex: 3),
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
                    const AdminTopHeader(title: 'Map Management'),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                children: [
                                  Expanded(
                                    child: _MapEditCanvas(
                                      mapUrl: _mapUrl,
                                      otherPins: _otherPins,
                                      editX: _editX,
                                      editY: _editY,
                                      isSaving: _isSaving,
                                      onTap: _onMapTap,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isSaving) ...[
                                        const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.adminPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(
                                        _isSaving
                                            ? 'Saving . . .'
                                            : 'Move your pin to new location . . .',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: AppColors.adminTextDark,
                                        ),
                                      ),
                                    ],
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

// ---------------------------------------------------------------------------

class _MapEditCanvas extends StatelessWidget {
  const _MapEditCanvas({
    required this.mapUrl,
    required this.otherPins,
    required this.editX,
    required this.editY,
    required this.isSaving,
    required this.onTap,
  });

  final String? mapUrl;
  final List<MapPinModel> otherPins;
  final int editX;
  final int editY;
  final bool isSaving;
  final void Function(Offset local, Size canvasSize) onTap;

  static const double _coordMax = 1000.0;

  @override
  Widget build(BuildContext context) {
    if (mapUrl == null || mapUrl!.isEmpty) {
      return const Center(
        child: Text(
          'No map uploaded',
          style: TextStyle(color: AppColors.adminTextMuted, fontSize: 16),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final canvasSize = Size(w, h);

          return GestureDetector(
            onTapDown: (details) => onTap(details.localPosition, canvasSize),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: mapUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 64,
                        color: AppColors.adminTextMuted,
                      ),
                    ),
                  ),
                ),
                // Other pins — black
                ...otherPins.map(
                  (pin) => Positioned(
                    left: (pin.x / _coordMax) * w - 14,
                    top: (pin.y / _coordMax) * h - 28,
                    child: Tooltip(
                      message: pin.name,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.black87,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                // Edited pin — red
                Positioned(
                  left: (editX / _coordMax) * w - 14,
                  top: (editY / _coordMax) * h - 28,
                  child: IgnorePointer(
                    child: Icon(
                      Icons.location_on,
                      color: isSaving ? Colors.red.shade300 : Colors.red,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
