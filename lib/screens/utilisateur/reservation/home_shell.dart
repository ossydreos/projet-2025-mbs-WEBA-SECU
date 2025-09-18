import 'package:flutter/material.dart';
import 'package:my_mobility_services/screens/utilisateur/reservation/acceuil_res_screen.dart';
import 'package:my_mobility_services/screens/utilisateur/offres/offres_personnalisees_screen.dart';
import 'package:my_mobility_services/screens/utilisateur/trajets/trajets_screen.dart';
import 'package:my_mobility_services/screens/utilisateur/profile/profile_screen.dart';
import 'package:my_mobility_services/widgets/utilisateur/widget_navBar.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:my_mobility_services/theme/google_map_styles.dart';

class HomeShell extends StatefulWidget {
  final int initialIndex;

  const HomeShell({super.key, this.initialIndex = 0});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _currentIndex;
  bool _navLocked = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTap(int index) {
    if (_navLocked || index == _currentIndex) return;
    _navLocked = true;
    setState(() => _currentIndex = index);
    Future.delayed(const Duration(milliseconds: 250), () {
      _navLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: Stack(
          children: [
            // Préchargement Google Map invisible (1x1) pour initialiser le moteur dès l'ouverture
            
            // Contenu persistant avec IndexedStack
            IndexedStack(
              index: _currentIndex,
              children: [
                AccueilScreen(
                  onNavigate: _onTap,
                  showBottomBar: false,
                ),
                OffresPersonnaliseesScreen(
                  onNavigate: _onTap,
                  showBottomBar: false,
                ),
                TrajetsScreen(
                  onNavigate: _onTap,
                  showBottomBar: false,
                ),
                ProfileScreen(
                  onNavigate: _onTap,
                  showBottomBar: false,
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTap,
        ),
      ),
    );
  }
}


