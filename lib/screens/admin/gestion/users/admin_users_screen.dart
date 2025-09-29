import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/screens/utilisateur/reservation/reservation_detail_screen.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(title: 'Gestion des utilisateurs'),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs ?? [];
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
                    children: docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      // Construire l'objet Reservation pour l'écran détail
                      final reservation = Reservation.fromMap({
                        ...data,
                        'id': d.id,
                      });
                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReservationDetailScreen(
                              reservation: reservation,
                            ),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(12),
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.directions_car,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${reservation.departure} → ${reservation.destination}',
                                      style: TextStyle(
                                        color: AppColors.textStrong,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Statut: ${reservation.status.name}',
                                      style: TextStyle(
                                        color: AppColors.textWeak,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${reservation.totalPrice.toStringAsFixed(2)} CHF',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
}
