import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_mobility_services/data/models/favorite_trip.dart';
import 'package:my_mobility_services/data/services/favorite_trip_service.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';
import 'package:my_mobility_services/widgets/address_suggestion_field.dart';

/// Écran d'ajout/édition de trajet favori
class AddEditFavoriteTripScreen extends StatefulWidget {
  final FavoriteTrip? favoriteTrip;

  const AddEditFavoriteTripScreen({
    super.key,
    this.favoriteTrip,
  });

  @override
  State<AddEditFavoriteTripScreen> createState() => _AddEditFavoriteTripScreenState();
}

class _AddEditFavoriteTripScreenState extends State<AddEditFavoriteTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final FavoriteTripService _favoriteTripService = FavoriteTripService();

  IconData _selectedIcon = Icons.place;
  bool _isLoading = false;
  String _departureAddress = '';
  String _arrivalAddress = '';
  LatLng? _departureCoordinates;
  LatLng? _arrivalCoordinates;

  bool get _isEditing => widget.favoriteTrip != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.favoriteTrip!.name;
      _departureAddress = widget.favoriteTrip!.departureAddress;
      _arrivalAddress = widget.favoriteTrip!.arrivalAddress;
      _selectedIcon = widget.favoriteTrip!.icon;
      _departureCoordinates = widget.favoriteTrip!.departureCoordinates;
      _arrivalCoordinates = widget.favoriteTrip!.arrivalCoordinates;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: _isEditing
              ? AppLocalizations.of(context).editFavoriteTrip
              : AppLocalizations.of(context).addFavoriteTrip,
          actions: [
            if (_isEditing)
              IconButton(
                onPressed: _isLoading ? null : _deleteTrip,
                icon: Icon(Icons.delete, color: Colors.red),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildForm(),
      ),
    );
  }

  /// Formulaire d'ajout/édition
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIconSelector(),
            const SizedBox(height: 24),
            _buildNameField(),
            const SizedBox(height: 16),
            _buildDepartureField(),
            const SizedBox(height: 16),
            _buildArrivalField(),
            const SizedBox(height: 32),
            _buildSaveButton(),
            const SizedBox(height: 16),
            if (_isEditing) _buildDeleteButton(),
          ],
        ),
      ),
    );
  }

  /// Sélecteur d'icône
  Widget _buildIconSelector() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppLocalizations.of(context).selectIcon,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textStrong,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: FavoriteTrip.getAvailableIcons().map((iconData) {
                final icon = iconData['icon'] as IconData;
                final name = iconData['name'] as String;
                final isSelected = icon == _selectedIcon;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withOpacity(0.2)
                          : AppColors.accent.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.accent.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.textWeak,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 8,
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.textWeak,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Champ nom
  Widget _buildNameField() {
    return GlassContainer(
      child: TextFormField(
        controller: _nameController,
        style: TextStyle(color: AppColors.textStrong),
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context).tripName,
          labelStyle: TextStyle(color: AppColors.textWeak),
          hintText: AppLocalizations.of(context).enterTripName,
          hintStyle: TextStyle(color: AppColors.textWeak.withOpacity(0.7)),
          prefixIcon: Icon(Icons.label, color: AppColors.accent),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return AppLocalizations.of(context).tripNameRequired;
          }
          if (value.trim().length < 2) {
            return AppLocalizations.of(context).tripNameTooShort;
          }
          return null;
        },
      ),
    );
  }

  /// Champ adresse de départ
  Widget _buildDepartureField() {
    return AddressSuggestionField(
      label: AppLocalizations.of(context).departureAddress,
      hint: AppLocalizations.of(context).enterDepartureAddress,
      prefixIcon: Icons.my_location,
      initialValue: _isEditing ? _departureAddress : null,
      onAddressSelected: (address, coordinates) {
        setState(() {
          _departureAddress = address;
          _departureCoordinates = coordinates;
        });
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return AppLocalizations.of(context).departureAddressRequired;
        }
        if (value.trim().length < 5) {
          return AppLocalizations.of(context).departureAddressTooShort;
        }
        return null;
      },
    );
  }

  /// Champ adresse d'arrivée
  Widget _buildArrivalField() {
    return AddressSuggestionField(
      label: AppLocalizations.of(context).arrivalAddress,
      hint: AppLocalizations.of(context).enterArrivalAddress,
      prefixIcon: Icons.location_on,
      initialValue: _isEditing ? _arrivalAddress : null,
      onAddressSelected: (address, coordinates) {
        setState(() {
          _arrivalAddress = address;
          _arrivalCoordinates = coordinates;
        });
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return AppLocalizations.of(context).arrivalAddressRequired;
        }
        if (value.trim().length < 5) {
          return AppLocalizations.of(context).arrivalAddressTooShort;
        }
        return null;
      },
    );
  }

  /// Bouton de sauvegarde
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: GlassButton(
        label: _isEditing
            ? AppLocalizations.of(context).updateTrip
            : AppLocalizations.of(context).addTrip,
        onPressed: _isLoading ? null : _saveTrip,
        primary: true,
      ),
    );
  }

  /// Bouton de suppression
  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      child: GlassButton(
        label: AppLocalizations.of(context).deleteTrip,
        onPressed: _isLoading ? null : _deleteTrip,
        primary: false,
        backgroundColor: Colors.red.withOpacity(0.1),
        textColor: Colors.red,
      ),
    );
  }

  /// Sauvegarder le trajet
  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Vérifier si le trajet existe déjà
      final exists = await _favoriteTripService.tripExists(
        departureAddress: _departureAddress.trim(),
        arrivalAddress: _arrivalAddress.trim(),
        excludeId: _isEditing ? widget.favoriteTrip!.id : null,
      );

      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).tripAlreadyExists),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (_isEditing) {
        // Mettre à jour le trajet existant
        await _favoriteTripService.updateFavoriteTrip(
          id: widget.favoriteTrip!.id,
          departureAddress: _departureAddress.trim(),
          arrivalAddress: _arrivalAddress.trim(),
          icon: _selectedIcon,
          name: _nameController.text.trim(),
          departureCoordinates: _departureCoordinates,
          arrivalCoordinates: _arrivalCoordinates,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).tripUpdated),
              backgroundColor: AppColors.accent,
            ),
          );
        }
      } else {
        // Créer un nouveau trajet
        await _favoriteTripService.addFavoriteTrip(
          departureAddress: _departureAddress.trim(),
          arrivalAddress: _arrivalAddress.trim(),
          icon: _selectedIcon,
          name: _nameController.text.trim(),
          departureCoordinates: _departureCoordinates,
          arrivalCoordinates: _arrivalCoordinates,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).tripAdded),
              backgroundColor: AppColors.accent,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Supprimer le trajet
  Future<void> _deleteTrip() async {
    if (!_isEditing) return;

    final confirmed = await showGlassConfirmDialog(
      context: context,
      title: AppLocalizations.of(context).deleteTrip,
      message: AppLocalizations.of(context).deleteTripConfirmation,
      confirmText: AppLocalizations.of(context).delete,
      cancelText: AppLocalizations.of(context).cancel,
      icon: Icons.delete,
      iconColor: Colors.red,
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _favoriteTripService.deleteFavoriteTrip(widget.favoriteTrip!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).tripDeleted),
            backgroundColor: AppColors.accent,
          ),
        );
        Navigator.pop(context);
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// Extension pour showGlassConfirmDialog
extension GlassConfirmDialog on BuildContext {
  Future<bool> showGlassConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
    required IconData icon,
    required Color iconColor,
  }) async {
    return await showDialog<bool>(
      context: this,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: iconColor, size: 48),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textWeak,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        label: cancelText,
                        onPressed: () => Navigator.pop(context, false),
                        primary: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassButton(
                        label: confirmText,
                        onPressed: () => Navigator.pop(context, true),
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
    ) ?? false;
  }
}
