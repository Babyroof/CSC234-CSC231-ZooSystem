import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'package:zoopernova_zoo_system/features/admin/maps/presentation/screens/mapUploadedAdmin.dart';
import '../../models/animal_admin_model.dart';
import '../../services/animal_admin_service.dart';

class EditAnimalAdminDialog extends ConsumerStatefulWidget {
  const EditAnimalAdminDialog({super.key, required this.animal, this.onSaved});

  final AnimalAdminModel animal;
  final VoidCallback? onSaved;

  @override
  ConsumerState<EditAnimalAdminDialog> createState() =>
      _EditAnimalAdminDialogState();
}

class _EditAnimalAdminDialogState extends ConsumerState<EditAnimalAdminDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _infoController;
  late final TextEditingController _xController;
  late final TextEditingController _yController;

  List<Map<String, String>> _zones = [];
  String? _selectedZoneId;
  String _pictureUrl = '';
  bool _isLoadingZones = false;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.animal.animalName);
    _infoController = TextEditingController(text: widget.animal.animalDetail);
    _xController = TextEditingController(
      text: widget.animal.locationX.toString(),
    );
    _yController = TextEditingController(
      text: widget.animal.locationY.toString(),
    );
    _pictureUrl = widget.animal.animalPicture;
    _loadZones();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _infoController.dispose();
    _xController.dispose();
    _yController.dispose();
    super.dispose();
  }

  Future<void> _showMapPicker() async {
    final result = await showDialog<({int x, int y})>(
      context: context,
      builder: (_) => MapLocationPickerDialog(
        initialX: int.tryParse(_xController.text.trim()) ?? 0,
        initialY: int.tryParse(_yController.text.trim()) ?? 0,
        pictureUrl: _pictureUrl.isNotEmpty ? _pictureUrl : null,
      ),
    );
    if (result != null) {
      setState(() {
        _xController.text = result.x.toString();
        _yController.text = result.y.toString();
      });
    }
  }

  Future<void> _loadZones() async {
    setState(() => _isLoadingZones = true);
    final zones = await ref.read(animalAdminServiceProvider).getZones();
    final currentId = zones.firstWhere(
      (z) => z['name'] == widget.animal.zoneName,
      orElse: () => zones.isNotEmpty ? zones.first : {},
    )['id'];
    setState(() {
      _zones = zones;
      _isLoadingZones = false;
      _selectedZoneId = currentId;
    });
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

  Future<void> _save() async {
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
          .updateAnimal(
            widget.animal.id,
            animalName: name,
            animalDetail: info,
            animalPicture: _pictureUrl,
            zoneId: _selectedZoneId!,
            locationX:
                int.tryParse(_xController.text.trim()) ??
                widget.animal.locationX,
            locationY:
                int.tryParse(_yController.text.trim()) ??
                widget.animal.locationY,
          );
      widget.onSaved?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              _isLoadingZones
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _FormBody(
                      pictureUrl: _pictureUrl,
                      nameController: _nameController,
                      infoController: _infoController,
                      xController: _xController,
                      yController: _yController,
                      zones: _zones,
                      selectedZoneId: _selectedZoneId,
                      onUpload: _isUploading ? null : _pickAndUpload,
                      onSetMap: _showMapPicker,
                      onZoneChanged: (id) =>
                          setState(() => _selectedZoneId = id),
                    ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
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
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminPrimaryDark,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(100, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Save'),
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

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.pictureUrl,
    required this.nameController,
    required this.infoController,
    required this.xController,
    required this.yController,
    required this.zones,
    required this.selectedZoneId,
    required this.onUpload,
    required this.onSetMap,
    required this.onZoneChanged,
  });

  final String pictureUrl;
  final TextEditingController nameController;
  final TextEditingController infoController;
  final TextEditingController xController;
  final TextEditingController yController;
  final List<Map<String, String>> zones;
  final String? selectedZoneId;
  final VoidCallback? onUpload;
  final VoidCallback onSetMap;
  final ValueChanged<String> onZoneChanged;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: picture
          SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Picture',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: onUpload,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.adminBorderGreen,
                        ),
                        foregroundColor: AppColors.adminPrimary,
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                      child: const Text('Upload'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: AppColors.adminImagePlaceholder,
                      borderRadius: BorderRadius.circular(10),
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
                                size: 48,
                                color: AppColors.adminTextMuted,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: AppColors.adminTextMuted,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Right: fields
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _FieldBlock(
                        label: 'Name',
                        child: _BoxedInput(
                          controller: nameController,
                          hint: 'Animal name',
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _FieldBlock(
                        label: 'Zone',
                        child: _ZoneDropdown(
                          zones: zones,
                          selectedZoneId: selectedZoneId,
                          onChanged: onZoneChanged,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _FieldBlock(
                  label: 'Information',
                  child: Container(
                    height: 140,
                    decoration: _boxDecoration,
                    child: TextField(
                      controller: infoController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(fontSize: 13, height: 1.5),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                        hintText: 'Enter animal description...',
                        hintStyle: TextStyle(
                          color: AppColors.adminTextMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _FieldBlock(
                        label: 'Location X',
                        child: _BoxedInput(controller: xController, hint: '0'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _FieldBlock(
                        label: 'Location Y',
                        child: _BoxedInput(controller: yController, hint: '0'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    OutlinedButton(
                      onPressed: onSetMap,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.adminBorderGreen,
                        ),
                        foregroundColor: AppColors.adminPrimary,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                      child: const Text('Set Map'),
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

// ---------------------------------------------------------------------------

BoxDecoration get _boxDecoration => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: AppColors.adminBorderLight),
);

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _BoxedInput extends StatelessWidget {
  const _BoxedInput({required this.controller, this.hint = ''});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: _boxDecoration,
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

class _ZoneDropdown extends StatelessWidget {
  const _ZoneDropdown({
    required this.zones,
    required this.selectedZoneId,
    required this.onChanged,
  });

  final List<Map<String, String>> zones;
  final String? selectedZoneId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: _boxDecoration,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedZoneId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(color: AppColors.adminTextDark, fontSize: 14),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          items: zones
              .map(
                (z) => DropdownMenuItem<String>(
                  value: z['id'],
                  child: Text(z['name'] ?? ''),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}
