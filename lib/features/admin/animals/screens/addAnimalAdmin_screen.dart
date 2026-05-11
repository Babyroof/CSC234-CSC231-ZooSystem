import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import '../services/animal_admin_service.dart';
import 'package:zoopernova_zoo_system/core/widgets/sidebarAdmin.dart';
import 'package:zoopernova_zoo_system/core/widgets/adminTopHeader.dart';
import 'package:zoopernova_zoo_system/features/admin/maps/screens/mapUploadedAdmin.dart';

class AddAnimalAdminScreen extends ConsumerStatefulWidget {
  const AddAnimalAdminScreen({super.key});

  @override
  ConsumerState<AddAnimalAdminScreen> createState() =>
      _AddAnimalAdminScreenState();
}

class _AddAnimalAdminScreenState extends ConsumerState<AddAnimalAdminScreen> {
  final _nameController = TextEditingController();
  final _infoController = TextEditingController();
  final _xController = TextEditingController();
  final _yController = TextEditingController();

  List<Map<String, String>> _zones = [];
  String? _selectedZoneId;
  String _selectedZoneName = '';
  String _pictureUrl = '';
  bool _isLoadingZones = false;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadZones();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _infoController.dispose();
    _xController.dispose();
    _yController.dispose();
    super.dispose();
  }

  Future<void> _loadZones() async {
    setState(() => _isLoadingZones = true);
    final zones = await ref.read(animalAdminServiceProvider).getZones();
    setState(() {
      _zones = zones;
      _isLoadingZones = false;
      if (zones.isNotEmpty) {
        _selectedZoneId = zones.first['id'];
        _selectedZoneName = zones.first['name'] ?? '';
      }
    });
  }

  String get _qrData {
    final name = _nameController.text.trim();
    return name.isNotEmpty || _selectedZoneName.isNotEmpty
        ? '$name-$_selectedZoneName'
        : 'animal';
  }

  Future<void> _showMapPicker() async {
    final result = await showDialog<({int x, int y})>(
      context: context,
      builder: (_) => MapLocationPickerDialog(
        initialX: int.tryParse(_xController.text.trim()) ?? 0,
        initialY: int.tryParse(_yController.text.trim()) ?? 0,
      ),
    );
    if (result != null) {
      setState(() {
        _xController.text = result.x.toString();
        _yController.text = result.y.toString();
      });
    }
  }

  Future<void> _pickAndUpload() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'pdf'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    if (file.bytes == null) return;

    setState(() => _isUploading = true);
    try {
      final url = await ref
          .read(animalAdminServiceProvider)
          .uploadImage(file.bytes!, file.extension ?? 'png');
      if (mounted) setState(() => _pictureUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final info = _infoController.text.trim();

    if (name.isEmpty || info.isEmpty || _selectedZoneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in Name, Information and Zone'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(animalAdminServiceProvider)
          .addAnimal(
            animalName: name,
            animalDetail: info,
            animalPicture: _pictureUrl,
            zoneId: _selectedZoneId!,
            locationX: int.tryParse(_xController.text.trim()) ?? 0,
            locationY: int.tryParse(_yController.text.trim()) ?? 0,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving animal: $e')));
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
          const AdminSidebar(activeIndex: 0),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    const AdminTopHeader(title: 'Animal Inventory'),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.adminCardBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add Animal',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: _isLoadingZones
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: _PictureAndLocationPanel(
                                            pictureUrl: _pictureUrl,
                                            xController: _xController,
                                            yController: _yController,
                                            onUpload: _isUploading
                                                ? null
                                                : _pickAndUpload,
                                            onSetMap: _showMapPicker,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 5,
                                          child: _InfoPanel(
                                            nameController: _nameController,
                                            infoController: _infoController,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 5,
                                          child: _ZoneAndQrPanel(
                                            zones: _zones,
                                            selectedZoneId: _selectedZoneId,
                                            qrData: _qrData,
                                            onZoneChanged: (id, name) {
                                              setState(() {
                                                _selectedZoneId = id;
                                                _selectedZoneName = name;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppColors.adminBorderGreen,
                                    ),
                                    foregroundColor: AppColors.adminPrimary,
                                    minimumSize: const Size(112, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 14),
                                ElevatedButton(
                                  onPressed: _isSaving ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.adminPrimaryDark,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(112, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Add'),
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

// ---------------------------------------------------------------------------

class _PictureAndLocationPanel extends StatelessWidget {
  const _PictureAndLocationPanel({
    required this.pictureUrl,
    required this.xController,
    required this.yController,
    required this.onUpload,
    required this.onSetMap,
  });

  final String pictureUrl;
  final TextEditingController xController;
  final TextEditingController yController;
  final VoidCallback? onUpload;
  final VoidCallback onSetMap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Picture',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: onUpload,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.adminBorderGreen),
                foregroundColor: AppColors.adminPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Upload'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 200,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: AppColors.adminImagePlaceholder,
            borderRadius: BorderRadius.circular(12),
          ),
          child: pictureUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: pictureUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 60,
                      color: AppColors.adminTextMuted,
                    ),
                  ),
                )
              : const Center(
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 60,
                    color: AppColors.adminTextMuted,
                  ),
                ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Location',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        _CoordField(label: 'X:', controller: xController),
        const SizedBox(height: 8),
        _CoordField(label: 'Y:', controller: yController),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            onPressed: onSetMap,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.adminBorderGreen),
              foregroundColor: AppColors.adminPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Set Map'),
          ),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.nameController,
    required this.infoController,
  });

  final TextEditingController nameController;
  final TextEditingController infoController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Name',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _BoxedInput(controller: nameController, hint: 'Animal name'),
        const SizedBox(height: 16),
        const Text(
          'Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _shadow(
          height: 280,
          child: TextField(
            controller: infoController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontSize: 13, height: 1.4),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
              hintText: 'Enter animal description...',
              hintStyle: TextStyle(color: AppColors.adminTextMuted),
            ),
          ),
        ),
      ],
    );
  }
}

class _ZoneAndQrPanel extends StatelessWidget {
  const _ZoneAndQrPanel({
    required this.zones,
    required this.selectedZoneId,
    required this.qrData,
    required this.onZoneChanged,
  });

  final List<Map<String, String>> zones;
  final String? selectedZoneId;
  final String qrData;
  final void Function(String id, String name) onZoneChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Zone',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _shadow(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedZoneId,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              style: const TextStyle(
                color: AppColors.adminTextDark,
                fontSize: 14,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: zones
                  .map(
                    (zone) => DropdownMenuItem<String>(
                      value: zone['id'],
                      child: Text(zone['name'] ?? ''),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                final zone = zones.firstWhere(
                  (z) => z['id'] == value,
                  orElse: () => {},
                );
                onZoneChanged(value, zone['name'] ?? '');
              },
            ),
          ),
          height: 38,
        ),
        const SizedBox(height: 16),
        const Text(
          'Generating QR',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _shadow(
          height: 280,
          child: Center(
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200,
            ),
          ),
          padding: const EdgeInsets.all(14),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

Widget _shadow({
  required Widget child,
  double? height,
  EdgeInsetsGeometry padding = EdgeInsets.zero,
}) {
  return Container(
    height: height,
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

class _BoxedInput extends StatelessWidget {
  const _BoxedInput({required this.controller, this.hint = ''});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return _shadow(
      height: 38,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.adminTextMuted,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _CoordField extends StatelessWidget {
  const _CoordField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _shadow(
            height: 38,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                hintText: '0',
                hintStyle: TextStyle(
                  color: AppColors.adminTextMuted,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
