import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../theme/theme_app.dart';

final defaultTextStyle = GoogleFonts.urbanist();

class VehicleReservationScreen extends StatefulWidget {
  const VehicleReservationScreen({Key? key}) : super(key: key);

  @override
  State<VehicleReservationScreen> createState() =>
      _VehicleReservationScreenState();
}

class _VehicleReservationScreenState extends State<VehicleReservationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  String selectedVehicleType = 'Standard';
  bool isDriverSelected = true;

  final List<VehicleType> vehicleTypes = [
    VehicleType('Standard', '\$10', '4 seats', '487 kg', Icons.directions_car),
    VehicleType('Comfort', '\$15', '4 seats', '500 kg', Icons.airport_shuttle),
    VehicleType('Luxury', '\$25', '4 seats', '600 kg', Icons.time_to_leave),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _hapticFeedback() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildLocationInputs(),
                  const SizedBox(height: 25),
                  const SizedBox(height: 25),
                  _buildVehicleSelection(),
                  const SizedBox(height: 30),
                  _buildBookingButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Navigation et profil
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _hapticFeedback,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu, color: Colors.white, size: 24),
              ),
            ),
            GestureDetector(
              onTap: _hapticFeedback,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent,
                      AppColors.accent.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.background,
                  size: 24,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 35),

        // Titre principal avec animation
        TweenAnimationBuilder(
          duration: const Duration(milliseconds: 800),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Text(
                  'Where do you\nwant to go?',
                  style: defaultTextStyle.copyWith(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 20),
        _buildDriverInfo(),
      ],
    );
  }

  Widget _buildDriverInfo() {
    return GlassmorphicCard(
      child: Row(
        children: [
          // Avatar du chauffeur
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent, AppColors.accent.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(22.5),
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.background,
              size: 22,
            ),
          ),

          const SizedBox(width: 15),

          // Infos chauffeur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chauffeur',
                  style: defaultTextStyle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '5.0',
                      style: defaultTextStyle.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Statut disponible
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Text(
              'Available',
              style: defaultTextStyle.copyWith(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInputs() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Première bulle - Pick-up
          _buildLocationBubble(
            controller: _pickupController,
            hint: 'Add a pick-up location',
            icon: Icons.radio_button_unchecked,
          ),

          const SizedBox(height: 8),

          // Bouton d'échange centré
          Center(
            child: GestureDetector(
              onTap: () {
                _hapticFeedback();
                final temp = _pickupController.text;
                _pickupController.text = _destinationController.text;
                _destinationController.text = temp;
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D26),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.swap_vert_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Deuxième bulle - Destination
          _buildLocationBubble(
            controller: _destinationController,
            hint: 'Add your destination',
            icon: Icons.location_on,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBubble({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D26), // Fond arrondi unifié
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          // Icône intégrée dans le fond arrondi
          Container(
            padding: const EdgeInsets.all(14),
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF1A1D26), size: 18),
            ),
          ),

          // Champ de texte qui occupe le reste de l'espace
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
              child: TextField(
                controller: controller,
                cursorColor: Colors.white, // 🔧 CORRECTION: Curseur blanc
                style: defaultTextStyle.copyWith(
                  color: Colors.white, // 🔧 CORRECTION: Texte saisi en blanc
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: defaultTextStyle.copyWith(
                    color: Color(0xFF6B7280), // Couleur du placeholder
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  filled: true, // 🔧 CORRECTION: Active le remplissage
                  fillColor:
                      Colors.transparent, // 🔧 CORRECTION: Fond transparent
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildVehicleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your ride',
          style: defaultTextStyle.copyWith(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 15),
        ...vehicleTypes.asMap().entries.map((entry) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 200 + (entry.key * 100)),
            child: _buildVehicleCard(entry.value),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildVehicleCard(VehicleType vehicle) {
    final isSelected = vehicle.name == selectedVehicleType;

    return GestureDetector(
      onTap: () {
        setState(() => selectedVehicleType = vehicle.name);
        _hapticFeedback();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 15),
        transform: Matrix4.identity()..scale(isSelected ? 1.02 : 1.0),
        child: GlassmorphicCard(
          isSelected: isSelected,
          child: Row(
            children: [
              // Icône véhicule
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            AppColors.accent,
                            AppColors.accent.withOpacity(0.7),
                          ],
                        )
                      : null,
                  color: !isSelected ? AppColors.surface : null,
                  borderRadius: BorderRadius.circular(27.5),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  vehicle.icon,
                  color: isSelected ? AppColors.background : Colors.white,
                  size: 26,
                ),
              ),

              const SizedBox(width: 15),

              // Infos véhicule
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: defaultTextStyle.copyWith(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                        Text(
                          ' ${vehicle.capacity}',
                          style: defaultTextStyle.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Icon(
                          Icons.luggage_outlined,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                        Text(
                          ' ${vehicle.luggage}',
                          style: defaultTextStyle.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Prix
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    vehicle.price,
                    style: defaultTextStyle.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'estimated',
                    style: defaultTextStyle.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
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

  Widget _buildBookingButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.accent.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          _hapticFeedback();
          _showBookingConfirmation();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_car,
              color: AppColors.background,
              size: 26,
            ),
            const SizedBox(width: 12),
            Text(
              'Book Now',
              style: defaultTextStyle.copyWith(
                color: AppColors.background,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingConfirmation() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => const BookingConfirmationDialog(),
    );
  }
}

// Widget glassmorphique réutilisable
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final bool isSelected;

  const GlassmorphicCard({
    Key? key,
    required this.child,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSelected
              ? [
                  AppColors.surface.withOpacity(0.9),
                  AppColors.surface.withOpacity(0.7),
                ]
              : [
                  AppColors.surface.withOpacity(0.7),
                  AppColors.surface.withOpacity(0.5),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? AppColors.accent.withOpacity(0.6)
              : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          if (isSelected)
            BoxShadow(
              color: AppColors.accent.withOpacity(0.2),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: child,
    );
  }
}

// Modèle de données pour les véhicules
class VehicleType {
  final String name;
  final String price;
  final String capacity;
  final String luggage;
  final IconData icon;

  VehicleType(this.name, this.price, this.capacity, this.luggage, this.icon);
}

// Dialog de confirmation avec effet glassmorphique
class BookingConfirmationDialog extends StatefulWidget {
  const BookingConfirmationDialog({Key? key}) : super(key: key);

  @override
  State<BookingConfirmationDialog> createState() =>
      _BookingConfirmationDialogState();
}

class _BookingConfirmationDialogState extends State<BookingConfirmationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.surface.withOpacity(0.9),
                        AppColors.surface.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icône de succès avec animation
                      TweenAnimationBuilder(
                        duration: const Duration(milliseconds: 1000),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, double value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.accent,
                                    AppColors.accent.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: AppColors.background,
                                size: 40,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 25),

                      Text(
                        'Booking Confirmed!',
                        style: defaultTextStyle.copyWith(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Your ride has been booked successfully.\nDriver will arrive in 3 minutes.',
                        textAlign: TextAlign.center,
                        style: defaultTextStyle.copyWith(
                          color: AppColors.textSecondary.withOpacity(0.9),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Bouton OK avec style glassmorphique
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accent,
                              AppColors.accent.withOpacity(0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'Perfect!',
                            style: defaultTextStyle.copyWith(
                              color: AppColors.background,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
