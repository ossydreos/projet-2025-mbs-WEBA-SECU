import 'package:flutter/material.dart';
import '../theme/theme_app.dart';
import '../widgets/widget_navBar.dart';

class TrajetsScreen extends StatefulWidget {
  const TrajetsScreen({super.key});

  @override
  State<TrajetsScreen> createState() => _TrajetsScreenState();
}

class _TrajetsScreenState extends State<TrajetsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 1; // Index 1 pour "Trajets" (actif)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex)
      return; // Éviter la navigation si déjà sur la page

    setState(() {
      _selectedIndex = index;
    });

    // Navigation vers les autres écrans
    switch (index) {
      case 0: // Accueil
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1: // Trajets (déjà sur cette page)
        break;
      case 2: // Compte
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Trajets',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        toolbarHeight: 80,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Onglets
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[400],
                indicatorColor: AppColors.accent,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
                tabs: const [
                  Tab(text: 'À venir'),
                  Tab(text: 'Terminés'),
                ],
              ),
            ),

            // Contenu principal
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Onglet "À venir"
                  _buildUpcomingTab(),
                  // Onglet "Terminés"
                  _buildCompletedTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildUpcomingTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          // Contenu principal centré
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Illustration 3D du calendrier
                  Container(
                    width: 120,
                    height: 120,
                    child: Stack(
                      children: [
                        // Calendrier de base
                        Positioned(
                          left: 20,
                          top: 10,
                          child: Container(
                            width: 80,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Barre supérieure du calendrier
                                Container(
                                  height: 25,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                ),
                                // Grille du calendrier
                                Expanded(
                                  child: GridView.builder(
                                    padding: const EdgeInsets.all(4),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 7,
                                          childAspectRatio: 1,
                                          crossAxisSpacing: 2,
                                          mainAxisSpacing: 2,
                                        ),
                                    itemCount: 35,
                                    itemBuilder: (context, index) {
                                      // Carré vert mis en évidence
                                      if (index == 15) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.accent,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        );
                                      }
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Anneau de reliure
                        Positioned(
                          left: 15,
                          top: 5,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // Icône d'horloge verte
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.schedule,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Message principal en anglais
                  Text(
                    'No Upcoming rides',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Message secondaire en français
                  Text(
                    'Emploi du temps compliqué? Optez pour un trajet planifié pour arriver à l\'heure.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[300],
                      height: 1.4,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Lien "Savoir comment ça fonctionne"
                  GestureDetector(
                    onTap: () {
                      // TODO: Implémenter l'action
                    },
                    child: Text(
                      'Savoir comment ça fonctionne',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bouton d'action en bas
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implémenter l'action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Planifiez un trajet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'Aucun trajet terminé',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[400],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
