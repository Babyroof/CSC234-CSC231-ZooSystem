import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import '../../models/zone_admin_model.dart';
import '../../services/zone_admin_service.dart';
import 'package:zoopernova_zoo_system/core/widgets/sidebarAdmin.dart';
import 'package:zoopernova_zoo_system/core/widgets/adminTopHeader.dart';

// ---------------------------------------------------------------------------
// State + Notifier

class ZoneAdminState {
  const ZoneAdminState({
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
  final List<ZoneAdminModel> items;

  List<ZoneAdminModel> get filteredItems {
    final query = searchText.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items
        .where((z) => z.zoneName.toLowerCase().contains(query))
        .toList();
  }

  int get totalPages {
    if (filteredItems.isEmpty) return 1;
    return (filteredItems.length / pageSize).ceil();
  }

  List<ZoneAdminModel> get pagedItems {
    final source = filteredItems;
    final start = (currentPage - 1) * pageSize;
    if (start >= source.length) return const [];
    final end = (start + pageSize).clamp(0, source.length);
    return source.sublist(start, end);
  }

  ZoneAdminState copyWith({
    bool? isLoading,
    String? searchText,
    int? currentPage,
    int? pageSize,
    List<ZoneAdminModel>? items,
  }) {
    return ZoneAdminState(
      isLoading: isLoading ?? this.isLoading,
      searchText: searchText ?? this.searchText,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      items: items ?? this.items,
    );
  }
}

class ZoneAdminNotifier extends StateNotifier<ZoneAdminState> {
  ZoneAdminNotifier(this._service) : super(const ZoneAdminState()) {
    _subscribeToZones();
  }

  final ZoneAdminService _service;
  StreamSubscription<List<ZoneAdminModel>>? _zonesSubscription;

  void _subscribeToZones() {
    state = state.copyWith(isLoading: true);
    _zonesSubscription = _service.getZones().listen(
      (zones) {
        if (!mounted) return;
        state = state.copyWith(isLoading: false, items: zones);
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
    _zonesSubscription?.cancel();
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

final zoneAdminProvider =
    StateNotifierProvider<ZoneAdminNotifier, ZoneAdminState>((ref) {
      final service = ref.watch(zoneAdminServiceProvider);
      return ZoneAdminNotifier(service);
    });

// ---------------------------------------------------------------------------
// Screen

class ZoneAdminScreen extends ConsumerStatefulWidget {
  const ZoneAdminScreen({super.key});

  @override
  ConsumerState<ZoneAdminScreen> createState() => _ZoneAdminScreenState();
}

class _ZoneAdminScreenState extends ConsumerState<ZoneAdminScreen> {
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
    final name = await _showNameDialog(context, title: 'Create New Zone');
    if (name == null || name.isEmpty) return;
    try {
      await ref.read(zoneAdminServiceProvider).addZone(name);
      // Stream updates automatically — no manual reload needed.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}')));
      }
    }
  }

  Future<void> _openEdit(ZoneAdminModel zone) async {
    final name = await _showNameDialog(
      context,
      title: 'Edit Zone',
      initialName: zone.zoneName,
    );
    if (name == null || name.isEmpty) return;
    try {
      await ref.read(zoneAdminServiceProvider).updateZone(zone.id, name);
      // Stream updates automatically — no manual reload needed.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}')));
      }
    }
  }

  void _openDelete(ZoneAdminModel zone) {
    showDialog(
      context: context,
      builder: (_) => _DeleteZoneDialog(zone: zone),
    );
  }

  Future<String?> _showNameDialog(
    BuildContext context, {
    required String title,
    String initialName = '',
  }) async {
    final controller = TextEditingController(text: initialName);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Zone name',
            hintStyle: const TextStyle(color: AppColors.adminTextMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.adminBorderLight),
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
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
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
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(88, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(zoneAdminProvider);
    final notifier = ref.read(zoneAdminProvider.notifier);
    final pages = state.totalPages;

    return Scaffold(
      backgroundColor: AppColors.adminBg,
      body: Row(
        children: [
          const AdminSidebar(activeIndex: 4),
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
                    const AdminTopHeader(title: 'Zone Management'),
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
                                  : _ZoneList(
                                      rows: state.pagedItems,
                                      onEdit: _openEdit,
                                      onDelete: _openDelete,
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

// ---------------------------------------------------------------------------

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
            label: const Text('Create New Zone'),
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
            flex: 5,
            child: Text(
              'Zone Name',
              style: TextStyle(
                color: AppColors.adminTextMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 6,
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

class _ZoneList extends StatelessWidget {
  const _ZoneList({
    required this.rows,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ZoneAdminModel> rows;
  final ValueChanged<ZoneAdminModel> onEdit;
  final ValueChanged<ZoneAdminModel> onDelete;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Text(
          'No zones found',
          style: TextStyle(color: AppColors.adminTextMuted, fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      itemCount: rows.length,
      itemBuilder: (context, index) => _ZoneRow(
        item: rows[index],
        isEven: index.isEven,
        onEdit: () => onEdit(rows[index]),
        onDelete: () => onDelete(rows[index]),
      ),
      separatorBuilder: (_, __) => const SizedBox(height: 4),
    );
  }
}

// ---------------------------------------------------------------------------

class _ZoneRow extends StatelessWidget {
  const _ZoneRow({
    required this.item,
    required this.isEven,
    required this.onEdit,
    required this.onDelete,
  });

  final ZoneAdminModel item;
  final bool isEven;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : AppColors.adminRowAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              item.zoneName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.adminTextDark,
              ),
            ),
          ),
          Expanded(
            flex: 6,
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
        height: 40,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.adminTextDark,
            side: const BorderSide(color: AppColors.adminBorderMedium),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _DeleteZoneDialog extends StatefulWidget {
  const _DeleteZoneDialog({required this.zone});

  final ZoneAdminModel zone;

  @override
  State<_DeleteZoneDialog> createState() => _DeleteZoneDialogState();
}

class _DeleteZoneDialogState extends State<_DeleteZoneDialog> {
  bool _isDeleting = false;

  Future<void> _delete() async {
    setState(() => _isDeleting = true);
    try {
      final container = ProviderScope.containerOf(context);
      await container.read(zoneAdminServiceProvider).deleteZone(widget.zone.id);
      // Stream updates automatically — no manual reload needed.
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
                      text: widget.zone.zoneName,
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
