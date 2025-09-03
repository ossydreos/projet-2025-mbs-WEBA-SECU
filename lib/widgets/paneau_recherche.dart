import 'package:flutter/material.dart';
import '../ui/glass/glassmorphism_theme.dart';

class PaneauRecherche extends StatelessWidget {
  final String? selectedDestination;
  final VoidCallback onTap;
  final bool noWrapper;

  const PaneauRecherche({
    super.key,
    this.selectedDestination,
    required this.onTap,
    this.noWrapper = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'On vous emmène !',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Brand.accent.withOpacity(0.25), blurRadius: 2, offset: const Offset(0, 1))],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onTap,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Brand.text,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedDestination ?? 'Où allez-vous ?',
                      style: TextStyle(
                        color: selectedDestination != null ? Colors.white : Brand.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (noWrapper) return content;

    return GlassContainer(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: content,
    );
  }
}
