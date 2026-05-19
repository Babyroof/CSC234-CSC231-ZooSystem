import 'package:flutter/material.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';

class MapSearchBar extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Function(Map<String, dynamic>) onSelected;

  const MapSearchBar({
    super.key,
    required this.items,
    required this.onSelected,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _results = [];
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _hasText = _controller.text.isNotEmpty);
    });
  }

  @override
  void didUpdateWidget(MapSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text.isNotEmpty) {
      _onChanged(_controller.text);
    }
  }

  void _onChanged(String query) {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    final lower = query.toLowerCase();
    setState(() {
      _results = widget.items
          .where(
            (item) => (item['name'] as String).toLowerCase().contains(lower),
          )
          .toList();
    });
  }

  void _select(Map<String, dynamic> item) {
    _controller.clear();
    _focusNode.unfocus();
    setState(() => _results = []);
    widget.onSelected(item);
  }

  void _clear() {
    _controller.clear();
    _focusNode.unfocus();
    setState(() => _results = []);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onChanged,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search animal or event....',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.grey,
                size: 22,
              ),
              suffixIcon: _hasText
                  ? IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: _clear,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (_hasText)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _results.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No result',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 64, endIndent: 16),
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      final isAnimal = item['type'] == 'animal';
                      final pictureUrl = item['pictureUrl'] as String?;
                      return ListTile(
                        onTap: () => _select(item),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: isAnimal
                              ? Colors.grey.shade100
                              : const Color(0xFFFFF3E0),
                          backgroundImage:
                              (pictureUrl != null && pictureUrl.isNotEmpty)
                              ? NetworkImage(pictureUrl)
                              : null,
                          child: (pictureUrl == null || pictureUrl.isEmpty)
                              ? Icon(
                                  isAnimal ? Icons.pets : Icons.event,
                                  size: 20,
                                  color: isAnimal
                                      ? AppColors.primary
                                      : Colors.orangeAccent,
                                )
                              : null,
                        ),
                        title: Text(
                          item['name'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isAnimal
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : Colors.orangeAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isAnimal ? 'animal' : 'event',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isAnimal
                                  ? AppColors.primary
                                  : Colors.orangeAccent,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }
}
