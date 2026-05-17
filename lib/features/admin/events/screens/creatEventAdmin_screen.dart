import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'package:zoopernova_zoo_system/features/admin/maps/screens/mapUploadedAdmin.dart';
import '../services/event_admin_service.dart';

class CreateEventAdminDialog extends ConsumerStatefulWidget {
  const CreateEventAdminDialog({super.key, this.onCreated});

  final VoidCallback? onCreated;

  @override
  ConsumerState<CreateEventAdminDialog> createState() =>
      _CreateEventAdminDialogState();
}

class _CreateEventAdminDialogState
    extends ConsumerState<CreateEventAdminDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _xController = TextEditingController(text: '0');
  final TextEditingController _yController = TextEditingController(text: '0');

  String _pictureUrl = '';
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _detailController.dispose();
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
          .read(eventAdminServiceProvider)
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

  Future<void> _create() async {
    final name = _nameController.text.trim();
    final detail = _detailController.text.trim();

    if (name.isEmpty || detail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in Event Name and Description'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(eventAdminServiceProvider)
          .createEvent(
            eventName: name,
            eventDetail: detail,
            eventPicture: _pictureUrl,
            locationX: int.tryParse(_xController.text.trim()) ?? 0,
            locationY: int.tryParse(_yController.text.trim()) ?? 0,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating event: $e')));
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
        constraints: const BoxConstraints(maxWidth: 960),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: picture + location
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
                                onPressed: _isUploading ? null : _pickAndUpload,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.adminBorderGreen,
                                  ),
                                  foregroundColor: AppColors.adminPrimary,
                                  minimumSize: const Size(0, 32),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
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
                          Container(
                            width: double.infinity,
                            height: 200,
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              color: AppColors.adminImagePlaceholder,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _pictureUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: _pictureUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
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
                          const SizedBox(height: 14),
                          const Text(
                            'Location',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _InlineField(label: 'X:', controller: _xController),
                          const SizedBox(height: 8),
                          _InlineField(label: 'Y:', controller: _yController),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton(
                              onPressed: _showMapPicker,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.adminBorderGreen,
                                ),
                                foregroundColor: AppColors.adminPrimary,
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(fontSize: 13),
                              ),
                              child: const Text('Set Map'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Right: name + description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Name'),
                          const SizedBox(height: 6),
                          _BoxedInput(
                            controller: _nameController,
                            hint: 'Event name',
                          ),
                          const SizedBox(height: 14),
                          const _FieldLabel('Information'),
                          const SizedBox(height: 6),
                          Container(
                            height: 240,
                            decoration: _boxDecoration,
                            child: TextField(
                              controller: _detailController,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              style: const TextStyle(fontSize: 13, height: 1.5),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(12),
                                hintText: 'Enter event description...',
                                hintStyle: TextStyle(
                                  color: AppColors.adminTextMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                    onPressed: _isSaving ? null : _create,
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
                        : const Text('Add'),
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

BoxDecoration get _boxDecoration => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: AppColors.adminBorderLight),
);

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );
}

class _InlineField extends StatelessWidget {
  const _InlineField({required this.label, required this.controller});

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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.adminTextDark,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 36,
            decoration: _boxDecoration,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
        ),
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
