import 'package:flutter/material.dart';

class FormsFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String searchHint;
  final bool showSearch;

  final String statusValue;
  final ValueChanged<String?> onStatusChanged;

  final String dateLabel;
  final VoidCallback onPickDateRange;

  final bool showPlaceFilter;
  final String placeValue;
  final List<String> placeOptions;
  final ValueChanged<String?>? onPlaceChanged;

  final int resultCount;
  final VoidCallback onReset;

  const FormsFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.searchHint,
    this.showSearch = true,
    required this.statusValue,
    required this.onStatusChanged,
    required this.dateLabel,
    required this.onPickDateRange,
    required this.showPlaceFilter,
    required this.placeValue,
    required this.placeOptions,
    required this.onPlaceChanged,
    required this.resultCount,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D9D9).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (showSearch)
            TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: searchHint,
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8FBFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          if (showSearch) const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _dropdownShell(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: statusValue,
                    onChanged: onStatusChanged,
                    items: const [
                      DropdownMenuItem(value: 'Tous', child: Text('Statut: Tous')),
                      DropdownMenuItem(
                        value: 'brouillon',
                        child: Text('Statut: brouillon'),
                      ),
                      DropdownMenuItem(
                        value: 'soumis',
                        child: Text('Statut: soumis'),
                      ),
                    ],
                  ),
                ),
              ),
              _dropdownShell(
                child: InkWell(
                  onTap: onPickDateRange,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.date_range_rounded, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          dateLabel,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showPlaceFilter)
                _dropdownShell(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: placeValue,
                      onChanged: onPlaceChanged,
                      items: placeOptions
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: p,
                              child: Text(
                                p == 'Tous' ? 'Lieu: Tous' : p,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$resultCount formulaires',
                  style: const TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: onReset,
                child: const Text('Reinitialiser'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdownShell({required Widget child}) {
    return SizedBox(
      width: 190,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: child,
      ),
    );
  }
}
