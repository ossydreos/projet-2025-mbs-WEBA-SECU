import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_mobility_services/widgets/glassmorphic.dart';

import '../theme/theme_app.dart';
import '../widgets/localisation_selector.dart';
import '../widgets/glassmorphic.dart';
import '../widgets/vehicule_option_carte.dart';
import '../widgets/booking_confirmation.dart';
import '../modele/vehicule_type.dart';

final defaultTextStyle = GoogleFonts.poppins();

class VehicleReservationScreen extends StatefulWidget {
  const VehicleReservationScreen({super.key});

  @override
  State<VehicleReservationScreen> createState() =>
      _VehicleReservationScreenState();
}

class _VehicleReservationScreenState extends State<VehicleReservationScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  // Liste des véhicules (gardée telle qu’indiquée)
  final List<VehiculeType> vehicleTypes = const [
    VehiculeType('Standard', '\$10', '4 seats', '487 kg', Icons.directions_car),
    VehiculeType('Comfort', '\$15', '4 seats', '500 kg', Icons.airport_shuttle),
    VehiculeType('Luxury', '\$25', '4 seats', '600 kg', Icons.time_to_leave),
  ];

  String? selectedVehicleName = 'Standard'; // sélection par défaut

  bool get _canReserve =>
      _pickupController.text.trim().isNotEmpty &&
      _destinationController.text.trim().isNotEmpty &&
      selectedVehicleName != null;

  @override
  void initState() {
    super.initState();
    // Rebuild quand les champs changent (pour activer/désactiver le bouton)
    _pickupController.addListener(_onFieldsChanged);
    _destinationController.addListener(_onFieldsChanged);
  }

  void _onFieldsChanged() => setState(() {});

  @override
  void dispose() {
    _pickupController
      ..removeListener(_onFieldsChanged)
      ..dispose();
    _destinationController
      ..removeListener(_onFieldsChanged)
      ..dispose();
    super.dispose();
  }

  void _hapticFeedback() => HapticFeedback.lightImpact();

  void _swapLocations() {
    _hapticFeedback();
    final tmp = _pickupController.text;
    _pickupController.text = _destinationController.text;
    _destinationController.text = tmp;
    final scope = FocusScope.of(context);
    if (scope.hasFocus) scope.nextFocus();
  }

  void _reserve() {
    if (!_canReserve) return;
    _hapticFeedback();
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => const BookingConfirmationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = selectedVehicleName;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween(begin: 0, end: 1),
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 16 * (1 - value)),
                        child: child,
                      ),
                    ),
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
                  const SizedBox(height: 20),

                  _buildDriverInfo(),
                  const SizedBox(height: 20),

                  LocalisationSelector(
                    pickupController: _pickupController,
                    destinationController: _destinationController,
                    onSwap: _swapLocations,
                    pickupHint: 'Add a pick-up location',
                    destinationHint: 'Add your destination',
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Choose a vehicle',
                    style: defaultTextStyle.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Liste des options véhicules
                  ...vehicleTypes.map(
                    (v) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: VehiculeOptionCard(
                        vehicle: v,
                        isSelected: v.name == selected,
                        onTap: () {
                          setState(() => selectedVehicleName = v.name);
                          _hapticFeedback();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 96), // espace pour le bouton bas
                ],
              ),
            ),

            // Barre de réservation en bas
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _canReserve ? _reserve : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    disabledBackgroundColor: const Color(0xFF3A3F4A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    selected != null
                        ? 'Reserve now • $selected'
                        : 'Reserve now',
                    style: defaultTextStyle.copyWith(
                      color: AppColors.background,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfo() {
    return GlassmorphicCard(
      child: Row(
        children: [
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Chauffeur',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                _StarsRow(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: const Text(
              'Available',
              style: TextStyle(
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
}

class _StarsRow extends StatelessWidget {
  const _StarsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.star_rounded, color: AppColors.accent, size: 18),
        Icon(Icons.star_rounded, color: AppColors.accent, size: 18),
        Icon(Icons.star_rounded, color: AppColors.accent, size: 18),
        Icon(Icons.star_rounded, color: AppColors.accent, size: 18),
        Icon(Icons.star_rounded, color: AppColors.accent, size: 18),
        SizedBox(width: 8),
        Text(
          '5.0',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
