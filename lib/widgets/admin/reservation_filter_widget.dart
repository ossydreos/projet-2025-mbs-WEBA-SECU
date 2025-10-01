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
    if (oldWidget.currentFilter != widget.currentFilter ||
        oldWidget.isUpcoming != widget.isUpcoming) {
      setState(() {
        _currentFilter = widget.currentFilter;
      });
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
        isUpcoming: widget.isUpcoming,
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
      key: ValueKey(
        'filter_widget_${widget.isUpcoming}_${_currentFilter.hashCode}',
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Bouton de filtrage - différent selon l'onglet
          Expanded(
            child: _FilterButton(
              key: ValueKey(
                'filter_btn_${widget.isUpcoming}_${_currentFilter.hasActiveFilter}',
              ),
              label: widget.isUpcoming
                  ? 'Filtres à venir'
                  : 'Filtres terminées',
              icon: widget.isUpcoming ? Icons.schedule : Icons.history,
              isActive: _currentFilter.hasActiveFilter,
              onTap: _showFilterDialog,
            ),
          ),
          const SizedBox(width: 12),

          // Bouton de tri - complètement différent selon l'onglet
          Expanded(
            child: _FilterButton(
              key: ValueKey(
                'sort_btn_${widget.isUpcoming}_${_currentFilter.sortType.name}',
              ),
              label: widget.isUpcoming ? 'Trier par départ' : 'Trier par fin',
              icon: widget.isUpcoming ? Icons.schedule : Icons.history,
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
    super.key,
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
                  // Type de réservation - titre différent selon l'onglet
                  _buildSectionTitle(
                    widget.isUpcoming ? 'Type de demande' : 'Type de course',
                  ),
                  const SizedBox(height: 12),
                  _buildTypeOptions(),

                  const SizedBox(height: 24),

                  // Filtres complètement différents selon l'onglet
                  if (widget.isUpcoming) ...[
                    // Pas de filtres supplémentaires pour les courses à venir
                  ] else ...[
                    // Pas de filtres supplémentaires pour les courses terminées
                  ],

                  // Plage de dates - titre différent selon l'onglet
                  _buildSectionTitle(
                    widget.isUpcoming ? 'Dates de départ' : 'Dates de fin',
                  ),
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

  Widget _buildTypeOptions() {
    // Types de courses identiques pour les deux onglets
    final typeOptions = [
      (ReservationTypeFilter.all, 'Toutes les courses', Icons.all_inclusive),
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
        // Date de début - label différent selon l'onglet
        _buildDatePicker(
          widget.isUpcoming ? 'Départ à partir du' : 'Fin à partir du',
          _tempFilter.startDate,
          (date) {
            setState(() {
              _tempFilter = _tempFilter.copyWith(startDate: date);
            });
          },
        ),
        const SizedBox(height: 16),

        // Date de fin - label différent selon l'onglet
        _buildDatePicker(
          widget.isUpcoming ? 'Départ jusqu\'au' : 'Fin jusqu\'au',
          _tempFilter.endDate,
          (date) {
            setState(() {
              _tempFilter = _tempFilter.copyWith(endDate: date);
            });
          },
        ),
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
  final bool isUpcoming;
  final Function(ReservationSortType) onSortChanged;

  const _SortBottomSheet({
    required this.currentSort,
    required this.isUpcoming,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sortOptions = isUpcoming
        ? [
            // Options de tri pour les courses à venir - complètement différentes
            (
              ReservationSortType.dateAscending,
              'Départ le plus proche',
              Icons.schedule,
            ),
            (
              ReservationSortType.dateDescending,
              'Départ le plus lointain',
              Icons.schedule,
            ),
            (
              ReservationSortType.priceDescending,
              'Prix le plus élevé',
              Icons.trending_up,
            ),
            (
              ReservationSortType.priceAscending,
              'Prix le plus bas',
              Icons.trending_down,
            ),
          ]
        : [
            // Options de tri pour les courses terminées - complètement différentes
            (
              ReservationSortType.dateDescending,
              'Fin la plus récente',
              Icons.history,
            ),
            (
              ReservationSortType.dateAscending,
              'Fin la plus ancienne',
              Icons.history,
            ),
            (
              ReservationSortType.priceDescending,
              'Prix le plus élevé',
              Icons.trending_up,
            ),
            (
              ReservationSortType.priceAscending,
              'Prix le plus bas',
              Icons.trending_down,
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
                Icon(
                  isUpcoming ? Icons.schedule : Icons.history,
                  color: AppColors.accent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  isUpcoming
                      ? 'Options de tri - Départ'
                      : 'Options de tri - Historique',
                  style: const TextStyle(
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
