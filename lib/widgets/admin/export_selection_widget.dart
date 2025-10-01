import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/services/pdf_export_service.dart';

class ExportSelectionWidget extends StatefulWidget {
  final List<Reservation> reservations;
  final String title;
  final String? subtitle;
  final bool isAdmin;

  const ExportSelectionWidget({
    super.key,
    required this.reservations,
    required this.title,
    this.subtitle,
    this.isAdmin = false,
  });

  @override
  State<ExportSelectionWidget> createState() => _ExportSelectionWidgetState();
}

class _ExportSelectionWidgetState extends State<ExportSelectionWidget> {
  final Set<String> _selectedReservations = <String>{};
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    // Sélectionner toutes les réservations par défaut
    if (widget.reservations.isNotEmpty) {
      _selectedReservations.addAll(widget.reservations.map((r) => r.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exporter en PDF',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textStrong,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sélectionnez les courses à exporter',
                          style: TextStyle(fontSize: 14, color: AppColors.text),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.text),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Statistiques
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total: ${widget.reservations.length} courses',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textStrong,
                          ),
                        ),
                        Text(
                          'Sélectionnées: ${_selectedReservations.length}',
                          style: TextStyle(fontSize: 12, color: AppColors.text),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Montant total: ${_getTotalAmount().toStringAsFixed(2)} CHF',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Actions de sélection
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      label: 'Tout sélectionner',
                      onPressed: _selectAll,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassButton(
                      label: 'Tout désélectionner',
                      onPressed: _deselectAll,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Liste des réservations
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: AppColors.glass.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.glassStroke, width: 1),
                ),
                child: widget.reservations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: AppColors.text.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune course à exporter',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.text.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: widget.reservations.length,
                        itemBuilder: (context, index) {
                          final reservation = widget.reservations[index];
                          final isSelected = _selectedReservations.contains(
                            reservation.id,
                          );

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: _buildReservationItem(
                              reservation,
                              isSelected,
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 20),

              // Actions d'export
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      label: 'Aperçu PDF',
                      onPressed: _isExporting ? null : _previewPdf,
                      icon: Icons.visibility,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassButton(
                      label: 'Exporter PDF',
                      onPressed: _isExporting ? null : _exportPdf,
                      icon: Icons.download,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservationItem(Reservation reservation, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleSelection(reservation.id),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.glassStroke,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.glassStroke,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
            const SizedBox(width: 10),

            // Informations de la réservation
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${reservation.departure} → ${reservation.destination}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textStrong,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 6,
                    runSpacing: 3,
                    children: [
                      Text(
                        '${reservation.selectedDate.day}/${reservation.selectedDate.month}',
                        style: TextStyle(fontSize: 11, color: AppColors.text),
                      ),
                      Text(
                        reservation.selectedTime,
                        style: TextStyle(fontSize: 11, color: AppColors.text),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            reservation.status,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          _getStatusText(reservation.status),
                          style: TextStyle(
                            fontSize: 9,
                            color: _getStatusColor(reservation.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Prix
            Text(
              '${reservation.totalPrice.toStringAsFixed(0)} CHF',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectAll() {
    setState(() {
      _selectedReservations.clear();
      _selectedReservations.addAll(widget.reservations.map((r) => r.id));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedReservations.clear();
    });
  }

  void _toggleSelection(String reservationId) {
    setState(() {
      if (_selectedReservations.contains(reservationId)) {
        _selectedReservations.remove(reservationId);
      } else {
        _selectedReservations.add(reservationId);
      }
    });
  }

  double _getTotalAmount() {
    return widget.reservations
        .where((r) => _selectedReservations.contains(r.id))
        .fold(0.0, (sum, reservation) => sum + reservation.totalPrice);
  }

  String _getStatusText(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return 'En attente';
      case ReservationStatus.confirmed:
        return 'Confirmée';
      case ReservationStatus.inProgress:
        return 'En cours';
      case ReservationStatus.completed:
        return 'Terminée';
      case ReservationStatus.cancelled:
        return 'Annulée';
    }
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Colors.orange;
      case ReservationStatus.confirmed:
        return Colors.green;
      case ReservationStatus.inProgress:
        return Colors.blue;
      case ReservationStatus.completed:
        return Colors.green;
      case ReservationStatus.cancelled:
        return Colors.red;
    }
  }

  Future<void> _previewPdf() async {
    if (_selectedReservations.isEmpty) {
      _showSnackBar('Veuillez sélectionner au moins une course');
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final selectedReservations = widget.reservations
          .where((r) => _selectedReservations.contains(r.id))
          .toList();

      final pdfBytes = await PdfExportService.exportReservationsToPdf(
        reservations: selectedReservations,
        title: widget.title,
        subtitle: widget.subtitle,
        isAdmin: widget.isAdmin,
      );

      await PdfExportService.viewPdf(pdfBytes, 'export_courses');
    } catch (e) {
      _showSnackBar('Erreur lors de la génération du PDF: $e');
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _exportPdf() async {
    if (_selectedReservations.isEmpty) {
      _showSnackBar('Veuillez sélectionner au moins une course');
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final selectedReservations = widget.reservations
          .where((r) => _selectedReservations.contains(r.id))
          .toList();

      final pdfBytes = await PdfExportService.exportReservationsToPdf(
        reservations: selectedReservations,
        title: widget.title,
        subtitle: widget.subtitle,
        isAdmin: widget.isAdmin,
      );

      await PdfExportService.sharePdf(pdfBytes, 'export_courses');

      _showSnackBar('PDF exporté avec succès !');
    } catch (e) {
      _showSnackBar('Erreur lors de l\'export: $e');
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.accent),
    );
  }
}
