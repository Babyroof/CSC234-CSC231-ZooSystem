import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'package:zoopernova_zoo_system/core/widgets/sidebarAdmin.dart';
import 'package:zoopernova_zoo_system/core/widgets/adminTopHeader.dart';

// ---------------------------------------------------------------------------
// Service

class MapAdminService {
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

  Future<String> uploadMap(List<int> bytes, String extension) async {
    // TODO: Upload to Firebase Storage at 'maps/zoo_map.<ext>', then call saveMapUrl(downloadUrl)
    const mockUrl = '';
    await saveMapUrl(mockUrl);
    return mockUrl;
  }
}

final mapAdminServiceProvider = Provider<MapAdminService>(
  (ref) => MapAdminService(),
);

// ---------------------------------------------------------------------------
// State + Notifier

class MapAdminState {
  const MapAdminState({
    this.isLoading = true,
    this.isSaving = false,
    this.mapUrl,
  });

  final bool isLoading;
  final bool isSaving;
  final String? mapUrl;

  MapAdminState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? mapUrl,
    bool clearMapUrl = false,
  }) {
    return MapAdminState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      mapUrl: clearMapUrl ? null : (mapUrl ?? this.mapUrl),
    );
  }
}

class MapAdminNotifier extends StateNotifier<MapAdminState> {
  MapAdminNotifier(this._service) : super(const MapAdminState()) {
    _load();
  }

  final MapAdminService _service;

  Future<void> _load() async {
    final url = await _service.getMapUrl();
    state = state.copyWith(
      isLoading: false,
      mapUrl: url,
      clearMapUrl: url == null,
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
}

final mapAdminProvider = StateNotifierProvider<MapAdminNotifier, MapAdminState>(
  (ref) {
    return MapAdminNotifier(ref.watch(mapAdminServiceProvider));
  },
);

// ---------------------------------------------------------------------------
// Screen

class MapAdminScreen extends ConsumerWidget {
  const MapAdminScreen({super.key});

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
          .read(mapAdminProvider.notifier)
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
    final state = ref.watch(mapAdminProvider);

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
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: state.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _MapContent(
                                mapUrl: state.mapUrl,
                                isSaving: state.isSaving,
                                onUpload: () => _pickAndUpload(context, ref),
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

class _MapContent extends StatelessWidget {
  const _MapContent({
    required this.mapUrl,
    required this.isSaving,
    required this.onUpload,
  });

  final String? mapUrl;
  final bool isSaving;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (mapUrl != null && mapUrl!.isNotEmpty)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: mapUrl!,
                fit: BoxFit.contain,
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
          ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.map_outlined,
                size: 48,
                color: AppColors.adminTextMuted,
              ),
              const SizedBox(height: 12),
              const Text(
                'Upload your map from your device',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.adminTextMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Supported formats: PNG, PDF',
                style: TextStyle(fontSize: 13, color: AppColors.adminTextMuted),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : onUpload,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.upload_outlined, size: 20),
                  label: const Text('Upload Map'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
