import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'package:zoopernova_zoo_system/core/widgets/sidebarAdmin.dart';
import 'package:zoopernova_zoo_system/core/widgets/adminTopHeader.dart';
import 'package:zoopernova_zoo_system/features/booking/models/add_on_model.dart';
import '../services/add_on_admin_service.dart';

// ---------------------------------------------------------------------------
// State + Notifier

class AddOnAdminState {
  const AddOnAdminState({
    this.isLoading = true,
    this.searchText = '',
    this.currentPage = 1,
    this.pageSize = 10,
    this.items = const [],
  });

  final bool isLoading;
  final String searchText;
  final int currentPage;
  final int pageSize;
  final List<AddOnModel> items;

  List<AddOnModel> get filteredItems {
    final query = searchText.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items.where((a) => a.name.toLowerCase().contains(query)).toList();
  }

  int get totalPages {
    if (filteredItems.isEmpty) return 1;
    return (filteredItems.length / pageSize).ceil();
  }

  List<AddOnModel> get pagedItems {
    final source = filteredItems;
    final start = (currentPage - 1) * pageSize;
    if (start >= source.length) return const [];
    final end = (start + pageSize).clamp(0, source.length);
    return source.sublist(start, end);
  }

  AddOnAdminState copyWith({
    bool? isLoading,
    String? searchText,
    int? currentPage,
    int? pageSize,
    List<AddOnModel>? items,
  }) {
    return AddOnAdminState(
      isLoading: isLoading ?? this.isLoading,
      searchText: searchText ?? this.searchText,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      items: items ?? this.items,
    );
  }
}

class AddOnAdminNotifier extends StateNotifier<AddOnAdminState> {
  AddOnAdminNotifier(this._service) : super(const AddOnAdminState()) {
    _subscribeToAddOns();
  }

  final AddOnAdminService _service;
  StreamSubscription<List<AddOnModel>>? _subscription;

  void _subscribeToAddOns() {
    state = state.copyWith(isLoading: true);
    _subscription = _service.getAddOns().listen(
      (addOns) {
        if (!mounted) return;
        state = state.copyWith(isLoading: false, items: addOns);
        _guardCurrentPage();
      },
      onError: (Object e) {
        if (!mounted) return;
        state = state.copyWith(isLoading: false);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void setSearchText(String value) {
    state = state.copyWith(searchText: value, currentPage: 1);
    _guardCurrentPage();
  }

  void setPage(int page) {
    state = state.copyWith(currentPage: page.clamp(1, state.totalPages));
  }

  void nextPage() => setPage(state.currentPage + 1);
  void previousPage() => setPage(state.currentPage - 1);

  void _guardCurrentPage() {
    if (state.currentPage > state.totalPages) {
      state = state.copyWith(currentPage: state.totalPages);
    }
  }
}

final addOnAdminServiceProvider = Provider<AddOnAdminService>((ref) {
  return AddOnAdminService();
});

final addOnAdminProvider =
    StateNotifierProvider<AddOnAdminNotifier, AddOnAdminState>((ref) {
      final service = ref.watch(addOnAdminServiceProvider);
      return AddOnAdminNotifier(service);
    });

// ---------------------------------------------------------------------------
// Screen

class AddOnsAdminScreen extends ConsumerStatefulWidget {
  const AddOnsAdminScreen({super.key});

  @override
  ConsumerState<AddOnsAdminScreen> createState() => _AddOnsAdminScreenState();
}

class _AddOnsAdminScreenState extends ConsumerState<AddOnsAdminScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AddOnFormDialog(
        title: 'Create New Add-on',
        onConfirm: (name, price, priceType, isActive) async {
          await ref
              .read(addOnAdminServiceProvider)
              .createAddOn(
                name: name,
                price: price,
                priceType: priceType,
                isActive: isActive,
              );
        },
      ),
    );
  }

  Future<void> _openEdit(AddOnModel addOn) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AddOnFormDialog(
        title: 'Edit Add-on',
        initial: addOn,
        onConfirm: (name, price, priceType, isActive) async {
          await ref
              .read(addOnAdminServiceProvider)
              .updateAddOn(
                id: addOn.id,
                name: name,
                price: price,
                priceType: priceType,
                order: addOn.order,
                isActive: isActive,
              );
        },
      ),
    );
  }

  void _openDelete(AddOnModel addOn) {
    showDialog(
      context: context,
      builder: (_) => _DeleteAddOnDialog(addOn: addOn),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addOnAdminProvider);
    final notifier = ref.read(addOnAdminProvider.notifier);
    final pages = state.totalPages;

    return Scaffold(
      backgroundColor: AppColors.adminBg,
      body: Row(
        children: [
          const AdminSidebar(activeIndex: 5),
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
                    const AdminTopHeader(title: 'Add-ons Management'),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _ToolBar(
                              controller: _searchController,
                              onSearchChanged: notifier.setSearchText,
                              onCreatePressed: _openCreate,
                            ),
                            const SizedBox(height: 18),
                            const _HeaderRow(),
                            const SizedBox(height: 8),
                            Expanded(
                              child: state.isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : _AddOnList(
                                      rows: state.pagedItems,
                                      onEdit: _openEdit,
                                      onDelete: _openDelete,
                                      onReorderUp: (item) {
                                        ref
                                            .read(addOnAdminServiceProvider)
                                            .reorderAddOn(
                                              item.id,
                                              item.order,
                                              direction: 'up',
                                            );
                                      },
                                      onReorderDown: (item) {
                                        ref
                                            .read(addOnAdminServiceProvider)
                                            .reorderAddOn(
                                              item.id,
                                              item.order,
                                              direction: 'down',
                                            );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 10),
                            _Pagination(
                              currentPage: state.currentPage,
                              totalPages: pages,
                              onPrevious: notifier.previousPage,
                              onNext: notifier.nextPage,
                              onPageTap: notifier.setPage,
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

class _ToolBar extends StatelessWidget {
  const _ToolBar({
    required this.controller,
    required this.onSearchChanged,
    required this.onCreatePressed,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.adminBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: controller,
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, size: 22),
                hintText: 'Search',
                hintStyle: TextStyle(color: AppColors.adminTextMuted),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.adminBorderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: 'All',
              borderRadius: BorderRadius.circular(12),
              icon: const Icon(Icons.keyboard_arrow_down),
              style: const TextStyle(
                color: AppColors.adminTextDark,
                fontSize: 14,
              ),
              items: const [DropdownMenuItem(value: 'All', child: Text('All'))],
              onChanged: (_) {},
            ),
          ),
        ),
        const SizedBox(width: 14),
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: onCreatePressed,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create New Add-on'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'Name',
              style: TextStyle(
                color: AppColors.adminTextMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Price',
              style: TextStyle(
                color: AppColors.adminTextMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Price Type',
              style: TextStyle(
                color: AppColors.adminTextMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Reorder',
              style: TextStyle(
                color: AppColors.adminTextMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Status',
              style: TextStyle(
                color: AppColors.adminTextMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Actions',
              style: TextStyle(
                color: AppColors.adminTextMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _AddOnList extends StatelessWidget {
  const _AddOnList({
    required this.rows,
    required this.onEdit,
    required this.onDelete,
    required this.onReorderUp,
    required this.onReorderDown,
  });

  final List<AddOnModel> rows;
  final ValueChanged<AddOnModel> onEdit;
  final ValueChanged<AddOnModel> onDelete;
  final ValueChanged<AddOnModel> onReorderUp;
  final ValueChanged<AddOnModel> onReorderDown;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Text(
          'No add-ons found',
          style: TextStyle(color: AppColors.adminTextMuted, fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      itemCount: rows.length,
      itemBuilder: (context, index) => _AddOnRow(
        item: rows[index],
        isEven: index.isEven,
        isFirst: index == 0,
        isLast: index == rows.length - 1,
        onEdit: () => onEdit(rows[index]),
        onDelete: () => onDelete(rows[index]),
        onReorderUp: () => onReorderUp(rows[index]),
        onReorderDown: () => onReorderDown(rows[index]),
      ),
      separatorBuilder: (context, index) => const SizedBox(height: 4),
    );
  }
}

// ---------------------------------------------------------------------------

class _AddOnRow extends StatelessWidget {
  const _AddOnRow({
    required this.item,
    required this.isEven,
    required this.isFirst,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
    required this.onReorderUp,
    required this.onReorderDown,
  });

  final AddOnModel item;
  final bool isEven;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReorderUp;
  final VoidCallback onReorderDown;

  @override
  Widget build(BuildContext context) {
    final priceTypeLabel = item.priceType == 'per_person'
        ? 'Per Person'
        : 'Per Booking';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : AppColors.adminRowAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              item.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.adminTextDark,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${item.price} ฿',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.adminTextDark,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              priceTypeLabel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.adminTextDark,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  onPressed: isFirst ? null : onReorderUp,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  color: AppColors.adminTextDark,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  onPressed: isLast ? null : onReorderDown,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  color: AppColors.adminTextDark,
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: _StatusChip(isActive: item.isActive)),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _ActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onPressed: onEdit,
                ),
                const SizedBox(width: 10),
                _ActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  onPressed: onDelete,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final bg = isActive ? const Color(0xFFE6F4EA) : const Color(0xFFF0F0F0);
    final fg = isActive ? const Color(0xFF2E7D32) : AppColors.adminTextMuted;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          isActive ? 'Active' : 'Inactive',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 34,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 15),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.black,
            side: BorderSide(color: AppColors.black.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create / Edit Dialog

class _AddOnFormDialog extends StatefulWidget {
  const _AddOnFormDialog({
    required this.title,
    required this.onConfirm,
    this.initial,
  });

  final String title;
  final AddOnModel? initial;
  final Future<void> Function(
    String name,
    int price,
    String priceType,
    bool isActive,
  )
  onConfirm;

  @override
  State<_AddOnFormDialog> createState() => _AddOnFormDialogState();
}

class _AddOnFormDialogState extends State<_AddOnFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late String _priceType;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _priceController = TextEditingController(
      text: widget.initial != null ? '${widget.initial!.price}' : '',
    );
    _priceType = widget.initial?.priceType ?? 'per_booking';
    _isActive = widget.initial?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final price = int.tryParse(_priceController.text.trim()) ?? 0;
    if (name.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await widget.onConfirm(name, price, _priceType, _isActive);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FieldLabel('Name'),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Add-on name',
                hintStyle: const TextStyle(color: AppColors.adminTextMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.adminBorderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.adminPrimary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _FieldLabel('Price (฿)'),
            const SizedBox(height: 6),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: const TextStyle(color: AppColors.adminTextMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.adminBorderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.adminPrimary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _FieldLabel('Price Type'),
            const SizedBox(height: 6),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.adminBorderLight),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _priceType,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(10),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  style: const TextStyle(
                    color: AppColors.adminTextDark,
                    fontSize: 14,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'per_booking',
                      child: Text('Per Booking'),
                    ),
                    DropdownMenuItem(
                      value: 'per_person',
                      child: Text('Per Person'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _priceType = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Is Active',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.adminTextDark,
                  ),
                ),
                Switch(
                  value: _isActive,
                  activeThumbColor: AppColors.adminPrimary,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.adminBorderGreen),
            foregroundColor: AppColors.adminPrimary,
            minimumSize: const Size(88, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.adminPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size(88, 40),
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
              : const Text('Confirm'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.adminTextDark,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Delete Dialog

class _DeleteAddOnDialog extends StatefulWidget {
  const _DeleteAddOnDialog({required this.addOn});

  final AddOnModel addOn;

  @override
  State<_DeleteAddOnDialog> createState() => _DeleteAddOnDialogState();
}

class _DeleteAddOnDialogState extends State<_DeleteAddOnDialog> {
  bool _isDeleting = false;

  Future<void> _delete() async {
    setState(() => _isDeleting = true);
    try {
      final container = ProviderScope.containerOf(context);
      await container
          .read(addOnAdminServiceProvider)
          .deleteAddOn(widget.addOn.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 36, 32, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.adminDangerBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: AppColors.adminDanger,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Confirm Delete?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.adminDanger,
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.adminTextDark,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'Are you sure you want to delete '),
                    TextSpan(
                      text: widget.addOn.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: '?'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isDeleting
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.adminDanger),
                        foregroundColor: AppColors.adminDanger,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isDeleting ? null : _delete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.adminDanger,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: _isDeleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Delete'),
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

// ---------------------------------------------------------------------------
// Pagination

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
    required this.onPageTap,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<int> onPageTap;

  @override
  Widget build(BuildContext context) {
    final pages = List.generate(totalPages, (index) => index + 1);

    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: currentPage > 1 ? onPrevious : null,
            icon: const Icon(Icons.chevron_left, size: 18),
            visualDensity: VisualDensity.compact,
          ),
          ...pages.map(
            (page) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => onPageTap(page),
                borderRadius: BorderRadius.circular(8),
                child: _PageChip(number: '$page', active: page == currentPage),
              ),
            ),
          ),
          IconButton(
            onPressed: currentPage < totalPages ? onNext : null,
            icon: const Icon(Icons.chevron_right, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _PageChip extends StatelessWidget {
  const _PageChip({required this.number, this.active = false});

  final String number;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.adminPrimaryDark : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        number,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: active ? Colors.white : AppColors.adminTextDark,
        ),
      ),
    );
  }
}
