import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import '../models/booking_admin_model.dart';
import '../services/booking_admin_service.dart';
import 'package:zoopernova_zoo_system/core/widgets/sidebarAdmin.dart';
import 'package:zoopernova_zoo_system/core/widgets/adminTopHeader.dart';

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
    loadBookings();
  }

  final BookingAdminService _service;

  Future<void> loadBookings() async {
    state = state.copyWith(isLoading: true);
    final bookings = await _service.getBookings();
    state = state.copyWith(isLoading: false, items: bookings);
    _guardCurrentPage();
  }

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
                                  : _BookingList(rows: state.pagedItems),
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

  static const _statuses = ['All', 'pending', 'done'];

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

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'ID',
              style: TextStyle(
                color: AppColors.adminTextMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
            flex: 4,
            child: Text(
              'Date',
              style: TextStyle(
                color: AppColors.adminTextMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Tickets',
              style: TextStyle(
                color: AppColors.adminTextMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Total',
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

class _BookingList extends StatelessWidget {
  const _BookingList({required this.rows});

  final List<BookingAdminModel> rows;

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
      itemBuilder: (context, index) =>
          _BookingRow(item: rows[index], isHighlighted: index.isEven),
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({required this.item, required this.isHighlighted});

  final BookingAdminModel item;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final shortId = '#${item.id.substring(0, 3).toUpperCase()}';
    final d = item.date;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    const textColor = Color(0xFF333333);
    const fontWeight = FontWeight.w400;
    final bgColor = isHighlighted ? Colors.white : AppColors.adminRowAlt;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              shortId,
              style: TextStyle(
                fontSize: 15,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              item.userName,
              style: TextStyle(
                fontSize: 15,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              dateStr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${item.totalTickets}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _formatTotal(item),
              style: TextStyle(
                fontSize: 15,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTotal(BookingAdminModel item) {
    const adultPrice = 200;
    const childPrice = 100;
    const elderPrice = 150;
    int total =
        item.adultTotal * adultPrice +
        item.childTotal * childPrice +
        item.elderTotal * elderPrice;
    if (item.buffetFood) total += 200;
    if (item.guideTour) total += 100;
    if (item.golfCar) total += 200;
    final formatted = total.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return formatted;
  }
}

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
