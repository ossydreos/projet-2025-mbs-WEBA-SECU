import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/data/models/vehicule_type.dart';
import 'package:my_mobility_services/data/services/vehicle_service.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';
import 'package:my_mobility_services/widgets/admin/admin_navbar.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() =>
      _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  final VehicleService _vehicleService = VehicleService();
  List<VehiculeType> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final vehicles = await _vehicleService.getAllVehicles();
      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Erreur lors du chargement des véhicules: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: AppLocalizations.of(context).vehicleManagement,
          actions: [
            IconButton(
              onPressed: _showAddVehicleDialog,
              icon: Icon(Icons.add, color: AppColors.accent),
              tooltip: AppLocalizations.of(context).addVehicle,
            ),
            IconButton(
              onPressed: _loadVehicles,
              icon: Icon(Icons.refresh, color: AppColors.accent),
              tooltip: AppLocalizations.of(context).refresh,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              )
            : _buildContent(),
        bottomNavigationBar: AdminBottomNavigationBar(
          currentIndex: 2,
          onTap: _handleNavigation,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_vehicles.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statistiques
          _buildStatsHeader(),
          const SizedBox(height: 24),

          // Liste des véhicules
          _buildVehiclesList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 80, color: AppColors.textWeak),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).noVehicles,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).startByAddingVehicle,
            style: TextStyle(fontSize: 14, color: AppColors.textWeak),
          ),
          const SizedBox(height: 24),
          GlassButton(
            label: AppLocalizations.of(context).addVehicle,
            onPressed: _showAddVehicleDialog,
            primary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    final activeCount = _vehicles.where((v) => v.isActive).length;
    final inactiveCount = _vehicles.length - activeCount;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              AppLocalizations.of(context).total,
              _vehicles.length.toString(),
              Icons.directions_car,
              AppColors.accent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              AppLocalizations.of(context).active,
              activeCount.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              AppLocalizations.of(context).inactive,
              inactiveCount.toString(),
              Icons.cancel,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textStrong,
          ),
        ),
        Text(title, style: TextStyle(fontSize: 12, color: AppColors.textWeak)),
      ],
    );
  }

  Widget _buildVehiclesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).availableVehicles,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<VehiculeType>>(
          stream: _vehicleService.getVehiclesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                snapshot.data == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Erreur: ${snapshot.error}',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            final vehicles = snapshot.data ?? [];
            return Column(
              children: vehicles
                  .map((vehicle) => _buildVehicleCard(vehicle))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVehicleCard(VehiculeType vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icône du véhicule
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: vehicle.isActive
                    ? AppColors.accent.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: vehicle.isActive ? AppColors.accent : Colors.grey,
                  width: 1,
                ),
              ),
              child: Icon(
                vehicle.icon,
                color: vehicle.isActive ? AppColors.accent : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Informations du véhicule
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vehicle.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: vehicle.isActive
                                ? AppColors.textStrong
                                : Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: vehicle.isActive
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          vehicle.isActive ? AppLocalizations.of(context).active : AppLocalizations.of(context).inactive,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: vehicle.isActive ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${vehicle.capacityDisplay} • ${vehicle.luggageDisplay}',
                    style: TextStyle(
                      fontSize: 12,
                      color: vehicle.isActive
                          ? AppColors.textWeak
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicle.priceDisplay,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Boutons d'action
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _showEditVehicleDialog(vehicle),
                  icon: Icon(Icons.edit, color: AppColors.accent, size: 18),
                  tooltip: AppLocalizations.of(context).modify,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                IconButton(
                  onPressed: () => _toggleVehicleStatus(vehicle),
                  icon: Icon(
                    vehicle.isActive ? Icons.pause : Icons.play_arrow,
                    color: vehicle.isActive ? Colors.orange : Colors.green,
                    size: 18,
                  ),
                  tooltip: vehicle.isActive ? AppLocalizations.of(context).deactivate : AppLocalizations.of(context).activate,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                IconButton(
                  onPressed: () => _showDeleteVehicleDialog(vehicle),
                  icon: Icon(Icons.delete, color: Colors.red, size: 18),
                  tooltip: AppLocalizations.of(context).delete,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVehicleDialog() {
    _showVehicleDialog();
  }

  void _showEditVehicleDialog(VehiculeType vehicle) {
    _showVehicleDialog(vehicle: vehicle);
  }

  void _showVehicleDialog({VehiculeType? vehicle}) {
    final isEditing = vehicle != null;
    final nameController = TextEditingController(text: vehicle?.name ?? '');
    final descriptionController = TextEditingController(
      text: vehicle?.description ?? '',
    );
    final priceController = TextEditingController(
      text: vehicle?.pricePerKm.toString() ?? '',
    );
    final maxPassengersController = TextEditingController(
      text: vehicle?.maxPassengers.toString() ?? '4',
    );
    final maxLuggageController = TextEditingController(
      text: vehicle?.maxLuggage.toString() ?? '2',
    );
    final imageUrlController = TextEditingController(
      text: vehicle?.imageUrl ?? '',
    );
    VehicleCategory selectedCategory =
        vehicle?.category ?? VehicleCategory.economique;
    IconData selectedIcon = vehicle?.icon ?? Icons.directions_car_outlined;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: GlassContainer(
              borderRadius: BorderRadius.circular(24),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEditing ? AppLocalizations.of(context).editVehicle : AppLocalizations.of(context).newVehicle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nom du véhicule
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).vehicleName,
                        hintText: AppLocalizations.of(
                          context,
                        ).vehicleNameExample,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: 'Nom visible par les utilisateurs',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).description,
                        hintText: AppLocalizations.of(
                          context,
                        ).vehicleDescriptionHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Catégorie
                    DropdownButtonFormField<VehicleCategory>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).category,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: VehicleCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.categoryInFrench),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          selectedCategory = value;
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Prix par kilomètre
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).pricePerKmEuro,
                        hintText: AppLocalizations.of(context).priceExample,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Capacité passagers et bagages
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: maxPassengersController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context).maxPassengers,
                              hintText: AppLocalizations.of(context).four,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: maxLuggageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context).maxLuggage,
                              hintText: AppLocalizations.of(context).two,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // URL de l'image
                    TextField(
                      controller: imageUrlController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).imageUrl,
                        hintText: AppLocalizations.of(context).imageUrlExample,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sélection d'icône
                    Text(
                      'Icône du véhicule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          [
                                Icons.directions_car_outlined,
                                Icons.airport_shuttle,
                                Icons.directions_car,
                                Icons.motorcycle,
                                Icons.bus_alert,
                                Icons.local_taxi,
                                Icons.two_wheeler,
                                Icons.directions_bus,
                              ]
                              .map(
                                (icon) => GestureDetector(
                                  onTap: () {
                                    print('Icon tapped: $icon');
                                    setState(() {
                                      selectedIcon = icon;
                                      print(
                                        'Selected icon updated to: $selectedIcon',
                                      );
                                    });
                                  },
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: selectedIcon == icon
                                          ? AppColors.accent.withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selectedIcon == icon
                                            ? AppColors.accent
                                            : Colors.grey,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: selectedIcon == icon
                                          ? AppColors.accent
                                          : Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 24),

                    // Boutons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Annuler',
                            style: TextStyle(color: AppColors.textWeak),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () => _saveVehicle(
                            nameController.text,
                            descriptionController.text,
                            selectedCategory,
                            double.tryParse(priceController.text) ?? 0.0,
                            int.tryParse(maxPassengersController.text) ?? 4,
                            int.tryParse(maxLuggageController.text) ?? 2,
                            imageUrlController.text,
                            selectedIcon,
                            vehicle,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isEditing
                                ? AppLocalizations.of(context).modify
                                : AppLocalizations.of(context).create,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveVehicle(
    String name,
    String description,
    VehicleCategory category,
    double pricePerKm,
    int maxPassengers,
    int maxLuggage,
    String imageUrl,
    IconData icon,
    VehiculeType? existingVehicle,
  ) async {
    if (name.isEmpty || pricePerKm <= 0) {
      _showErrorSnackBar('Veuillez remplir tous les champs obligatoires');
      return;
    }

    try {
      if (existingVehicle != null) {
        // Modification
        final updatedVehicle = existingVehicle.copyWith(
          name: name,
          description: description,
          category: category,
          pricePerKm: pricePerKm,
          maxPassengers: maxPassengers,
          maxLuggage: maxLuggage,
          imageUrl: imageUrl,
          icon: icon,
          isActive: true, // Toujours actif lors de la modification
        );

        final success = await _vehicleService.updateVehicle(updatedVehicle);
        if (success) {
          Navigator.pop(context);
          _showSuccessSnackBar('Véhicule modifié avec succès');
        } else {
          _showErrorSnackBar('Erreur lors de la modification');
        }
      } else {
        // Création
        final newVehicle = VehiculeType(
          id: '',
          name: name,
          description: description,
          category: category,
          pricePerKm: pricePerKm,
          maxPassengers: maxPassengers,
          maxLuggage: maxLuggage,
          imageUrl: imageUrl,
          icon: icon,
          isActive: true, // Toujours actif lors de la création
          createdAt: DateTime.now(),
        );

        final id = await _vehicleService.createVehicle(newVehicle);
        if (id != null) {
          Navigator.pop(context);
          _showSuccessSnackBar('Véhicule créé avec succès');
        } else {
          _showErrorSnackBar('Erreur lors de la création');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    }
  }

  Future<void> _toggleVehicleStatus(VehiculeType vehicle) async {
    try {
      final success = await _vehicleService.updateVehicle(
        vehicle.copyWith(isActive: !vehicle.isActive),
      );

      if (success) {
        _showSuccessSnackBar(
          'Véhicule ${vehicle.isActive ? 'désactivé' : 'activé'} avec succès',
        );
      } else {
        _showErrorSnackBar('Erreur lors du changement de statut');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    }
  }

  void _showDeleteVehicleDialog(VehiculeType vehicle) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Supprimer le véhicule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Êtes-vous sûr de vouloir supprimer le véhicule "${vehicle.name}" ?',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textWeak),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Annuler',
                      style: TextStyle(color: AppColors.textWeak),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _deleteVehicle(vehicle);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context).delete),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteVehicle(VehiculeType vehicle) async {
    try {
      final success = await _vehicleService.deleteVehicle(vehicle.id);
      if (success) {
        _showSuccessSnackBar('Véhicule supprimé avec succès');
      } else {
        _showErrorSnackBar('Erreur lors de la suppression');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    }
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/admin/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/admin/trajets');
        break;
      case 2:
        // Déjà sur cette page
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/admin/profile');
        break;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
