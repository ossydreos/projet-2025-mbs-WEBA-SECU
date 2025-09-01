import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// TODO: Intégrer Firebase Auth
// import 'package:firebase_auth/firebase_auth.dart';

// TODO: Intégrer Firestore pour les données utilisateur
// import 'package:cloud_firestore/cloud_firestore.dart';

// TODO: Services à implémenter avec Firebase
/*
class AuthService {
  User? get utilisateurActuel => FirebaseAuth.instance.currentUser;
  Future<void> deconnexion() async {
    await FirebaseAuth.instance.signOut();
  }
}

class DataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<Utilisateur> obtenirUtilisateur(String uid) async {
    final doc = await _firestore.collection('utilisateurs').doc(uid).get();
    return Utilisateur.fromMap(doc.data()!);
  }
}
*/

// Modèle utilisateur (à adapter selon votre structure Firebase)
class Utilisateur {
  final String uid;
  final String nom;
  final String email;
  final String telephone;
  final DateTime dateCreation;
  final double notation;

  Utilisateur({
    required this.uid,
    required this.nom,
    required this.email,
    required this.telephone,
    required this.dateCreation,
    this.notation = 0.0,
  });

  // TODO: Ajouter les méthodes Firebase
  /*
  factory Utilisateur.fromMap(Map<String, dynamic> map) {
    return Utilisateur(
      uid: map['uid'],
      nom: map['nom'],
      email: map['email'],
      telephone: map['telephone'],
      dateCreation: (map['dateCreation'] as Timestamp).toDate(),
      notation: map['notation']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nom': nom,
      'email': email,
      'telephone': telephone,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'notation': notation,
    };
  }
  */
}

/// Écran de profil - Version mockée (sans Firebase)
class EcranProfile extends StatefulWidget {
  const EcranProfile({super.key});

  @override
  State<EcranProfile> createState() => _EcranProfilState();
}

class _EcranProfilState extends State<EcranProfile> {
  // Données mockées - TODO: Remplacer par les vraies données Firebase
  final Utilisateur _utilisateur = Utilisateur(
    uid: 'mock_uid_123',
    nom: 'bob teste',
    email: 'bob@teste.ch',
    telephone: '+41 79 123 45 67',
    dateCreation: DateTime(2024, 1, 10),
    notation: 5.0,
  );

  // TODO: États pour Firebase
  // bool _loadingLogout = false;
  // bool _loadingDelete = false;

  // TODO: Méthodes Firebase à implémenter
  /*
  Future<void> _seDeconnecter() async {
    final confirmation = await _afficherDialogueConfirmation(
      'Se déconnecter',
      'Voulez-vous vraiment vous déconnecter ?',
      'Se déconnecter',
    );

    if (confirmation != true) return;
    setState(() => _loadingLogout = true);

    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      // Navigation vers écran de connexion
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingLogout = false);
      _afficherSnack('Erreur de déconnexion : $e', isError: true);
    }
  }

  Future<void> _supprimerCompte() async {
    final confirmation = await _afficherDialogueConfirmation(
      'Supprimer le compte',
      'Cette action est définitive et ne peut pas être annulée.',
      'Supprimer',
      isDanger: true,
    );

    if (confirmation != true) return;
    setState(() => _loadingDelete = true);

    try {
      // Supprimer les données Firestore
      await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(_utilisateur.uid)
          .delete();
      
      // Supprimer le compte Auth
      await FirebaseAuth.instance.currentUser?.delete();
      
      if (!mounted) return;
      _afficherSnack('Compte supprimé avec succès', isError: false);
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDelete = false);
      _afficherSnack('Erreur lors de la suppression', isError: true);
    }
  }
  */

  // Méthodes mockées pour la démo
  void _seDecconnecterMock() {
    _afficherSnack('Déconnexion (demo mode)', isError: false);
    // TODO: Remplacer par la vraie déconnexion Firebase
  }

  void _supprimerCompteMock() {
    _afficherSnack('Suppression de compte (demo mode)', isError: false);
    // TODO: Remplacer par la vraie suppression Firebase
  }

  Future<bool?> _afficherDialogueConfirmation(
    String titre,
    String contenu,
    String actionText, {
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E3A47),
        title: Text(titre, style: const TextStyle(color: Colors.white)),
        content: Text(contenu, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Color(0xFF476582)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger
                  ? Colors.red
                  : const Color.fromARGB(255, 218, 255, 52),
              foregroundColor: Colors.black,
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  void _afficherSnack(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red
            : const Color.fromARGB(255, 218, 255, 52),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildContent(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          _buildUpdateAccountCard(),
          _buildMenuSection(),
          _buildLocationSection(),
          _buildSettingsSection(),
          _buildAccountActions(),
          const SizedBox(height: 100), // Espace pour la bottom nav
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF2E3A47),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 40, color: Color(0xFF476582)),
          ),
          const SizedBox(height: 16),
          // Nom
          Text(
            _utilisateur.nom,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Notation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.green, size: 20),
              const SizedBox(width: 4),
              Text(
                '${_utilisateur.notation.toStringAsFixed(2)} Notation',
                style: const TextStyle(color: Color(0xFF476582), fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateAccountCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 218, 255, 52).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(255, 218, 255, 52).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mettez à jour votre compte',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Améliorez votre expérience d\'application',
                  style: TextStyle(color: Color(0xFF476582), fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  '2 nouvelles suggestions',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // TODO: Navigation vers pages détail avec Firebase
          _buildMenuItem(Icons.person_outline, 'Infos personnelles', () {
            // TODO: Navigator.push(context, MaterialPageRoute(builder: (_) => InfosPersonnellesPage()));
            _afficherSnack('À connecter avec Firebase', isError: false);
          }),
          _buildMenuItem(Icons.family_restroom, 'Profil familial', () {
            // TODO: Navigation vers profil familial
            _afficherSnack('À connecter avec Firebase', isError: false);
          }),
          _buildMenuItem(Icons.security, 'Sécurité', () {
            // TODO: Navigation vers paramètres sécurité
            _afficherSnack('À connecter avec Firebase', isError: false);
          }),
          _buildMenuItem(
            Icons.verified_user_outlined,
            'Connexion et sécurité',
            () {
              // TODO: Navigation vers paramètres connexion
              _afficherSnack('À connecter avec Firebase', isError: false);
            },
          ),
          _buildMenuItem(Icons.privacy_tip_outlined, 'Confidentialité', () {
            // TODO: Navigation vers paramètres confidentialité
            _afficherSnack('À connecter avec Firebase', isError: false);
          }),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lieux sauvegardés',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // TODO: Connecter avec Firestore pour sauvegarder les adresses
          _buildMenuItem(
            Icons.home_outlined,
            'Ajouter l\'adresse de domicile',
            () {
              // TODO: Navigation vers ajout adresse + sauvegarde Firestore
              _afficherSnack('À connecter avec Firestore', isError: false);
            },
          ),
          _buildMenuItem(
            Icons.work_outline,
            'Ajouter l\'adresse professionnelle',
            () {
              // TODO: Navigation vers ajout adresse + sauvegarde Firestore
              _afficherSnack('À connecter avec Firestore', isError: false);
            },
          ),
          _buildMenuItem(Icons.add, 'Ajouter un lieu', () {
            // TODO: Navigation vers ajout lieu personnalisé + sauvegarde Firestore
            _afficherSnack('À connecter avec Firestore', isError: false);
          }),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          _buildMenuItem(
            Icons.language,
            'Langue',
            () {
              // TODO: Sauvegarder préférence dans Firestore
              _afficherSnack(
                'À connecter avec Firestore pour les préférences',
                isError: false,
              );
            },
            trailing: const Text(
              'Français',
              style: TextStyle(color: Color(0xFF476582)),
            ),
          ),
          _buildMenuItem(
            Icons.volume_up_outlined,
            'Préférences de communication',
            () {
              // TODO: Navigation vers paramètres notifications + sauvegarde Firebase
              _afficherSnack(
                'À connecter avec Firebase pour les notifications',
                isError: false,
              );
            },
          ),
          _buildMenuItem(Icons.calendar_month_outlined, 'Calendriers', () {
            // TODO: Intégration Google Calendar + sauvegarde Firestore
            _afficherSnack(
              'À connecter avec Google Calendar API',
              isError: false,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          _buildMenuItem(
            Icons.logout,
            'Se déconnecter',
            _seDecconnecterMock, // TODO: Remplacer par _seDeconnecter() avec Firebase
          ),
          _buildMenuItem(
            Icons.delete_outline,
            'Supprimer le compte',
            _supprimerCompteMock, // TODO: Remplacer par _supprimerCompte() avec Firebase
            isDanger: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback? onTap, {
    Widget? trailing,
    bool isDanger = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        leading: Icon(
          icon,
          color: isDanger ? Colors.red : const Color(0xFF476582),
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDanger ? Colors.red : Colors.white,
            fontSize: 16,
          ),
        ),
        trailing:
            trailing ??
            const Icon(Icons.chevron_right, color: Color(0xFF476582)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2E3A47),
        border: Border(top: BorderSide(color: Color(0xFF476582), width: 0.5)),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        currentIndex: 2, // Index du profil
        selectedItemColor: const Color.fromARGB(255, 218, 255, 52),
        unselectedItemColor: const Color(0xFF476582),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route_outlined),
            label: 'Trajets',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Compte'),
        ],
        // TODO: Gérer la navigation entre les onglets
        onTap: (index) {
          switch (index) {
            case 0:
              // TODO: Navigator.pushReplacementNamed(context, '/home');
              _afficherSnack(
                'Navigation Accueil - À implémenter',
                isError: false,
              );
              break;
            case 1:
              // TODO: Navigator.pushReplacementNamed(context, '/trajets');
              _afficherSnack(
                'Navigation Trajets - À implémenter',
                isError: false,
              );
              break;
            case 2:
              // Déjà sur la page profil
              break;
          }
        },
      ),
    );
  }
}
