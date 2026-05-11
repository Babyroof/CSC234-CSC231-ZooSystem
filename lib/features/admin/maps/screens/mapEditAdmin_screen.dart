import 'dart:math';
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
    this.pictureUrl,
  });

  final String itemId;
  final bool isAnimal;
  final String name;
  final int x;
  final int y;
  final String? pictureUrl;
}

// ---------------------------------------------------------------------------
// Screen

class MapEditAdminScreen extends ConsumerStatefulWidget {
  const MapEditAdminScreen({super.key, required this.args});

  final MapEditArgs args;

  @override
  ConsumerState<MapEditAdminScreen> createState() => _MapEditAdminScreenState();
}

class _MapEditAdminScreenState extends ConsumerState<MapEditAdminScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _mapUrl;
  List<MapPinModel> _otherPins = [];
  late int _editX;
  late int _editY;
  Size? _canvasSize;

  late final TransformationController _transformController;
  late final AnimationController _animController;
  Animation<Matrix4>? _animMatrix;

  @override
  void initState() {
    super.initState();
    _editX = widget.args.x;
    _editY = widget.args.y;
    _transformController = TransformationController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(() {
        if (_animMatrix != null) {
          _transformController.value = _animMatrix!.value;
        }
      });
    _loadData();
  }

  @override
  void dispose() {
    _transformController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _zoomToPin() {
    if (_canvasSize == null) return;
    const scale = 2.5;
    final tx = _canvasSize!.width / 2 - scale * widget.args.x;
    final ty = _canvasSize!.height / 2 - scale * widget.args.y;
    final target = Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
    _animMatrix = Matrix4Tween(
      begin: Matrix4.identity(),
      end: target,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubic),
    );
    _animController.forward(from: 0);
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _zoomToPin();
    });
  }

  Future<void> _onMapTap(Offset local) async {
    if (_isSaving) return;

    final newX = local.dx.round();
    final newY = local.dy.round();

    setState(() {
      _editX = newX;
      _editY = newY;
    });

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => MapConfirmDialog(x: newX, y: newY),
    );

    if (confirmed != true) {
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
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, size: 14),
                      label: const Text('Back to Map'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.adminPrimary,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        _canvasSize = Size(
                                          constraints.maxWidth,
                                          constraints.maxHeight,
                                        );
                                        return _MapEditCanvas(
                                          controller: _transformController,
                                          mapUrl: _mapUrl,
                                          otherPins: _otherPins,
                                          editX: _editX,
                                          editY: _editY,
                                          editPictureUrl: widget.args.pictureUrl,
                                          isSaving: _isSaving,
                                          onTap: _onMapTap,
                                        );
                                      },
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
    required this.controller,
    required this.mapUrl,
    required this.otherPins,
    required this.editX,
    required this.editY,
    required this.editPictureUrl,
    required this.isSaving,
    required this.onTap,
  });

  final TransformationController controller;
  final String? mapUrl;
  final List<MapPinModel> otherPins;
  final int editX;
  final int editY;
  final String? editPictureUrl;
  final bool isSaving;
  final void Function(Offset local) onTap;

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
      child: InteractiveViewer(
        transformationController: controller,
        constrained: false,
        minScale: 0.1,
        maxScale: 5.0,
        boundaryMargin: const EdgeInsets.all(2000),
        child: GestureDetector(
          onTapDown: (details) => onTap(details.localPosition),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: mapUrl!,
                placeholder: (_, _) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (_, _, _) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: AppColors.adminTextMuted,
                  ),
                ),
              ),
              // Other pins — fluid-scaled circular images
              ...otherPins.map(
                (pin) => Positioned(
                  left: pin.x.toDouble() - 20,
                  top: pin.y.toDouble() - 20,
                  child: Tooltip(
                    message: pin.name,
                    child: AnimatedBuilder(
                      animation: controller,
                      builder: (_, _) {
                        final scale = controller.value.getMaxScaleOnAxis();
                        final r = (20.0 / sqrt(scale)).clamp(6.0, 36.0);
                        return MapAdminPinAvatar(
                          pictureUrl: pin.pictureUrl,
                          highlighted: false,
                          radius: r,
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Editing pin — fluid-scaled + highlighted
              Positioned(
                left: editX.toDouble() - 20,
                top: editY.toDouble() - 20,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: isSaving ? 0.6 : 1.0,
                    child: AnimatedBuilder(
                      animation: controller,
                      builder: (_, _) {
                        final scale = controller.value.getMaxScaleOnAxis();
                        final r = (20.0 / sqrt(scale)).clamp(6.0, 36.0);
                        return MapAdminPinAvatar(
                          pictureUrl: editPictureUrl,
                          highlighted: true,
                          radius: r,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
