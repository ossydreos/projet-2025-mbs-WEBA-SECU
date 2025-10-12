import 'package:flutter/material.dart';
import 'package:my_mobility_services/data/models/favorite_trip.dart';
import 'package:my_mobility_services/data/services/favorite_trip_service.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';
import 'add_edit_favorite_trip_screen.dart';

/// Écran de gestion des trajets favoris
class FavoriteTripsScreen extends StatefulWidget {
  const FavoriteTripsScreen({super.key});

  @override
  State<FavoriteTripsScreen> createState() => _FavoriteTripsScreenState();
}

class _FavoriteTripsScreenState extends State<FavoriteTripsScreen> {
  final FavoriteTripService _favoriteTripService = FavoriteTripService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: AppLocalizations.of(context).favoriteTrips,
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _buildFavoriteTripsList(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddTripDialog,
          backgroundColor: AppColors.accent,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  /// Barre de recherche
  Widget _buildSearchBar() {
    return GlassContainer(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: TextStyle(color: AppColors.textStrong),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).searchFavoriteTrips,
          hintStyle: TextStyle(color: AppColors.textWeak),
          prefixIcon: Icon(Icons.search, color: AppColors.accent),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: Icon(Icons.clear, color: AppColors.textWeak),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  /// Liste des trajets favoris
  Widget _buildFavoriteTripsList() {
    return StreamBuilder<List<FavoriteTrip>>(
      stream: _searchQuery.isEmpty
          ? _favoriteTripService.getFavoriteTrips()
          : _favoriteTripService.searchFavoriteTrips(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        final favoriteTrips = snapshot.data ?? [];

        if (favoriteTrips.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: favoriteTrips.length,
          itemBuilder: (context, index) {
            final trip = favoriteTrips[index];
            return _buildFavoriteTripCard(trip);
          },
        );
      },
    );
  }

  /// Carte d'un trajet favori
  Widget _buildFavoriteTripCard(FavoriteTrip trip) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTripDetails(trip),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec icône et nom
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(trip.icon, color: AppColors.accent, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textStrong,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(trip.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textWeak,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleMenuAction(value, trip),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: AppColors.accent, size: 20),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context).edit),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context).delete),
                            ],
                          ),
                        ),
                      ],
                      child: Icon(
                        Icons.more_vert,
                        color: AppColors.textWeak,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Adresses
                _buildAddressRow(
                  Icons.my_location,
                  AppLocalizations.of(context).departure,
                  trip.departureAddress,
                ),
                const SizedBox(height: 8),
                _buildAddressRow(
                  Icons.location_on,
                  AppLocalizations.of(context).arrivalAddress,
                  trip.arrivalAddress,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Ligne d'adresse
  Widget _buildAddressRow(IconData icon, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.accent, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textWeak,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textStrong,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// État vide
  Widget _buildEmptyState() {
    return Center(
      child: GlassContainer(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: AppColors.accent.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).noFavoriteTrips,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textStrong,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).noFavoriteTripsDescription,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textWeak,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GlassButton(
              label: AppLocalizations.of(context).addFirstFavoriteTrip,
              onPressed: _showAddTripDialog,
              primary: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Widget d'erreur
  Widget _buildErrorWidget(String error) {
    return Center(
      child: GlassContainer(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).error(''),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textWeak,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GlassButton(
              label: AppLocalizations.of(context).retry,
              onPressed: () {
                setState(() {});
              },
              primary: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Afficher le dialogue d'ajout de trajet
  void _showAddTripDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditFavoriteTripScreen(),
      ),
    );
  }

  /// Afficher les détails d'un trajet
  void _showTripDetails(FavoriteTrip trip) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône et nom
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(trip.icon, color: AppColors.accent, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  trip.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Adresses
                _buildDetailAddressRow(
                  Icons.my_location,
                  AppLocalizations.of(context).departure,
                  trip.departureAddress,
                ),
                const SizedBox(height: 16),
                _buildDetailAddressRow(
                  Icons.location_on,
                  AppLocalizations.of(context).arrivalAddress,
                  trip.arrivalAddress,
                ),
                const SizedBox(height: 24),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        label: AppLocalizations.of(context).edit,
                        onPressed: () {
                          Navigator.pop(context);
                          _editTrip(trip);
                        },
                        primary: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassButton(
                        label: AppLocalizations.of(context).use,
                        onPressed: () {
                          Navigator.pop(context);
                          _useTrip(trip);
                        },
                        primary: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Ligne d'adresse pour les détails
  Widget _buildDetailAddressRow(IconData icon, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.accent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textWeak,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textStrong,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Gérer les actions du menu
  void _handleMenuAction(String action, FavoriteTrip trip) {
    switch (action) {
      case 'edit':
        _editTrip(trip);
        break;
      case 'delete':
        _deleteTrip(trip);
        break;
    }
  }

  /// Éditer un trajet
  void _editTrip(FavoriteTrip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditFavoriteTripScreen(
          favoriteTrip: trip,
        ),
      ),
    );
  }


  /// Supprimer un trajet
  void _deleteTrip(FavoriteTrip trip) {
    showGlassConfirmDialog(
      context: context,
      title: AppLocalizations.of(context).deleteTrip,
      message: AppLocalizations.of(context).deleteTripConfirmation,
      confirmText: AppLocalizations.of(context).delete,
      cancelText: AppLocalizations.of(context).cancel,
      icon: Icons.delete,
      iconColor: Colors.red,
      onConfirm: () async {
        try {
          await _favoriteTripService.deleteFavoriteTrip(trip.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).tripDeleted),
                backgroundColor: AppColors.accent,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString()),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      onCancel: () => Navigator.pop(context),
    );
  }

  /// Utiliser un trajet (navigation vers la réservation)
  void _useTrip(FavoriteTrip trip) {
    // TODO: Implémenter la navigation vers l'écran de réservation
    // avec les adresses pré-remplies
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fonctionnalité à implémenter: Utiliser le trajet "${trip.name}"'),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  /// Formater une date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
