import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'package:zoopernova_zoo_system/core/routes/app_routes.dart';
import 'package:zoopernova_zoo_system/core/widgets/sidebarAdmin.dart';
import 'package:zoopernova_zoo_system/core/widgets/adminTopHeader.dart';
import '../models/animal_admin_model.dart';
import '../services/animal_admin_service.dart';
import 'editAnimalAdmin_screen.dart';
import 'deleteAnimalAdmin_screen.dart';

class AnimalAdminState {
  const AnimalAdminState({
    this.isLoading = true,
    this.searchText = '',
    this.selectedZone = 'All',
    this.currentPage = 1,
    this.pageSize = 7,
    this.items = const [],
  });

  final bool isLoading;
  final String searchText;
  final String selectedZone;
  final int currentPage;
  final int pageSize;
  final List<AnimalAdminModel> items;

  List<String> get zones {
    final unique = items.map((e) => e.zoneName).toSet().toList()..sort();
    return ['All', ...unique];
  }

  List<AnimalAdminModel> get filteredItems {
    final query = searchText.trim().toLowerCase();
    return items.where((item) {
      final zoneMatch = selectedZone == 'All' || item.zoneName == selectedZone;
      final queryMatch =
          query.isEmpty ||
          item.animalName.toLowerCase().contains(query) ||
          item.zoneName.toLowerCase().contains(query);
      return zoneMatch && queryMatch;
    }).toList();
  }

  int get totalPages {
    if (filteredItems.isEmpty) return 1;
    return (filteredItems.length / pageSize).ceil();
  }

  List<AnimalAdminModel> get pagedItems {
    final source = filteredItems;
    final start = (currentPage - 1) * pageSize;
    if (start >= source.length) return const [];
    final end = (start + pageSize).clamp(0, source.length);
    return source.sublist(start, end);
  }

  AnimalAdminState copyWith({
    bool? isLoading,
    String? searchText,
    String? selectedZone,
    int? currentPage,
    int? pageSize,
    List<AnimalAdminModel>? items,
  }) {
    return AnimalAdminState(
      isLoading: isLoading ?? this.isLoading,
      searchText: searchText ?? this.searchText,
      selectedZone: selectedZone ?? this.selectedZone,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      items: items ?? this.items,
    );
  }
}

class AnimalAdminNotifier extends StateNotifier<AnimalAdminState> {
  AnimalAdminNotifier(this._service) : super(const AnimalAdminState()) {
    loadAnimals();
  }

  final AnimalAdminService _service;

  Future<void> loadAnimals() async {
    state = state.copyWith(isLoading: true);
    final animals = await _service.getAnimals();
    state = state.copyWith(isLoading: false, items: animals);
    _guardCurrentPage();
  }

  void setSearchText(String value) {
    state = state.copyWith(searchText: value, currentPage: 1);
    _guardCurrentPage();
  }

  void setZone(String zone) {
    state = state.copyWith(selectedZone: zone, currentPage: 1);
    _guardCurrentPage();
  }

  void setPage(int page) {
    final safe = page.clamp(1, state.totalPages);
    state = state.copyWith(currentPage: safe);
  }

  void nextPage() => setPage(state.currentPage + 1);

  void previousPage() => setPage(state.currentPage - 1);

  void _guardCurrentPage() {
    if (state.currentPage > state.totalPages) {
      state = state.copyWith(currentPage: state.totalPages);
    }
  }
}

final animalAdminProvider =
    StateNotifierProvider<AnimalAdminNotifier, AnimalAdminState>((ref) {
      final service = ref.watch(animalAdminServiceProvider);
      return AnimalAdminNotifier(service);
    });

class AnimalAdminScreen extends ConsumerStatefulWidget {
  const AnimalAdminScreen({super.key});

  @override
  ConsumerState<AnimalAdminScreen> createState() => _AnimalAdminScreenState();
}

class _AnimalAdminScreenState extends ConsumerState<AnimalAdminScreen> {
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
    final state = ref.watch(animalAdminProvider);
    final notifier = ref.read(animalAdminProvider.notifier);
    final pages = state.totalPages;

    return Scaffold(
      backgroundColor: AppColors.adminBg,
      body: Row(
        children: [
          const AdminSidebar(activeIndex: 0),
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
                    const AdminTopHeader(title: 'Animal Inventory'),
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
                              selectedZone: state.selectedZone,
                              zones: state.zones,
                              onSearchChanged: notifier.setSearchText,
                              onZoneChanged: notifier.setZone,
                              onCreatePressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoute.adminAddAnimal,
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
                                  : _AnimalList(
                                      rows: state.pagedItems,
                                      onEdit: (item) {
                                        showDialog(
                                          context: context,
                                          builder: (_) => EditAnimalAdminDialog(
                                            animal: item,
                                            onSaved: notifier.loadAnimals,
                                          ),
                                        );
                                      },
                                      onDelete: (item) {
                                        showDialog(
                                          context: context,
                                          builder: (_) =>
                                              DeleteAnimalAdminDialog(
                                                animal: item,
                                                onDeleted: notifier.loadAnimals,
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
    required this.selectedZone,
    required this.zones,
    required this.onSearchChanged,
    required this.onZoneChanged,
    required this.onCreatePressed,
  });

  final TextEditingController controller;
  final String selectedZone;
  final List<String> zones;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onZoneChanged;
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
              value: selectedZone,
              borderRadius: BorderRadius.circular(12),
              icon: const Icon(Icons.keyboard_arrow_down),
              style: const TextStyle(
                color: AppColors.adminTextDark,
                fontSize: 14,
              ),
              items: zones
                  .map(
                    (zone) => DropdownMenuItem<String>(
                      value: zone,
                      child: Text(zone),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onZoneChanged(value);
              },
            ),
          ),
        ),
        const SizedBox(width: 14),
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: onCreatePressed,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Register New Animal'),
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
            flex: 5,
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
              'Zone',
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

class _AnimalList extends StatelessWidget {
  const _AnimalList({
    required this.rows,
    required this.onEdit,
    required this.onDelete,
  });

  final List<AnimalAdminModel> rows;
  final ValueChanged<AnimalAdminModel> onEdit;
  final ValueChanged<AnimalAdminModel> onDelete;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Text(
          'No animals found',
          style: TextStyle(color: AppColors.adminTextMuted, fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      itemCount: rows.length,
      itemBuilder: (context, index) => _AnimalRow(
        item: rows[index],
        isEven: index.isEven,
        onEdit: () => onEdit(rows[index]),
        onDelete: () => onDelete(rows[index]),
      ),
      separatorBuilder: (_, __) => const SizedBox(height: 4),
    );
  }
}

class _AnimalRow extends StatelessWidget {
  const _AnimalRow({
    required this.item,
    required this.isEven,
    required this.onEdit,
    required this.onDelete,
  });

  final AnimalAdminModel item;
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
            flex: 5,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: item.animalPicture,
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
                      child: const Icon(Icons.pets, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  item.animalName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              item.zoneName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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
