import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'package:zoopernova_zoo_system/core/routes/app_routes.dart';
import 'package:zoopernova_zoo_system/core/widgets/sidebarAdmin.dart';
import 'package:zoopernova_zoo_system/core/widgets/adminTopHeader.dart';
import 'mapEditAdmin_screen.dart';

// ---------------------------------------------------------------------------
// Model

class MapPinModel {
  const MapPinModel({
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
// Service

class MapUploadedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> getMapUrl() async {
    final snap = await _db.collection('map').limit(1).get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data()['mapPicture'] as String?;
  }

  Future<void> saveMapUrl(String url) async {
    final snap = await _db.collection('map').limit(1).get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.update({'mapPicture': url});
    } else {
      await _db.collection('map').add({'mapPicture': url});
    }
  }

  Future<List<MapPinModel>> getPins() async {
    final results = await Future.wait([
      _db.collection('animal').get(),
      _db.collection('event').get(),
    ]);

    final pins = <MapPinModel>[];

    for (final doc in results[0].docs) {
      final data = doc.data();
      final lx = data['location_x'];
      final ly = data['location_y'];
      if (lx == null || ly == null) continue;
      pins.add(
        MapPinModel(
          itemId: doc.id,
          isAnimal: true,
          name: data['animalName']?.toString() ?? '',
          x: (lx as num).toInt(),
          y: (ly as num).toInt(),
          pictureUrl: data['animalPicture'] as String?,
        ),
      );
    }

    for (final doc in results[1].docs) {
      final data = doc.data();
      final lx = data['location_x'];
      final ly = data['location_y'];
      if (lx == null || ly == null) continue;
      pins.add(
        MapPinModel(
          itemId: doc.id,
          isAnimal: false,
          name: data['eventName']?.toString() ?? '',
          x: (lx as num).toInt(),
          y: (ly as num).toInt(),
          pictureUrl: data['eventPicture'] as String?,
        ),
      );
    }

    return pins;
  }

  Future<String> uploadMap(List<int> bytes, String extension) async {
    const mimeTypes = {'png': 'image/png', 'pdf': 'application/pdf'};
    final contentType = mimeTypes[extension.toLowerCase()];
    if (contentType == null)
      throw ArgumentError('Only PNG and PDF are supported');
    final ref = _storage.ref().child('maps/zoo_map.$extension');
    final metadata = SettableMetadata(contentType: contentType);
    await ref.putData(Uint8List.fromList(bytes), metadata);
    final downloadUrl = await ref.getDownloadURL();
    await saveMapUrl(downloadUrl);
    return downloadUrl;
  }

  Future<void> updateLocation(String id, bool isAnimal, int x, int y) async {
    if (x < 0 || y < 0) throw ArgumentError('Coordinates must be non-negative');
    final col = isAnimal ? 'animal' : 'event';
    await _db.collection(col).doc(id).update({
      'location_x': x,
      'location_y': y,
    });
  }
}

final mapUploadedServiceProvider = Provider<MapUploadedService>(
  (ref) => MapUploadedService(),
);

// ---------------------------------------------------------------------------
// State + Notifier

class MapUploadedState {
  const MapUploadedState({
    this.isLoading = true,
    this.isSaving = false,
    this.mapUrl,
    this.pins = const [],
  });

  final bool isLoading;
  final bool isSaving;
  final String? mapUrl;
  final List<MapPinModel> pins;

  MapUploadedState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? mapUrl,
    List<MapPinModel>? pins,
  }) {
    return MapUploadedState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      mapUrl: mapUrl ?? this.mapUrl,
      pins: pins ?? this.pins,
    );
  }
}

class MapUploadedNotifier extends StateNotifier<MapUploadedState> {
  MapUploadedNotifier(this._service) : super(const MapUploadedState()) {
    _load();
  }

  final MapUploadedService _service;

  Future<void> _load() async {
    final results = await Future.wait([
      _service.getMapUrl(),
      _service.getPins(),
    ]);
    state = state.copyWith(
      isLoading: false,
      mapUrl: results[0] as String?,
      pins: results[1] as List<MapPinModel>,
    );
  }

  Future<void> uploadMap(List<int> bytes, String extension) async {
    state = state.copyWith(isSaving: true);
    try {
      final url = await _service.uploadMap(bytes, extension);
      state = state.copyWith(isSaving: false, mapUrl: url);
    } catch (_) {
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }

  Future<void> reload() => _load();
}

final mapUploadedProvider =
    StateNotifierProvider<MapUploadedNotifier, MapUploadedState>((ref) {
      return MapUploadedNotifier(ref.watch(mapUploadedServiceProvider));
    });

// ---------------------------------------------------------------------------
// Screen

class MapUploadedAdminScreen extends ConsumerStatefulWidget {
  const MapUploadedAdminScreen({super.key});

  @override
  ConsumerState<MapUploadedAdminScreen> createState() =>
      _MapUploadedAdminScreenState();
}

class _MapUploadedAdminScreenState
    extends ConsumerState<MapUploadedAdminScreen> {
  MapPinModel? _selectedPin;

  Future<void> _pickAndUpload() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'pdf'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    if (file.bytes == null) return;

    try {
      await ref
          .read(mapUploadedProvider.notifier)
          .uploadMap(file.bytes!, file.extension ?? 'png');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading map: $e')));
      }
    }
  }

  Future<void> _navigateToEdit(MapPinModel pin) async {
    setState(() => _selectedPin = null);
    await context.push(
      AppRoute.adminMapEdit,
      extra: MapEditArgs(
        itemId: pin.itemId,
        isAnimal: pin.isAnimal,
        name: pin.name,
        x: pin.x,
        y: pin.y,
        pictureUrl: pin.pictureUrl,
      ),
    );
    if (mounted) ref.read(mapUploadedProvider.notifier).reload();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapUploadedProvider);

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
                        child: state.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        _MapCanvas(
                                          mapUrl: state.mapUrl,
                                          pins: state.pins,
                                          onPinTap: (pin) => setState(
                                            () => _selectedPin = pin,
                                          ),
                                        ),
                                        if (_selectedPin != null)
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: _MapPinInfoCard(
                                              pin: _selectedPin!,
                                              onClose: () => setState(
                                                () => _selectedPin = null,
                                              ),
                                              onEditTap: () => _navigateToEdit(
                                                _selectedPin!,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: SizedBox(
                                      width: 160,
                                      height: 44,
                                      child: ElevatedButton.icon(
                                        onPressed: state.isSaving
                                            ? null
                                            : _pickAndUpload,
                                        icon: state.isSaving
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.upload_outlined,
                                                size: 18,
                                              ),
                                        label: Text(
                                          state.mapUrl != null &&
                                                  state.mapUrl!.isNotEmpty
                                              ? 'Change Map'
                                              : 'Upload Map',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.adminPrimary,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
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

// ---------------------------------------------------------------------------

class _MapCanvas extends StatefulWidget {
  const _MapCanvas({
    required this.mapUrl,
    required this.pins,
    required this.onPinTap,
  });

  final String? mapUrl;
  final List<MapPinModel> pins;
  final void Function(MapPinModel pin) onPinTap;

  @override
  State<_MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<_MapCanvas> with TickerProviderStateMixin {
  final _controller = TransformationController();
  late final AnimationController _animController;
  Animation<Matrix4>? _animMatrix;
  Size? _canvasSize;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1200),
        )..addListener(() {
          if (_animMatrix != null) {
            _controller.value = _animMatrix!.value;
          }
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _zoomToCenter() async {
    final url = widget.mapUrl;
    if (url == null || _canvasSize == null) return;

    Size imageSize = Size.zero;
    try {
      final completer = Completer<Size>();
      NetworkImage(url)
          .resolve(ImageConfiguration.empty)
          .addListener(
            ImageStreamListener(
              (info, _) {
                if (!completer.isCompleted) {
                  completer.complete(
                    Size(
                      info.image.width.toDouble(),
                      info.image.height.toDouble(),
                    ),
                  );
                }
              },
              onError: (_, _) {
                if (!completer.isCompleted) completer.complete(Size.zero);
              },
            ),
          );
      imageSize = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => Size.zero,
      );
    } catch (_) {}

    if (!mounted) return;

    final Matrix4 target;
    if (imageSize.width > 0 && imageSize.height > 0) {
      final s =
          min(
            _canvasSize!.width / imageSize.width,
            _canvasSize!.height / imageSize.height,
          ) *
          0.85;
      final tx = _canvasSize!.width / 2 - s * imageSize.width / 2;
      final ty = _canvasSize!.height / 2 - s * imageSize.height / 2;
      target = Matrix4.identity()
        ..translate(tx, ty)
        ..scale(s);
    } else {
      target = Matrix4.identity();
    }

    final initial = Matrix4.identity()..scale(2.0);
    _animMatrix = Matrix4Tween(begin: initial, end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutQuart),
    );
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mapUrl == null || widget.mapUrl!.isEmpty) {
      return const Center(
        child: Text(
          'No map uploaded yet',
          style: TextStyle(color: AppColors.adminTextMuted, fontSize: 16),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        if (!_hasAnimated) {
          _hasAnimated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _zoomToCenter();
          });
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: InteractiveViewer(
            transformationController: _controller,
            constrained: false,
            minScale: 0.1,
            maxScale: 5.0,
            boundaryMargin: const EdgeInsets.all(2000),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: widget.mapUrl!,
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
                ...widget.pins.map(
                  (pin) => Positioned(
                    left: pin.x.toDouble() - 20,
                    top: pin.y.toDouble() - 20,
                    child: GestureDetector(
                      onTap: () => widget.onPinTap(pin),
                      child: Tooltip(
                        message: pin.name,
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (_, _) {
                            final scale = _controller.value.getMaxScaleOnAxis();
                            final r = (25.0 / sqrt(scale)).clamp(6.0, 50.0);
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shared circular pin widget used by both canvas and edit screen

class MapAdminPinAvatar extends StatelessWidget {
  const MapAdminPinAvatar({
    super.key,
    required this.pictureUrl,
    required this.highlighted,
    this.radius = 16.0,
  });

  final String? pictureUrl;
  final bool highlighted;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(highlighted ? 3 : 2),
      decoration: BoxDecoration(
        color: highlighted ? Colors.redAccent : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: highlighted
                ? Colors.redAccent.withValues(alpha: 0.55)
                : Colors.black26,
            blurRadius: highlighted ? 14 : 4,
            spreadRadius: highlighted ? 4 : 1,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: (pictureUrl != null && pictureUrl!.isNotEmpty)
            ? NetworkImage(pictureUrl!)
            : null,
        child: (pictureUrl == null || pictureUrl!.isEmpty)
            ? Icon(Icons.pets, size: radius * 0.9, color: Colors.grey)
            : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------

// Reusable map location picker dialog — used by animal & event admin screens.
class MapLocationPickerDialog extends ConsumerStatefulWidget {
  const MapLocationPickerDialog({
    super.key,
    required this.initialX,
    required this.initialY,
    this.pictureUrl,
  });

  final int initialX;
  final int initialY;
  final String? pictureUrl;

  @override
  ConsumerState<MapLocationPickerDialog> createState() =>
      _MapLocationPickerDialogState();
}

class _MapLocationPickerDialogState
    extends ConsumerState<MapLocationPickerDialog>
    with TickerProviderStateMixin {
  final _controller = TransformationController();
  late final AnimationController _animController;
  Animation<Matrix4>? _animMatrix;
  Size? _canvasSize;

  String? _mapUrl;
  bool _loading = true;
  late int _x;
  late int _y;

  @override
  void initState() {
    super.initState();
    _x = widget.initialX;
    _y = widget.initialY;
    _animController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 900),
        )..addListener(() {
          if (_animMatrix != null) {
            _controller.value = _animMatrix!.value;
          }
        });
    _loadMap();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadMap() async {
    final url = await ref.read(mapUploadedServiceProvider).getMapUrl();
    if (mounted) {
      setState(() {
        _mapUrl = url;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _zoomOnOpen();
      });
    }
  }

  void _zoomOnOpen() {
    if (_mapUrl == null || _canvasSize == null) return;
    if (widget.initialX > 0 || widget.initialY > 0) {
      _zoomToPin(widget.initialX.toDouble(), widget.initialY.toDouble());
    } else {
      _zoomToCenter();
    }
  }

  void _zoomToPin(double px, double py) {
    if (_canvasSize == null) return;
    const scale = 2.5;
    final tx = _canvasSize!.width / 2 - scale * px;
    final ty = _canvasSize!.height / 2 - scale * py;
    final target = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);
    _animController.duration = const Duration(milliseconds: 800);
    _animMatrix = Matrix4Tween(begin: Matrix4.identity(), end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubic),
    );
    _animController.forward(from: 0);
  }

  Future<void> _zoomToCenter() async {
    final url = _mapUrl;
    if (url == null || _canvasSize == null) return;

    Size imageSize = Size.zero;
    try {
      final completer = Completer<Size>();
      NetworkImage(url)
          .resolve(ImageConfiguration.empty)
          .addListener(
            ImageStreamListener(
              (info, _) {
                if (!completer.isCompleted) {
                  completer.complete(
                    Size(
                      info.image.width.toDouble(),
                      info.image.height.toDouble(),
                    ),
                  );
                }
              },
              onError: (_, _) {
                if (!completer.isCompleted) completer.complete(Size.zero);
              },
            ),
          );
      imageSize = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => Size.zero,
      );
    } catch (_) {}

    if (!mounted) return;

    final Matrix4 target;
    if (imageSize.width > 0 && imageSize.height > 0) {
      final s =
          min(
            _canvasSize!.width / imageSize.width,
            _canvasSize!.height / imageSize.height,
          ) *
          0.85;
      final tx = _canvasSize!.width / 2 - s * imageSize.width / 2;
      final ty = _canvasSize!.height / 2 - s * imageSize.height / 2;
      target = Matrix4.identity()
        ..translate(tx, ty)
        ..scale(s);
    } else {
      target = Matrix4.identity();
    }

    final initial = Matrix4.identity()..scale(2.0);
    _animController.duration = const Duration(milliseconds: 1200);
    _animMatrix = Matrix4Tween(begin: initial, end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutQuart),
    );
    _animController.forward(from: 0);
  }

  void _onTap(Offset local) {
    setState(() {
      _x = local.dx.round();
      _y = local.dy.round();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set Location on Map',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap on the map to place the pin  •  X: $_x  Y: $_y',
                style: const TextStyle(
                  color: AppColors.adminTextMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (_mapUrl == null || _mapUrl!.isEmpty)
                    ? const Center(
                        child: Text(
                          'No map uploaded yet. Upload a map first.',
                          style: TextStyle(color: AppColors.adminTextMuted),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          _canvasSize = Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: InteractiveViewer(
                              transformationController: _controller,
                              constrained: false,
                              minScale: 0.1,
                              maxScale: 5.0,
                              boundaryMargin: const EdgeInsets.all(2000),
                              child: GestureDetector(
                                onTapDown: (d) => _onTap(d.localPosition),
                                child: Stack(
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: _mapUrl!,
                                      placeholder: (_, _) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (_, _, _) => const Center(
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          size: 64,
                                          color: AppColors.adminTextMuted,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: _x.toDouble() - 20,
                                      top: _y.toDouble() - 20,
                                      child: IgnorePointer(
                                        child: AnimatedBuilder(
                                          animation: _controller,
                                          builder: (_, _) {
                                            final scale = _controller.value
                                                .getMaxScaleOnAxis();
                                            final r = (20.0 / sqrt(scale))
                                                .clamp(6.0, 36.0);
                                            return MapAdminPinAvatar(
                                              pictureUrl: widget.pictureUrl,
                                              highlighted: true,
                                              radius: r,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.adminBorderGreen),
                      foregroundColor: AppColors.adminPrimary,
                      minimumSize: const Size(100, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, (x: _x, y: _y)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminPrimaryDark,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(100, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Confirm'),
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

// ---------------------------------------------------------------------------

class _MapPinInfoCard extends StatelessWidget {
  const _MapPinInfoCard({
    required this.pin,
    required this.onClose,
    required this.onEditTap,
  });

  final MapPinModel pin;
  final VoidCallback onClose;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (pin.pictureUrl != null && pin.pictureUrl!.isNotEmpty)
                  ? Image.network(
                      pin.pictureUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pin.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pin.isAnimal ? 'Animal' : 'Event',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onEditTap,
              icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
              label: const Text('Edit Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 20),
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.pets, color: Colors.grey),
    );
  }
}
