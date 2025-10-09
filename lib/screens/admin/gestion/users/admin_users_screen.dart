import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/screens/utilisateur/reservation/reservation_detail_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim();
      });
    });
  }

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
          title: 'Gestion des utilisateurs',
          actions: [
            IconButton(
              tooltip: 'Rechercher',
              onPressed: () async {
                await showSearchDialog(context);
              },
              icon: Icon(Icons.search, color: AppColors.accent),
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            var docs = snapshot.data?.docs ?? [];
            if (_query.isNotEmpty) {
              final q = _query.toLowerCase();
              docs = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final displayName = (data['displayName'] ?? '').toString();
                final firstName = (data['firstName'] ?? '').toString();
                final lastName = (data['lastName'] ?? '').toString();
                final nameField = (data['name'] ?? '').toString();
                final email = (data['email'] ?? '').toString();
                final fullName = ('$firstName $lastName').trim();
                final nameToShow = nameField.isNotEmpty
                    ? nameField
                    : (fullName.isNotEmpty
                          ? fullName
                          : (displayName.isNotEmpty ? displayName : ''));
                return nameToShow.toLowerCase().contains(q) ||
                    email.toLowerCase().contains(q);
              }).toList();
            }
            if (docs.isEmpty) {
              return const Center(child: Text('Aucun utilisateur'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                final uid = docs[i].id;
                final displayName = (data['displayName'] ?? '').toString();
                final firstName = (data['firstName'] ?? '').toString();
                final lastName = (data['lastName'] ?? '').toString();
                final nameField = (data['name'] ?? '').toString();
                final email = (data['email'] ?? '').toString();
                final photoUrl = (data['photoURL'] ?? data['photoUrl'] ?? '')
                    .toString();
                final fullName = ('$firstName $lastName').trim();
                final nameToShow = nameField.isNotEmpty
                    ? nameField
                    : (fullName.isNotEmpty
                          ? fullName
                          : (displayName.isNotEmpty ? displayName : ''));
                final firstChar =
                    (nameToShow.isNotEmpty
                            ? nameToShow[0]
                            : email.isNotEmpty
                            ? email[0]
                            : '?')
                        .toUpperCase();
                return GlassContainer(
                  padding: const EdgeInsets.all(12),
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.accent.withOpacity(0.2),
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl.isEmpty
                          ? Text(
                              firstChar,
                              style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      nameToShow.isNotEmpty ? nameToShow : 'Nom du client',
                      style: TextStyle(
                        color: AppColors.textStrong,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      email,
                      style: TextStyle(color: AppColors.textWeak),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white70,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminUserDetailScreen(userId: uid),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> showSearchDialog(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: GlassContainer(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom ou email',
                      hintStyle: TextStyle(color: AppColors.textWeak),
                      prefixIcon: Icon(Icons.search, color: AppColors.accent),
                      filled: true,
                      fillColor: AppColors.glass,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.glassStroke),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.accent),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Effacer',
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: Icon(Icons.clear, color: AppColors.hot),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AdminUserDetailScreen extends StatelessWidget {
  const AdminUserDetailScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    final users = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots();
    final reservations = FirebaseFirestore.instance
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(title: 'Fiche utilisateur'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profil
              StreamBuilder<DocumentSnapshot>(
                stream: users,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data == null) {
                    return const Text('Utilisateur introuvable');
                  }
                  final displayName = (data['displayName'] ?? '').toString();
                  final firstName = (data['firstName'] ?? '').toString();
                  final lastName = (data['lastName'] ?? '').toString();
                  final nameField = (data['name'] ?? '').toString();
                  final email = (data['email'] ?? '').toString();
                  final phone = (data['phoneNumber'] ?? data['number'] ?? '')
                      .toString();
                  final photoUrl = (data['photoURL'] ?? data['photoUrl'] ?? '')
                      .toString();

                  return GlassContainer(
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.accent.withOpacity(0.2),
                          backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl.isEmpty
                              ? Text(
                                  (displayName.isNotEmpty
                                          ? displayName[0]
                                          : '?')
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nameField.isNotEmpty
                                    ? nameField
                                    : ('$firstName $lastName'.trim().isNotEmpty
                                          ? '$firstName $lastName'
                                          : (displayName.isNotEmpty
                                                ? displayName
                                                : 'Nom du client')),
                                style: TextStyle(
                                  color: AppColors.textStrong,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (email.isNotEmpty)
                                Text(
                                  email,
                                  style: TextStyle(color: AppColors.textWeak),
                                ),
                              if (phone.isNotEmpty)
                                Text(
                                  phone,
                                  style: TextStyle(color: AppColors.textWeak),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Historique des modifications
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Historique des modifications',
                    style: TextStyle(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showHistoryDialog(context, userId),
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('Voir l\'historique'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent2.withOpacity(0.2),
                      foregroundColor: AppColors.accent2,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.accent2),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Réservations
              Text(
                'Réservations',
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: reservations,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Text('Aucune réservation');
                  }
                  return Column(
                    children: docs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final d = entry.value;
                      final data = d.data() as Map<String, dynamic>;
                      // Construire l'objet Reservation pour l'écran détail
                      final reservation = Reservation.fromMap({
                        ...data,
                        'id': d.id,
                      });
                      return Container(
                        margin: EdgeInsets.only(
                          bottom: index < docs.length - 1 ? 16 : 0,
                        ),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReservationDetailScreen(
                                reservation: reservation,
                              ),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: GlassContainer(
                            padding: const EdgeInsets.all(16),
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // En-tête avec véhicule et bouton info
                                Row(
                                  children: [
                                    // Icône véhicule
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.accent.withOpacity(
                                            0.3,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.directions_car,
                                        color: AppColors.accent,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Informations du véhicule
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            reservation.vehicleName,
                                            style: TextStyle(
                                              color: AppColors.textStrong,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${reservation.departure} → ${reservation.destination}',
                                            style: TextStyle(
                                              color: AppColors.textWeak,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Bouton d'informations détaillées
                                    _buildInfoButton(context, reservation),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Informations supplémentaires
                                Row(
                                  children: [
                                    // Statut
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          reservation.status,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _getStatusColor(
                                            reservation.status,
                                          ).withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        _getStatusText(reservation.status),
                                        style: TextStyle(
                                          color: _getStatusColor(
                                            reservation.status,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),

                                    const Spacer(),

                                    // Prix
                                    Text(
                                      '${reservation.totalPrice.toStringAsFixed(2)} CHF',
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Date et heure
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 14,
                                      color: AppColors.textWeak,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatDateTime(
                                        reservation.selectedDate,
                                        reservation.selectedTime,
                                      ),
                                      style: TextStyle(
                                        color: AppColors.textWeak,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Contre-offres (si vous avez une collection dédiée ou un champ)
              // Placeholder: à brancher si une collection `counter_offers` existe
              Text(
                'Offres personnalisées',
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Aucune donnée (à brancher selon votre modèle)'),
            ],
          ),
        ),
      ),
    );
  }

  // Bouton d'informations détaillées
  Widget _buildInfoButton(BuildContext context, Reservation reservation) {
    return GestureDetector(
      onTap: () => _showVehicleDetailsDialog(context, reservation),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.accent.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(Icons.info_outline, size: 16, color: AppColors.accent),
      ),
    );
  }

  // Dialog d'informations détaillées du véhicule
  void _showVehicleDetailsDialog(
    BuildContext context,
    Reservation reservation,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Row(
            children: [
              Icon(Icons.directions_car, color: AppColors.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Détails du véhicule',
                  style: TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Informations du véhicule
                _buildDetailSection(
                  'Véhicule',
                  Icons.directions_car,
                  reservation.vehicleName,
                ),
                const SizedBox(height: 12),

                // Trajet
                _buildDetailSection(
                  'Départ',
                  Icons.location_on,
                  reservation.departure,
                ),
                const SizedBox(height: 8),
                _buildDetailSection(
                  'Destination',
                  Icons.flag,
                  reservation.destination,
                ),
                const SizedBox(height: 12),

                // Date et heure
                _buildDetailSection(
                  'Date',
                  Icons.calendar_today,
                  '${reservation.selectedDate.day}/${reservation.selectedDate.month}/${reservation.selectedDate.year}',
                ),
                const SizedBox(height: 8),
                _buildDetailSection(
                  'Heure',
                  Icons.schedule,
                  reservation.selectedTime,
                ),
                const SizedBox(height: 12),

                // Prix
                _buildDetailSection(
                  'Prix total',
                  Icons.attach_money,
                  '${reservation.totalPrice.toStringAsFixed(2)} CHF',
                ),
                const SizedBox(height: 8),
                _buildDetailSection(
                  'Méthode de paiement',
                  Icons.payment,
                  reservation.paymentMethod,
                ),
                const SizedBox(height: 12),

                // Statut
                _buildDetailSection(
                  'Statut',
                  Icons.info,
                  _getStatusText(reservation.status),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fermer', style: TextStyle(color: AppColors.accent)),
            ),
          ],
        );
      },
    );
  }

  // Section de détail dans le dialog
  Widget _buildDetailSection(String label, IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textWeak,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Couleur du statut
  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Colors.orange;
      case ReservationStatus.confirmed:
        return Colors.green;
      case ReservationStatus.inProgress:
        return AppColors.accent;
      case ReservationStatus.completed:
        return Colors.green;
      case ReservationStatus.cancelled:
        return Colors.red;
    }
  }

  // Texte du statut
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

  // Formatage de la date et heure
  String _formatDateTime(DateTime date, String time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);

    String dateText;
    if (selectedDay == today) {
      dateText = 'Aujourd\'hui';
    } else if (selectedDay == today.add(const Duration(days: 1))) {
      dateText = 'Demain';
    } else {
      dateText =
          '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }

    return '$dateText à $time';
  }

  // Méthode pour afficher l'historique des modifications
  void _showHistoryDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.history,
                  color: AppColors.accent2,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Historique des modifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Liste de l'historique
                SizedBox(
                  height: 400,
                  width: double.maxFinite,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('profile_history')
                        .orderBy('changedAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Aucun historique disponible',
                            style: TextStyle(color: AppColors.textWeak),
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final changedAt = (data['changedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.glass.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.glassStroke),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Modifié le ${changedAt.day}/${changedAt.month}/${changedAt.year} à ${changedAt.hour}:${changedAt.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textWeak,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: data['changedBy'] == 'admin' 
                                            ? AppColors.hot.withOpacity(0.2)
                                            : AppColors.accent.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        data['changedBy'] == 'admin' ? 'Admin' : 'Utilisateur',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: data['changedBy'] == 'admin' 
                                              ? AppColors.hot
                                              : AppColors.accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (data['name'] != null && data['name'].isNotEmpty)
                                  _buildHistoryField('Nom', data['name']),
                                if (data['email'] != null && data['email'].isNotEmpty)
                                  _buildHistoryField('Email', data['email']),
                                if (data['phone'] != null && data['phone'].isNotEmpty)
                                  _buildHistoryField('Téléphone', data['phone']),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Bouton fermer
                GlassButton(
                  label: 'Fermer',
                  onPressed: () => Navigator.pop(context),
                  primary: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textWeak,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
