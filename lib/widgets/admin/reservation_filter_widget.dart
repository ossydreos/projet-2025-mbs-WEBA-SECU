import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/data/models/reservation_filter.dart';

class ReservationFilterWidget extends StatefulWidget {
  final ReservationFilter currentFilter;
  final Function(ReservationFilter) onFilterChanged;
  final bool
  isUpcoming; // true pour les courses à venir, false pour les terminées

  const ReservationFilterWidget({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.isUpcoming,
  });

  @override
  State<ReservationFilterWidget> createState() =>
      _ReservationFilterWidgetState();
}

class _ReservationFilterWidgetState extends State<ReservationFilterWidget> {
  late ReservationFilter _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.currentFilter;
  }

  @override
  void didUpdateWidget(ReservationFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentFilter != widget.currentFilter) {
      _currentFilter = widget.currentFilter;
    }
  }

  void _updateFilter(ReservationFilter newFilter) {
    setState(() {
      _currentFilter = newFilter;
    });
    widget.onFilterChanged(newFilter);
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        currentFilter: _currentFilter,
        isUpcoming: widget.isUpcoming,
        onFilterChanged: _updateFilter,
      ),
    );
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SortBottomSheet(
        currentSort: _currentFilter.sortType,
        onSortChanged: (sortType) {
          _updateFilter(_currentFilter.copyWith(sortType: sortType));
        },
      ),
    );
  }

  void _clearFilters() {
    _updateFilter(ReservationFilter(isUpcoming: widget.isUpcoming));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Bouton de filtrage
          Expanded(
            child: _FilterButton(
              label: 'Filtres',
              icon: Icons.filter_list,
              isActive: _currentFilter.hasActiveFilter,
              onTap: _showFilterDialog,
            ),
          ),
          const SizedBox(width: 12),

          // Bouton de tri
          Expanded(
            child: _FilterButton(
              label: _currentFilter.getSortDescription(),
              icon: Icons.sort,
              isActive: false,
              onTap: _showSortDialog,
            ),
          ),

          // Bouton de réinitialisation
          if (_currentFilter.hasActiveFilter) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _clearFilters,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.hot.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.hot.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(Icons.clear, color: AppColors.hot, size: 20),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent.withOpacity(0.2) : AppColors.glass,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.accent : AppColors.glassStroke,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.accent : AppColors.textWeak,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? AppColors.accent : AppColors.textStrong,
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final ReservationFilter currentFilter;
  final bool isUpcoming;
  final Function(ReservationFilter) onFilterChanged;

  const _FilterBottomSheet({
    required this.currentFilter,
    required this.isUpcoming,
    required this.onFilterChanged,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late ReservationFilter _tempFilter;

  @override
  void initState() {
    super.initState();
    _tempFilter = widget.currentFilter;
  }

  void _applyFilter() {
    widget.onFilterChanged(_tempFilter);
    Navigator.pop(context);
  }

  void _resetFilter() {
    setState(() {
      _tempFilter = ReservationFilter(isUpcoming: widget.isUpcoming);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textWeak,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: AppColors.accent, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Filtres ${widget.isUpcoming ? 'à venir' : 'terminées'}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetFilter,
                  child: Text(
                    'Réinitialiser',
                    style: TextStyle(color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type de réservation
                  _buildSectionTitle('Type de réservation'),
                  const SizedBox(height: 12),
                  _buildTypeOptions(),

                  const SizedBox(height: 24),

                  // Plage de dates
                  _buildSectionTitle('Plage de dates'),
                  const SizedBox(height: 12),
                  _buildDateRangeOptions(),
                ],
              ),
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textWeak,
                      side: BorderSide(color: AppColors.glassStroke),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Appliquer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFilterOption(
    String title,
    ReservationFilterType type,
    IconData icon,
  ) {
    final isSelected = _tempFilter.filterType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tempFilter = _tempFilter.copyWith(filterType: type);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.glassStroke,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accent : AppColors.textWeak,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.accent : Colors.white,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: AppColors.accent, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOptions() {
    final typeOptions = [
      (ReservationTypeFilter.all, 'Tous les types', Icons.all_inclusive),
      (ReservationTypeFilter.simple, 'Demande simple', Icons.receipt),
      (ReservationTypeFilter.customOffer, 'Offre personnalisée', Icons.star),
      (ReservationTypeFilter.counterOffer, 'Contre offre', Icons.handshake),
    ];

    return Column(
      children: typeOptions.map((option) {
        final (type, title, icon) = option;
        final isSelected = _tempFilter.typeFilter == type;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _tempFilter = _tempFilter.copyWith(typeFilter: type);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.glassStroke,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? AppColors.accent : AppColors.textWeak,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? AppColors.accent : Colors.white,
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check, color: AppColors.accent, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateRangeOptions() {
    return Column(
      children: [
        // Date de début
        _buildDatePicker('Date de début', _tempFilter.startDate, (date) {
          setState(() {
            _tempFilter = _tempFilter.copyWith(startDate: date);
          });
        }),
        const SizedBox(height: 16),

        // Date de fin
        _buildDatePicker('Date de fin', _tempFilter.endDate, (date) {
          setState(() {
            _tempFilter = _tempFilter.copyWith(endDate: date);
          });
        }),
      ],
    );
  }

  Widget _buildDatePicker(
    String title,
    DateTime? date,
    Function(DateTime?) onChanged,
  ) {
    return GestureDetector(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.accent,
                  onPrimary: Colors.white,
                  surface: Colors.black87,
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (selectedDate != null) {
          onChanged(selectedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassStroke, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textWeak,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Sélectionner une date',
                    style: TextStyle(
                      color: date != null ? Colors.white : AppColors.textWeak,
                      fontSize: 14,
                      fontWeight: date != null
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(Icons.clear, color: AppColors.hot, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

class _SortBottomSheet extends StatelessWidget {
  final ReservationSortType currentSort;
  final Function(ReservationSortType) onSortChanged;

  const _SortBottomSheet({
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sortOptions = [
      (
        ReservationSortType.dateDescending,
        'Date (récente → ancienne)',
        Icons.arrow_downward,
      ),
      (
        ReservationSortType.dateAscending,
        'Date (ancienne → récente)',
        Icons.arrow_upward,
      ),
      (
        ReservationSortType.priceDescending,
        'Prix (décroissant)',
        Icons.arrow_downward,
      ),
      (
        ReservationSortType.priceAscending,
        'Prix (croissant)',
        Icons.arrow_upward,
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textWeak,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.sort, color: AppColors.accent, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Trier par',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Options
          ...sortOptions.map((option) {
            final (sortType, title, icon) = option;
            final isSelected = currentSort == sortType;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: GestureDetector(
                onTap: () {
                  onSortChanged(sortType);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.glassStroke,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textWeak,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: isSelected ? AppColors.accent : Colors.white,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check, color: AppColors.accent, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
