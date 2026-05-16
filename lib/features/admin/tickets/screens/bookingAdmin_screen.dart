import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import '../models/booking_admin_model.dart';
import '../services/booking_admin_service.dart';
import 'package:zoopernova_zoo_system/core/widgets/sidebarAdmin.dart';
import 'package:zoopernova_zoo_system/core/widgets/adminTopHeader.dart';
import 'package:zoopernova_zoo_system/features/booking/constants/booking_pricing.dart';

class BookingAdminState {
  const BookingAdminState({
    this.isLoading = true,
    this.searchText = '',
    this.selectedStatus = 'All',
    this.currentPage = 1,
    this.pageSize = 7,
    this.items = const [],
  });

  final bool isLoading;
  final String searchText;
  final String selectedStatus;
  final int currentPage;
  final int pageSize;
  final List<BookingAdminModel> items;

  List<BookingAdminModel> get filteredItems {
    final query = searchText.trim().toLowerCase();
    return items.where((item) {
      final statusMatch =
          selectedStatus == 'All' || item.status == selectedStatus;
      final queryMatch =
          query.isEmpty ||
          item.userName.toLowerCase().contains(query) ||
          item.id.toLowerCase().contains(query);
      return statusMatch && queryMatch;
    }).toList();
  }

  int get totalPages {
    if (filteredItems.isEmpty) return 1;
    return (filteredItems.length / pageSize).ceil();
  }

  List<BookingAdminModel> get pagedItems {
    final source = filteredItems;
    final start = (currentPage - 1) * pageSize;
    if (start >= source.length) return const [];
    final end = (start + pageSize).clamp(0, source.length);
    return source.sublist(start, end);
  }

  BookingAdminState copyWith({
    bool? isLoading,
    String? searchText,
    String? selectedStatus,
    int? currentPage,
    int? pageSize,
    List<BookingAdminModel>? items,
  }) {
    return BookingAdminState(
      isLoading: isLoading ?? this.isLoading,
      searchText: searchText ?? this.searchText,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      items: items ?? this.items,
    );
  }
}

class BookingAdminNotifier extends StateNotifier<BookingAdminState> {
  BookingAdminNotifier(this._service) : super(const BookingAdminState()) {
    _sub = _service.watchBookings().listen((bookings) {
      state = state.copyWith(isLoading: false, items: bookings);
      _guardCurrentPage();
    }, onError: (Object _) => state = state.copyWith(isLoading: false));
  }

  final BookingAdminService _service;
  late final StreamSubscription<List<BookingAdminModel>> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Future<void> deleteBooking(String id) => _service.deleteBooking(id);

  Future<void> updateBooking({
    required String id,
    required DateTime date,
    required String status,
  }) => _service.updateBooking(id: id, date: date, status: status);

  void setSearchText(String value) {
    state = state.copyWith(searchText: value, currentPage: 1);
    _guardCurrentPage();
  }

  void setStatus(String status) {
    state = state.copyWith(selectedStatus: status, currentPage: 1);
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

final bookingAdminProvider =
    StateNotifierProvider<BookingAdminNotifier, BookingAdminState>((ref) {
      final service = ref.watch(bookingAdminServiceProvider);
      return BookingAdminNotifier(service);
    });

class BookingAdminScreen extends ConsumerStatefulWidget {
  const BookingAdminScreen({super.key});

  @override
  ConsumerState<BookingAdminScreen> createState() => _BookingAdminScreenState();
}

class _BookingAdminScreenState extends ConsumerState<BookingAdminScreen> {
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

  Future<void> _showEditDialog(BookingAdminModel item) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _EditBookingDialog(
        item: item,
        onSave:
            ({
              required String id,
              required DateTime date,
              required String status,
            }) => ref
                .read(bookingAdminProvider.notifier)
                .updateBooking(id: id, date: date, status: status),
      ),
    );
  }

  Future<void> _showDeleteConfirm(BookingAdminModel item) async {
    final shortId = '#${item.id.substring(0, 6).toUpperCase()}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Booking'),
        content: Text(
          'Delete booking $shortId for ${item.userName}?\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelled'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.adminTextDark,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(bookingAdminProvider.notifier).deleteBooking(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingAdminProvider);
    final notifier = ref.read(bookingAdminProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.adminBg,
      body: Row(
        children: [
          const AdminSidebar(activeIndex: 1),
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
                    const AdminTopHeader(title: 'Booking List'),
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
                              selectedStatus: state.selectedStatus,
                              onSearchChanged: notifier.setSearchText,
                              onStatusChanged: notifier.setStatus,
                            ),
                            const SizedBox(height: 18),
                            const _HeaderRow(),
                            const SizedBox(height: 8),
                            Expanded(
                              child: state.isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : _BookingList(
                                      rows: state.pagedItems,
                                      onEdit: _showEditDialog,
                                      onDelete: _showDeleteConfirm,
                                    ),
                            ),
                            const SizedBox(height: 10),
                            _Pagination(
                              currentPage: state.currentPage,
                              totalPages: state.totalPages,
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

// ─── Toolbar ────────────────────────────────────────────────────────────────

class _ToolBar extends StatelessWidget {
  const _ToolBar({
    required this.controller,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onStatusChanged,
  });

  final TextEditingController controller;
  final String selectedStatus;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;

  static const _statuses = ['All', 'pending', 'done', 'cancel'];

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
                hintText: 'Search by name or ID',
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
              value: selectedStatus,
              borderRadius: BorderRadius.circular(12),
              icon: const Icon(Icons.unfold_more, size: 18),
              style: const TextStyle(
                color: AppColors.adminTextDark,
                fontSize: 14,
              ),
              items: _statuses
                  .map(
                    (s) => DropdownMenuItem<String>(value: s, child: Text(s)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onStatusChanged(value);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Header Row ─────────────────────────────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: AppColors.adminTextMuted,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Expanded(flex: 2, child: Text('ID', style: style)),
          const Expanded(flex: 3, child: Text('Name', style: style)),
          const Expanded(flex: 2, child: Text('Date', style: style)),
          const Expanded(flex: 3, child: Text('Guests', style: style)),
          const Expanded(flex: 3, child: Text('Add-ons', style: style)),
          const Expanded(flex: 2, child: Text('Total (฿)', style: style)),
          const Expanded(flex: 2, child: Text('Status', style: style)),
          const Expanded(flex: 3, child: Text('Actions', style: style)),
        ],
      ),
    );
  }
}

// ─── Booking List ────────────────────────────────────────────────────────────

class _BookingList extends StatelessWidget {
  const _BookingList({
    required this.rows,
    required this.onEdit,
    required this.onDelete,
  });

  final List<BookingAdminModel> rows;
  final void Function(BookingAdminModel) onEdit;
  final void Function(BookingAdminModel) onDelete;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Text(
          'No bookings found',
          style: TextStyle(color: AppColors.adminTextMuted, fontSize: 15),
        ),
      );
    }
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) => _BookingRow(
        item: rows[index],
        isHighlighted: index.isEven,
        onEdit: () => onEdit(rows[index]),
        onDelete: () => onDelete(rows[index]),
      ),
    );
  }
}

// ─── Booking Row ─────────────────────────────────────────────────────────────

class _BookingRow extends StatelessWidget {
  const _BookingRow({
    required this.item,
    required this.isHighlighted,
    required this.onEdit,
    required this.onDelete,
  });

  final BookingAdminModel item;
  final bool isHighlighted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final shortId = '#${item.id.substring(0, 6).toUpperCase()}';
    final d = item.date;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
    const textColor = Color(0xFF333333);
    final bgColor = isHighlighted ? Colors.white : AppColors.adminRowAlt;

    final chipColors = [
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
      const Color(0xFFEF4444),
    ];
    final addons = item.selectedAddOns.asMap().entries.map((entry) {
      final color = chipColors[entry.key % chipColors.length];
      return _AddonChip(label: entry.value.name, color: color);
    }).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              shortId,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              item.userName,
              style: const TextStyle(fontSize: 14, color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              dateStr,
              style: const TextStyle(fontSize: 13, color: textColor),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _GuestLine(label: 'Adult', count: item.adultTotal),
                _GuestLine(label: 'Kid', count: item.childTotal),
                _GuestLine(label: 'Elder', count: item.elderTotal),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: addons.isEmpty
                ? const Text(
                    '—',
                    style: TextStyle(
                      color: AppColors.adminTextMuted,
                      fontSize: 13,
                    ),
                  )
                : Wrap(spacing: 4, runSpacing: 4, children: addons),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatTotal(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ),
          Expanded(flex: 2, child: _StatusBadge(status: item.status)),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: _ActionIconButton(
                    icon: Icons.edit_outlined,
                    color: AppColors.black,
                    tooltip: 'Edit',
                    onTap: onEdit,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ActionIconButton(
                    icon: Icons.delete_outline,
                    color: AppColors.black,
                    tooltip: 'Delete',
                    onTap: onDelete,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTotal() {
    final addOnTotal = item.selectedAddOns.fold(0, (acc, a) => acc + a.price);
    final total =
        item.adultTotal * BookingPricing.adultPrice +
        item.childTotal * BookingPricing.kidPrice +
        item.elderTotal * BookingPricing.elderPrice +
        addOnTotal;
    return total.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

// ─── Guest Line ──────────────────────────────────────────────────────────────

class _GuestLine extends StatelessWidget {
  const _GuestLine({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $count',
      style: TextStyle(
        fontSize: 12,
        color: count > 0 ? const Color(0xFF333333) : AppColors.adminTextMuted,
      ),
    );
  }
}

// ─── Addon Chip ──────────────────────────────────────────────────────────────

class _AddonChip extends StatelessWidget {
  const _AddonChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Status Badge ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'done' => (const Color(0xFFD1FAE5), const Color(0xFF065F46)),
      'cancel' => (AppColors.adminDangerBg, AppColors.adminDanger),
      _ => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          status,
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

// ─── Action Icon Button ──────────────────────────────────────────────────────

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Text(tooltip),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

// ─── Edit Booking Dialog ─────────────────────────────────────────────────────

class _EditBookingDialog extends StatefulWidget {
  const _EditBookingDialog({required this.item, required this.onSave});

  final BookingAdminModel item;
  final Future<void> Function({
    required String id,
    required DateTime date,
    required String status,
  })
  onSave;

  @override
  State<_EditBookingDialog> createState() => _EditBookingDialogState();
}

class _EditBookingDialogState extends State<_EditBookingDialog> {
  late DateTime _date;
  late String _status;
  bool _saving = false;

  static const _statuses = ['pending', 'done', 'cancel'];

  @override
  void initState() {
    super.initState();
    _date = widget.item.date;
    _status = _statuses.contains(widget.item.status)
        ? widget.item.status
        : 'pending';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(id: widget.item.id, date: _date, status: _status);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${_date.day.toString().padLeft(2, '0')}/'
        '${_date.month.toString().padLeft(2, '0')}/'
        '${_date.year}';

    return AlertDialog(
      title: Text(
        'Edit Booking #${widget.item.id.substring(0, 6).toUpperCase()}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Visit Date',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.adminTextMuted,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.adminBorderLight),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppColors.adminTextMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(dateStr, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Status',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.adminTextMuted,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.adminBorderLight),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _status,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(8),
                  icon: const Icon(Icons.unfold_more, size: 18),
                  style: const TextStyle(
                    color: AppColors.adminTextDark,
                    fontSize: 14,
                  ),
                  items: _statuses
                      .map(
                        (s) =>
                            DropdownMenuItem<String>(value: s, child: Text(s)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _status = v);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.adminPrimaryDark,
          ),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ─── Pagination ──────────────────────────────────────────────────────────────

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
    final pages = List.generate(totalPages, (i) => i + 1);

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
