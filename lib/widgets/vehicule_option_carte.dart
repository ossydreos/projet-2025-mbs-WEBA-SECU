import 'package:flutter/material.dart';
import '../ui/glass/glassmorphism_theme.dart';
import '../modele/vehicule_type.dart';

class VehiculeOptionCard extends StatelessWidget {
  final VehiculeType vehicle;
  final bool isSelected;
  final VoidCallback onTap;

  const VehiculeOptionCard({
    super.key,
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Brand.accent.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(color: Brand.accent.withOpacity(0.6), width: 2)
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Brand.accent.withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icône véhicule
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? Brand.accent : Brand.bgElev,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Brand.accent.withOpacity(0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  vehicle.icon,
                  color: isSelected ? Colors.white : Brand.textStrong,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: TextStyle(
                        color: Brand.textStrong,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.event_seat, size: 16, color: Brand.textWeak),
                        const SizedBox(width: 6),
                        Text(
                          vehicle.capacity,
                          style: TextStyle(
                            color: Brand.textWeak,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.work_outline,
                          size: 16,
                          color: Brand.textWeak,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          vehicle.luggage,
                          style: TextStyle(
                            color: Brand.textWeak,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
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
                    style: TextStyle(
                      color: Brand.textStrong,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'estimated',
                    style: TextStyle(color: Brand.textWeak, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
