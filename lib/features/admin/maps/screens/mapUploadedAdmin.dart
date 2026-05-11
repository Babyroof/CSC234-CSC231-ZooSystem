import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'package:zoopernova_zoo_system/core/widgets/sidebarAdmin.dart';
import 'package:zoopernova_zoo_system/core/widgets/adminTopHeader.dart';

// ---------------------------------------------------------------------------
// Model

class MapPinModel {
  const MapPinModel({
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
// Service

class MapUploadedService {
  // TODO: Inject FirebaseFirestore and FirebaseStorage — replace all methods with real calls
  String? _mapUrl;

  Future<String?> getMapUrl() async {
    // TODO: _db.collection('config').doc('map').get() → return data['mapUrl']
    return _mapUrl;
  }

  Future<void> saveMapUrl(String url) async {
    // TODO: _db.collection('config').doc('map').set({'mapUrl': url}, SetOptions(merge: true))
    _mapUrl = url;
  }

  Future<List<MapPinModel>> getPins() async {
    // TODO: Query 'animal' and 'event' collections, return pins with location_x / location_y
    return const [
      MapPinModel(
        itemId: 'mock_1',
        isAnimal: true,
        name: 'Scarlet Macaw',
        x: 200,
        y: 150,
      ),
      MapPinModel(
        itemId: 'mock_2',
        isAnimal: true,
        name: 'African Elephant',
        x: 500,
        y: 300,
      ),
      MapPinModel(
        itemId: 'mock_3',
        isAnimal: true,
        name: 'Bottlenose Dolphin',
        x: 700,
        y: 600,
      ),
      MapPinModel(
        itemId: 'mock_4',
        isAnimal: false,
        name: 'Smart Seal Show',
        x: 300,
        y: 400,
      ),
      MapPinModel(
        itemId: 'mock_5',
        isAnimal: false,
        name: 'Elephant Bathing',
        x: 600,
        y: 250,
      ),
    ];
  }

  Future<String> uploadMap(List<int> bytes, String extension) async {
    // TODO: Upload to Firebase Storage at 'maps/zoo_map.<ext>', then call saveMapUrl(downloadUrl)
    const mockUrl = '';
    await saveMapUrl(mockUrl);
    return mockUrl;
  }

  Future<void> updateLocation(String id, bool isAnimal, int x, int y) async {
    // TODO: final col = isAnimal ? 'animal' : 'event'; _db.collection(col).doc(id).update({'location_x': x, 'location_y': y})
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

class MapUploadedAdminScreen extends ConsumerWidget {
  const MapUploadedAdminScreen({super.key});

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
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
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading map: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                                    child: _MapCanvas(
                                      mapUrl: state.mapUrl,
                                      pins: state.pins,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: SizedBox(
                                      width: 120,
                                      height: 44,
                                      child: ElevatedButton(
                                        onPressed: state.isSaving
                                            ? null
                                            : () =>
                                                  _pickAndUpload(context, ref),
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
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        child: state.isSaving
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Text('Edit'),
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

class _MapCanvas extends StatelessWidget {
  const _MapCanvas({required this.mapUrl, required this.pins});

  final String? mapUrl;
  final List<MapPinModel> pins;

  // Coordinate space assumed when admins set location_x / location_y
  static const double _coordMax = 1000.0;

  @override
  Widget build(BuildContext context) {
    if (mapUrl == null || mapUrl!.isEmpty) {
      return const Center(
        child: Text(
          'No map uploaded yet',
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

          return Stack(
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
              ...pins.map(
                (pin) => Positioned(
                  left: (pin.x / _coordMax) * w - 14,
                  top: (pin.y / _coordMax) * h - 28,
                  child: Tooltip(
                    message: pin.name,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
  });

  final int initialX;
  final int initialY;

  @override
  ConsumerState<MapLocationPickerDialog> createState() =>
      _MapLocationPickerDialogState();
}

class _MapLocationPickerDialogState
    extends ConsumerState<MapLocationPickerDialog> {
  String? _mapUrl;
  bool _loading = true;
  late int _x;
  late int _y;

  static const double _coordMax = 1000.0;

  @override
  void initState() {
    super.initState();
    _x = widget.initialX;
    _y = widget.initialY;
    _loadMap();
  }

  Future<void> _loadMap() async {
    final url = await ref.read(mapUploadedServiceProvider).getMapUrl();
    if (mounted)
      setState(() {
        _mapUrl = url;
        _loading = false;
      });
  }

  void _onTap(Offset local, Size size) {
    final newX = ((local.dx / size.width) * _coordMax).round().clamp(0, 1000);
    final newY = ((local.dy / size.height) * _coordMax).round().clamp(0, 1000);
    setState(() {
      _x = newX;
      _y = newY;
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
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LayoutBuilder(
                          builder: (ctx, constraints) {
                            final w = constraints.maxWidth;
                            final h = constraints.maxHeight;
                            return GestureDetector(
                              onTapDown: (d) =>
                                  _onTap(d.localPosition, Size(w, h)),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: CachedNetworkImage(
                                      imageUrl: _mapUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (_, __, ___) => const Center(
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          size: 64,
                                          color: AppColors.adminTextMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: (_x / _coordMax) * w - 14,
                                    top: (_y / _coordMax) * h - 28,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 32,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
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
