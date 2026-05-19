import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import '../../models/event_admin_model.dart';
import '../../services/event_admin_service.dart';
import 'editEventAdmin_screen.dart';
import 'deleteEventAdmin_screen.dart';
import 'creatEventAdmin_screen.dart';
import 'package:zoopernova_zoo_system/core/widgets/sidebarAdmin.dart';
import 'package:zoopernova_zoo_system/core/widgets/adminTopHeader.dart';

class EventAdminState {
  const EventAdminState({
    this.isLoading = true,
    this.searchText = '',
    this.currentPage = 1,
    this.pageSize = 7,
    this.items = const [],
  });

  final bool isLoading;
  final String searchText;
  final int currentPage;
  final int pageSize;
  final List<EventAdminModel> items;

  List<EventAdminModel> get filteredItems {
    final query = searchText.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items
        .where((e) => e.eventName.toLowerCase().contains(query))
        .toList();
  }

  int get totalPages {
    if (filteredItems.isEmpty) return 1;
    return (filteredItems.length / pageSize).ceil();
  }

  List<EventAdminModel> get pagedItems {
    final source = filteredItems;
    final start = (currentPage - 1) * pageSize;
    if (start >= source.length) return const [];
    final end = (start + pageSize).clamp(0, source.length);
    return source.sublist(start, end);
  }

  EventAdminState copyWith({
    bool? isLoading,
    String? searchText,
    int? currentPage,
    int? pageSize,
    List<EventAdminModel>? items,
  }) {
    return EventAdminState(
      isLoading: isLoading ?? this.isLoading,
      searchText: searchText ?? this.searchText,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      items: items ?? this.items,
    );
  }
}

class EventAdminNotifier extends StateNotifier<EventAdminState> {
  EventAdminNotifier(this._service) : super(const EventAdminState()) {
    _subscribeToEvents();
  }

  final EventAdminService _service;
  StreamSubscription<List<EventAdminModel>>? _eventsSubscription;

  void _subscribeToEvents() {
    state = state.copyWith(isLoading: true);
    _eventsSubscription = _service.getEvents().listen(
      (events) {
        if (!mounted) return;
        state = state.copyWith(isLoading: false, items: events);
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
    _eventsSubscription?.cancel();
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

final eventAdminProvider =
    StateNotifierProvider<EventAdminNotifier, EventAdminState>((ref) {
      final service = ref.watch(eventAdminServiceProvider);
      return EventAdminNotifier(service);
    });

class EventAdminScreen extends ConsumerStatefulWidget {
  const EventAdminScreen({super.key});

  @override
  ConsumerState<EventAdminScreen> createState() => _EventAdminScreenState();
}

class _EventAdminScreenState extends ConsumerState<EventAdminScreen> {
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
    final state = ref.watch(eventAdminProvider);
    final notifier = ref.read(eventAdminProvider.notifier);
    final pages = state.totalPages;

    return Scaffold(
      backgroundColor: AppColors.adminBg,
      body: Row(
        children: [
          const AdminSidebar(activeIndex: 2),
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
                    const AdminTopHeader(title: 'Events Management'),
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
                              onCreatePressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) =>
                                      const CreateEventAdminDialog(),
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                            const _HeaderRow(),
                            const SizedBox(height: 8),
                            Expanded(
                              child: state.isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : _EventList(
                                      rows: state.pagedItems,
                                      onEdit: (item) {
                                        showDialog(
                                          context: context,
                                          builder: (_) =>
                                              EditEventAdminDialog(event: item),
                                        );
                                      },
                                      onDelete: (item) {
                                        showDialog(
                                          context: context,
                                          builder: (_) =>
                                              DeleteEventAdminDialog(
                                                event: item,
                                              ),
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
            label: const Text('Create New Event'),
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

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 9,
            child: Text(
              'Event Name',
              style: TextStyle(
                color: AppColors.adminTextMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 5,
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

class _EventList extends StatelessWidget {
  const _EventList({
    required this.rows,
    required this.onEdit,
    required this.onDelete,
  });

  final List<EventAdminModel> rows;
  final ValueChanged<EventAdminModel> onEdit;
  final ValueChanged<EventAdminModel> onDelete;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Text(
          'No events found',
          style: TextStyle(color: AppColors.adminTextMuted, fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      itemCount: rows.length,
      itemBuilder: (context, index) => _EventRow(
        item: rows[index],
        isEven: index.isEven,
        onEdit: () => onEdit(rows[index]),
        onDelete: () => onDelete(rows[index]),
      ),
      separatorBuilder: (_, __) => const SizedBox(height: 4),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.item,
    required this.isEven,
    required this.onEdit,
    required this.onDelete,
  });

  final EventAdminModel item;
  final bool isEven;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : AppColors.adminRowAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 9,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: item.eventPicture,
                    width: 56,
                    height: 42,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 56,
                      height: 42,
                      color: AppColors.adminBorderLight,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 56,
                      height: 42,
                      color: AppColors.adminBorderLight,
                      child: const Icon(Icons.celebration_outlined, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  item.eventName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
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
        height: 38,
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
