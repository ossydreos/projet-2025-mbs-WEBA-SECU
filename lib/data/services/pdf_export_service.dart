import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:my_mobility_services/data/models/reservation.dart';

class PdfExportService {
  /// Exporter une liste de réservations en PDF
  static Future<Uint8List> exportReservationsToPdf({
    required List<Reservation> reservations,
    required String title,
    String? subtitle,
    bool isAdmin = false,
  }) async {
    final pdf = pw.Document();

    // Charger la police personnalisée si disponible
    final font = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // En-tête
            _buildHeader(title, subtitle, fontBold),
            pw.SizedBox(height: 20),

            // Informations de l'export
            _buildExportInfo(reservations, font),
            pw.SizedBox(height: 20),

            // Tableau des réservations
            _buildReservationsTable(reservations, font, fontBold, isAdmin),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Construire l'en-tête du PDF
  static pw.Widget _buildHeader(
    String title,
    String? subtitle,
    pw.Font fontBold,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 40,
                height: 40,
                decoration: pw.BoxDecoration(
                  color: PdfColors.green,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'MBG',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    if (subtitle != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        subtitle,
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construire les informations de l'export
  static pw.Widget _buildExportInfo(
    List<Reservation> reservations,
    pw.Font font,
  ) {
    final now = DateTime.now();
    final totalAmount = reservations.fold<double>(
      0.0,
      (sum, reservation) => sum + reservation.totalPrice,
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Date d\'export: ${_formatDate(now)}',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Nombre de courses: ${reservations.length}',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Total: ${totalAmount.toStringAsFixed(2)} CHF',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construire le tableau des réservations
  static pw.Widget _buildReservationsTable(
    List<Reservation> reservations,
    pw.Font font,
    pw.Font fontBold,
    bool isAdmin,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5), // ID
        1: const pw.FlexColumnWidth(2), // Client
        2: const pw.FlexColumnWidth(3), // Trajet
        3: const pw.FlexColumnWidth(1.5), // Date
        4: const pw.FlexColumnWidth(1.5), // Heure
        5: const pw.FlexColumnWidth(1.5), // Statut
        6: const pw.FlexColumnWidth(1.5), // Prix
      },
      children: [
        // En-tête du tableau
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell('ID', fontBold, PdfColors.black),
            _buildTableCell('Client', fontBold, PdfColors.black),
            _buildTableCell('Trajet', fontBold, PdfColors.black),
            _buildTableCell('Date', fontBold, PdfColors.black),
            _buildTableCell('Heure', fontBold, PdfColors.black),
            _buildTableCell('Statut', fontBold, PdfColors.black),
            _buildTableCell('Prix', fontBold, PdfColors.black),
          ],
        ),
        // Lignes des réservations
        ...reservations.map(
          (reservation) => _buildReservationRow(reservation, font, isAdmin),
        ),
      ],
    );
  }

  /// Construire une cellule de tableau
  static pw.Widget _buildTableCell(String text, pw.Font font, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  /// Construire une ligne de réservation
  static pw.TableRow _buildReservationRow(
    Reservation reservation,
    pw.Font font,
    bool isAdmin,
  ) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.white),
      children: [
        _buildTableCell(
          reservation.id.length > 8
              ? reservation.id.substring(0, 8)
              : reservation.id,
          font,
          PdfColors.grey700,
        ),
        _buildTableCell(
          reservation.userName ?? 'Client',
          font,
          PdfColors.grey700,
        ),
        _buildTableCell(
          '${reservation.departure} → ${reservation.destination}',
          font,
          PdfColors.grey700,
        ),
        _buildTableCell(
          '${reservation.selectedDate.day}/${reservation.selectedDate.month}/${reservation.selectedDate.year}',
          font,
          PdfColors.grey700,
        ),
        _buildTableCell(reservation.selectedTime, font, PdfColors.grey700),
        _buildTableCell(
          _getStatusText(reservation.status),
          font,
          _getStatusColor(reservation.status),
        ),
        _buildTableCell(
          '${reservation.totalPrice.toStringAsFixed(2)} CHF',
          font,
          PdfColors.green800,
        ),
      ],
    );
  }

  /// Obtenir le texte du statut
  static String _getStatusText(ReservationStatus status) {
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

  /// Obtenir la couleur du statut
  static PdfColor _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return PdfColors.orange;
      case ReservationStatus.confirmed:
        return PdfColors.green;
      case ReservationStatus.inProgress:
        return PdfColors.blue;
      case ReservationStatus.completed:
        return PdfColors.green;
      case ReservationStatus.cancelled:
        return PdfColors.red;
    }
  }

  /// Formater une date
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Sauvegarder le PDF sur le device
  static Future<File> savePdfToDevice(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  /// Partager le PDF
  static Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: '$fileName.pdf');
  }

  /// Afficher le PDF dans une vue
  static Future<void> viewPdf(Uint8List pdfBytes, String fileName) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: fileName,
    );
  }
}
