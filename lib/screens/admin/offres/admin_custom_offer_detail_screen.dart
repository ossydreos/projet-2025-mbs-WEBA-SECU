import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/data/models/custom_offer.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/custom_offer_service.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';
import 'package:my_mobility_services/data/services/vehicle_service.dart';
import 'package:my_mobility_services/data/models/vehicule_type.dart';

class AdminCustomOfferDetailScreen extends StatefulWidget {
  final CustomOffer offer;

  const AdminCustomOfferDetailScreen({
    super.key,
    required this.offer,
  });

  @override
  State<AdminCustomOfferDetailScreen> createState() => _AdminCustomOfferDetailScreenState();
}

class _AdminCustomOfferDetailScreenState extends State<AdminCustomOfferDetailScreen> {
  final CustomOfferService _customOfferService = CustomOfferService();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isProcessing = false;
  final VehicleService _vehicleService = VehicleService();
  VehiculeType? _offerVehicle;
  
  // Variables pour la modification
  late DateTime _modifiedStartDate;
  TimeOfDay? _modifiedStartTime;
  late DateTime _modifiedEndDate;
  TimeOfDay? _modifiedEndTime;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.offer.proposedPrice != null) {
      _priceController.text = widget.offer.proposedPrice!.toStringAsFixed(2);
    }
    if (widget.offer.driverMessage != null) {
      _messageController.text = widget.offer.driverMessage!;
    }
    
    // Initialiser les dates/heures modifiables
    _modifiedStartDate = DateTime.now();
    _modifiedEndDate = DateTime.now().add(const Duration(hours: 1));
    _modifiedStartTime = TimeOfDay.now();
    _modifiedEndTime = TimeOfDay.now();

    // Charger le véhicule choisi s'il existe
    if ((widget.offer.vehicleId ?? '').isNotEmpty) {
      _vehicleService.getVehicleById(widget.offer.vehicleId!).then((v) {
        if (mounted) setState(() => _offerVehicle = v);
      });
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: 'Détail de l\'offre',
          actions: [
            if (widget.offer.status == 'pending')
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => _rejectOffer(),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statut
              _buildStatusCard(),
              const SizedBox(height: 16),
              
              // Informations du trajet
              _buildTripInfoCard(),
              const SizedBox(height: 16),
              
              // Informations temporelles (modifiables si en attente)
              if (widget.offer.status == ReservationStatus.pending)
                _buildEditableTimeInfoCard(),
              if (widget.offer.status != ReservationStatus.pending)
                _buildTimeInfoCard(),
              const SizedBox(height: 16),
              
              // Note du client
              if (widget.offer.clientNote != null && widget.offer.clientNote!.isNotEmpty)
                _buildClientNoteCard(),
              if (widget.offer.clientNote != null && widget.offer.clientNote!.isNotEmpty)
                const SizedBox(height: 16),
              
              // Prix proposé (si accepté)
              if (widget.offer.status == 'accepted' && widget.offer.proposedPrice != null)
                _buildPriceCard(),
              if (widget.offer.status == 'accepted' && widget.offer.proposedPrice != null)
                const SizedBox(height: 16),
              
              // Message du chauffeur (si présent)
              if (widget.offer.driverMessage != null && widget.offer.driverMessage!.isNotEmpty)
                _buildDriverMessageCard(),
              if (widget.offer.driverMessage != null && widget.offer.driverMessage!.isNotEmpty)
                const SizedBox(height: 16),
              
              // Prix proposé (si en attente)
              if (widget.offer.status == ReservationStatus.pending)
                _buildPriceCard(),
              if (widget.offer.status == ReservationStatus.pending)
                const SizedBox(height: 16),
              
              // Actions (si en attente)
              if (widget.offer.status == ReservationStatus.pending)
                _buildActionCard(),
              
              const SizedBox(height: 100), // Espace pour éviter que le contenu soit caché
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final l10n = AppLocalizations.of(context)!;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (widget.offer.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = l10n.customOfferStatusPending;
        break;
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = l10n.customOfferStatusAccepted;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = l10n.customOfferStatusRejected;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Inconnu';
    }

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child:                 Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.offer.userName ?? 'Client inconnu',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 14,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDateTime(widget.offer.createdAt),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildTripInfoCard() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations du trajet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            // Départ
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.offer.departure,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Destination
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.offer.destination,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Véhicule choisi (si présent) - rendu plus graphique
            if ((widget.offer.vehicleName ?? '').isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _getVehicleColor(_offerVehicle?.category)
                            .withOpacity(0.20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _offerVehicle?.icon ?? Icons.directions_car,
                        color: _getVehicleColor(_offerVehicle?.category),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.offer.vehicleName!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_offerVehicle != null)
                            Text(
                              '${_offerVehicle!.category.categoryInFrench} • ${_offerVehicle!.capacityDisplay}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Véhicule choisi',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Couleur par catégorie
  Color _getVehicleColor(VehicleCategory? category) {
    if (category == null) return AppColors.accent;
    switch (category) {
      case VehicleCategory.economique:
        return AppColors.accent;
      case VehicleCategory.van:
        return AppColors.accent2;
      case VehicleCategory.luxe:
        return AppColors.hot;
    }
  }

  Widget _buildTimeInfoCard() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Durée de service',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white70, size: 20),
                const SizedBox(width: 12),
                Text(
                  '${widget.offer.durationHours} heures et ${widget.offer.durationMinutes} minutes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableTimeInfoCard() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Durée de service',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                    });
                  },
                  icon: Icon(
                    _isEditing ? Icons.check : Icons.edit,
                    color: _isEditing ? Colors.green : Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_isEditing) ...[
              // Date et heure de début
              _buildDateTimeSelector(
                label: 'Date et heure de début',
                date: _modifiedStartDate,
                time: _modifiedStartTime ?? TimeOfDay.now(),
                onDateTap: _selectModifiedStartDate,
                onTimeTap: _selectModifiedStartTime,
              ),
              const SizedBox(height: 16),
              
              // Date et heure de fin
              _buildDateTimeSelector(
                label: 'Date et heure de fin',
                date: _modifiedEndDate,
                time: _modifiedEndTime ?? TimeOfDay.now(),
                onDateTap: _selectModifiedEndDate,
                onTimeTap: _selectModifiedEndTime,
              ),
            ] else ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white70, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '${widget.offer.durationHours} heures et ${widget.offer.durationMinutes} minutes',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Début: ${_formatDateTime(widget.offer.createdAt)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClientNoteCard() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Note du client',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                widget.offer.clientNote!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prix proposé',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).priceInChf,
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.euro, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverMessageCard() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Message du chauffeur',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Text(
                widget.offer.driverMessage!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard() {
    final l10n = AppLocalizations.of(context)!;
    
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Message pour le client
            TextField(
              controller: _messageController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: l10n.driverMessage,
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: AppLocalizations.of(context).optionalMessageForClient,
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 24),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _rejectOffer,
                    icon: const Icon(Icons.close),
                    label: Text(l10n.rejectOffer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _acceptOffer,
                    icon: const Icon(Icons.check),
                    label: Text(l10n.acceptOffer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Méthodes pour la sélection de date/heure modifiée
  Future<void> _selectModifiedStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _modifiedStartDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _modifiedStartDate = date;
      });
    }
  }

  Future<void> _selectModifiedStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _modifiedStartTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _modifiedStartTime = time;
      });
    }
  }

  Future<void> _selectModifiedEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _modifiedEndDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _modifiedEndDate = date;
      });
    }
  }

  Future<void> _selectModifiedEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _modifiedEndTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _modifiedEndTime = time;
      });
    }
  }

  Widget _buildDateTimeSelector({
    required String label,
    required DateTime date,
    required TimeOfDay time,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onDateTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2)
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${date.day}/${date.month}/${date.year}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onTimeTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2)
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        time != null 
                          ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                          : '--:--',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _acceptOffer() async {
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un prix'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un prix valide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Calculer la nouvelle durée si modifiée
      int newDurationHours = widget.offer.durationHours;
      int newDurationMinutes = widget.offer.durationMinutes;
      
      if (_isEditing && _modifiedStartTime != null && _modifiedEndTime != null) {
        final startDateTime = DateTime(_modifiedStartDate.year, _modifiedStartDate.month, _modifiedStartDate.day, _modifiedStartTime!.hour, _modifiedStartTime!.minute);
        final endDateTime = DateTime(_modifiedEndDate.year, _modifiedEndDate.month, _modifiedEndDate.day, _modifiedEndTime!.hour, _modifiedEndTime!.minute);
        final duration = endDateTime.difference(startDateTime);
        
        newDurationHours = duration.inHours;
        newDurationMinutes = duration.inMinutes % 60;
      }

      await _customOfferService.updateCustomOffer(
        widget.offer.id,
        status: 'confirmed',
        proposedPrice: price,
        driverMessage: _messageController.text.isNotEmpty ? _messageController.text : null,
        durationHours: newDurationHours,
        durationMinutes: newDurationMinutes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offre acceptée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _rejectOffer() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _customOfferService.updateCustomOffer(
        widget.offer.id,
        status: 'cancelled',
        driverMessage: _messageController.text.isNotEmpty ? _messageController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offre rejetée'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
